import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:cope_x_studio/l10n/l10n_scope.dart';
import 'package:cope_x_studio/models/app_tab.dart';
import 'package:cope_x_studio/models/browser_entry.dart';
import 'package:cope_x_studio/utils/file_type_utils.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:video_player/video_player.dart';

class PropertyField {
  const PropertyField(this.label, this.value);

  final String label;
  final String value;
}

class DirectoryStats {
  const DirectoryStats({
    required this.totalBytes,
    required this.fileCount,
    required this.folderCount,
  });

  final int totalBytes;
  final int fileCount;
  final int folderCount;
}

class EntryPropertiesService {
  static const _maxImageProbeBytes = 16 * 1024 * 1024;
  static const _maxId3ProbeBytes = 256 * 1024;

  Future<List<PropertyField>> buildFields(AppTab tab, BrowserEntry entry) async {
    final l10n = L10nScope.current;
    final fields = <PropertyField>[
      PropertyField(l10n.propertyName, entry.name),
      PropertyField(l10n.propertyType, _fileTypeLabel(entry)),
      PropertyField(l10n.propertyLocation, _entryLocation(tab, entry)),
    ];

    final path = entry.path;
    final isLocal = !path.startsWith('@') && !entry.isZipVirtual;

    if (entry.isDirectory) {
      if (entry.childrenCount != null) {
        fields.add(PropertyField(l10n.propertyItemCount, '${entry.childrenCount}'));
      }
      if (isLocal) {
        final stats = await calculateDirectoryStats(path);
        fields.add(PropertyField(l10n.propertySize, formatSize(stats.totalBytes)));
        fields.add(PropertyField(l10n.propertyFiles, '${stats.fileCount}'));
        if (stats.folderCount > 0) {
          fields.add(PropertyField(l10n.propertySubfolders, '${stats.folderCount}'));
        }
      } else if (entry.size != null) {
        fields.add(PropertyField(l10n.propertySize, formatSize(entry.size!)));
      }
    } else {
      int? size = entry.size;
      if (size == null && isLocal) {
        try {
          size = await File(path).length();
        } catch (_) {}
      }
      if (size != null) {
        fields.add(PropertyField(l10n.propertySize, formatSize(size)));
      }

      if (isLocal) {
        fields.addAll(await _loadMediaMetadata(path));
      }
    }

    if (isLocal) {
      try {
        final stat = (entry.isDirectory ? Directory(path) : File(path)).statSync();
        fields.add(PropertyField(l10n.propertyModified, formatDateTime(stat.modified)));
        fields.add(PropertyField(l10n.propertyAccessed, formatDateTime(stat.accessed)));
      } catch (_) {}
    }

    if (entry.subtitle != null && entry.subtitle!.isNotEmpty) {
      fields.add(PropertyField(l10n.propertyNotes, entry.subtitle!));
    }

    return fields;
  }

  Future<DirectoryStats> calculateDirectoryStats(String dirPath) async {
    var totalBytes = 0;
    var fileCount = 0;
    var folderCount = 0;

    final dir = Directory(dirPath);
    if (!dir.existsSync()) {
      return const DirectoryStats(totalBytes: 0, fileCount: 0, folderCount: 0);
    }

    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        try {
          totalBytes += await entity.length();
          fileCount++;
        } catch (_) {}
      } else if (entity is Directory) {
        folderCount++;
      }
    }

    return DirectoryStats(
      totalBytes: totalBytes,
      fileCount: fileCount,
      folderCount: folderCount,
    );
  }

  Future<List<PropertyField>> _loadMediaMetadata(String path) async {
    if (FileTypeUtils.isImage(path)) {
      return _imageMetadata(path);
    }
    if (FileTypeUtils.isVideo(path)) {
      return _videoMetadata(path);
    }
    if (FileTypeUtils.isAudio(path)) {
      return _audioMetadata(path);
    }
    return const [];
  }

  Future<List<PropertyField>> _imageMetadata(String path) async {
    final fields = <PropertyField>[];
    try {
      final file = File(path);
      if (!file.existsSync()) return fields;

      final fileLen = await file.length();
      final probeLen = fileLen > _maxImageProbeBytes ? _maxImageProbeBytes : fileLen;
      final builder = BytesBuilder(copy: false);
      await for (final chunk in file.openRead(0, probeLen)) {
        builder.add(chunk);
      }
      final bytes = builder.toBytes();
      if (bytes.isEmpty) return fields;

      final image = img.decodeImage(bytes);
      if (image == null) return fields;

      fields.add(PropertyField(L10nScope.current.propertyResolution, '${image.width} × ${image.height} px'));

      if (image.hasExif) {
        fields.addAll(_exifFields(image.exif));
      }
    } catch (_) {}
    return fields;
  }

  List<PropertyField> _exifFields(img.ExifData exif) {
    final fields = <PropertyField>[];

    final l10n = L10nScope.current;
    void addTag(int tag, String label) {
      final value = exif.getTag(tag);
      if (value == null) return;
      final text = value.toString().trim();
      if (text.isEmpty) return;
      fields.add(PropertyField(label, text));
    }

    addTag(0x010F, l10n.propertyCamera);
    addTag(0x0110, 'Model');
    addTag(0x9003, l10n.propertyCapturedAt);
    addTag(0x0132, l10n.propertyDateModified);
    addTag(0x0112, l10n.propertyOrientation);
    return fields;
  }

  Future<List<PropertyField>> _videoMetadata(String path) async {
    final fields = <PropertyField>[];
    VideoPlayerController? controller;
    try {
      controller = VideoPlayerController.file(File(path));
      await controller.initialize();
      final size = controller.value.size;
      final duration = controller.value.duration;
      if (size.width > 0 && size.height > 0) {
        fields.add(PropertyField(L10nScope.current.propertyResolution, '${size.width.toInt()} × ${size.height.toInt()} px'));
      }
      if (duration.inMilliseconds > 0) {
        fields.add(PropertyField(L10nScope.current.propertyDuration, _formatDuration(duration)));
      }
    } catch (_) {
    } finally {
      await controller?.dispose();
    }
    return fields;
  }

  Future<List<PropertyField>> _audioMetadata(String path) async {
    final fields = <PropertyField>[];
    fields.addAll(_readId3Tags(path));

    AudioPlayer? player;
    try {
      player = AudioPlayer();
      await player.setSourceDeviceFile(path);
      final duration = await player.getDuration();
      if (duration != null && duration.inMilliseconds > 0) {
        fields.add(PropertyField(L10nScope.current.propertyDuration, _formatDuration(duration)));
      }
    } catch (_) {
    } finally {
      await player?.dispose();
    }
    return fields;
  }

  List<PropertyField> _readId3Tags(String path) {
    final fields = <PropertyField>[];
    try {
      final file = File(path);
      if (!file.existsSync()) return fields;

      final length = file.lengthSync();
      final readLen = length < _maxId3ProbeBytes ? length : _maxId3ProbeBytes;
      final bytes = file.readAsBytesSync().sublist(0, readLen);
      if (bytes.length < 10 || bytes[0] != 0x49 || bytes[1] != 0x44 || bytes[2] != 0x33) {
        return fields;
      }

      final tagSize = _syncsafeInt(bytes.sublist(6, 10));
      final end = (10 + tagSize).clamp(0, bytes.length);
      var offset = 10;

      while (offset + 10 <= end) {
        final frameId = String.fromCharCodes(bytes.sublist(offset, offset + 4));
        final frameSize = _syncsafeInt(bytes.sublist(offset + 4, offset + 8));
        offset += 10;
        if (frameSize <= 0 || offset + frameSize > end) break;

        final encoding = bytes[offset];
        final textBytes = bytes.sublist(offset + 1, offset + frameSize);
        final text = _decodeId3Text(textBytes, encoding).trim();
        offset += frameSize;

        if (text.isEmpty) continue;
        switch (frameId) {
          case 'TIT2':
            fields.add(PropertyField(L10nScope.current.propertyTitle, text));
          case 'TPE1':
            fields.add(PropertyField(L10nScope.current.propertyArtist, text));
          case 'TALB':
            fields.add(PropertyField('Album', text));
          case 'TCON':
          case 'TYP':
            fields.add(PropertyField(L10nScope.current.propertyGenre, text));
          case 'TDRC':
          case 'TYER':
            fields.add(PropertyField(L10nScope.current.propertyYear, text));
        }
      }
    } catch (_) {}
    return fields;
  }

  static String formatSize(int size) {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  static String formatDateTime(DateTime dt) => DateFormat('dd/MM/yyyy HH:mm').format(dt);

  static String _fileTypeLabel(BrowserEntry entry) {
    final l10n = L10nScope.current;
    if (entry.isDirectory) return l10n.folderType;
    final ext = p.extension(entry.path).replaceFirst('.', '').toUpperCase();
    return ext.isEmpty ? l10n.fileType : l10n.fileTypeExt(ext);
  }

  static String _entryLocation(AppTab tab, BrowserEntry entry) {
    if (tab.isZipViewer && tab.zipArchivePath != null) {
      if (entry.path.isEmpty) return tab.zipArchivePath!;
      return '${tab.zipArchivePath} → ${entry.path}';
    }
    return entry.path;
  }

  static String _formatDuration(Duration duration) {
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);
    final s = duration.inSeconds.remainder(60);
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  static int _syncsafeInt(List<int> bytes) {
    return (bytes[0] << 21) | (bytes[1] << 14) | (bytes[2] << 7) | bytes[3];
  }

  static String _decodeId3Text(List<int> bytes, int encoding) {
    if (bytes.isEmpty) return '';
    switch (encoding) {
      case 1:
      case 2:
        var end = bytes.length;
        if (end >= 2 && bytes[end - 1] == 0 && bytes[end - 2] == 0) end -= 2;
        return String.fromCharCodes(bytes.sublist(0, end));
      default:
        var end = bytes.length;
        if (end > 0 && bytes[end - 1] == 0) end--;
        return String.fromCharCodes(bytes.sublist(0, end));
    }
  }
}
