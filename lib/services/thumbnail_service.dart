import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:archive/archive.dart';
import 'package:cope_x_studio/services/permission_service.dart';
import 'package:cope_x_studio/services/platform_bridge.dart';
import 'package:cope_x_studio/utils/file_type_utils.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class ThumbnailService {
  ThumbnailService._({PlatformBridge? platform})
      : _platform = platform ?? PlatformBridge(),
        _cacheRoot = _initCacheRoot();

  static final ThumbnailService instance = ThumbnailService._();

  static const _cacheRelative = 'copecute/.thumb';
  static const _thumbMaxSize = 120;
  static const _maxSourceBytes = 48 * 1024 * 1024;

  final PlatformBridge _platform;
  final Future<String> _cacheRoot;
  final _memoryCache = <String, Uint8List?>{};
  final _inFlight = <String, Future<Uint8List?>>{};

  Future<Uint8List?> load(String filePath) async {
    if (!FileTypeUtils.hasThumbnail(filePath)) return null;

    final cacheKey = _pathCacheKey(filePath);
    if (_memoryCache.containsKey(cacheKey)) {
      return _memoryCache[cacheKey];
    }

    final pending = _inFlight[cacheKey];
    if (pending != null) return pending;

    final future = _loadUncached(filePath);
    _inFlight[cacheKey] = future;
    try {
      final bytes = await future;
      _memoryCache[cacheKey] = bytes;
      return bytes;
    } finally {
      _inFlight.remove(cacheKey);
    }
  }

  void evict(String filePath) {
    final cacheKey = _pathCacheKey(filePath);
    _memoryCache.remove(cacheKey);
    _deleteDiskCache(filePath);
  }

  void clear() {
    _memoryCache.clear();
  }

  Future<Uint8List?> _loadUncached(String filePath) async {
    try {
      final stat = await File(filePath).stat();
      final cached = await _readDiskCache(filePath, stat.modified, stat.size);
      if (cached != null) return cached;

      Uint8List? bytes;
      if (FileTypeUtils.isImage(filePath)) {
        bytes = await _generateImageThumbnail(filePath);
      } else if (FileTypeUtils.isVideo(filePath)) {
        bytes = await _generateVideoThumbnail(filePath);
      } else if (FileTypeUtils.isPdf(filePath)) {
        bytes = await _generatePdfThumbnail(filePath);
      } else if (FileTypeUtils.isApk(filePath)) {
        bytes = await _generateApkThumbnail(filePath);
      }

      if (bytes != null && bytes.isNotEmpty) {
        final normalized = _normalizeThumb(bytes);
        if (normalized != null && normalized.isNotEmpty) {
          await _writeDiskCache(filePath, stat.modified, stat.size, normalized);
          return normalized;
        }
      }
      return bytes;
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List?> _readDiskCache(
    String filePath,
    DateTime modified,
    int size,
  ) async {
    try {
      final thumbFile = await _thumbFile(filePath);
      final metaFile = await _metaFile(filePath);
      if (!thumbFile.existsSync() || !metaFile.existsSync()) return null;

      final meta = await metaFile.readAsString();
      if (meta != _metaValue(modified, size)) return null;

      final bytes = await thumbFile.readAsBytes();
      return bytes.isEmpty ? null : bytes;
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeDiskCache(
    String filePath,
    DateTime modified,
    int size,
    Uint8List bytes,
  ) async {
    try {
      final dir = await _ensureCacheDir(filePath);
      final thumbFile = File(p.join(dir.path, '${_hash(filePath)}.png.copethumb'));
      final metaFile = File(p.join(dir.path, '${_hash(filePath)}.meta.copethumb'));
      await thumbFile.writeAsBytes(bytes, flush: true);
      await metaFile.writeAsString(_metaValue(modified, size), flush: true);
    } catch (_) {}
  }

  Future<void> _deleteDiskCache(String filePath) async {
    try {
      final thumbFile = await _thumbFile(filePath);
      final metaFile = await _metaFile(filePath);
      if (thumbFile.existsSync()) await thumbFile.delete();
      if (metaFile.existsSync()) await metaFile.delete();
    } catch (_) {}
  }

  Future<Directory> _ensureCacheDir(String filePath) async {
    final dir = Directory(await _cacheDirFor(filePath));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<String> _cacheDirFor(String filePath) async {
    if (Platform.isAndroid) {
      return await _cacheRoot;
    }
    final root = _nearestStorageRoot(filePath) ?? _defaultStorageRoot();
    return p.normalize(p.join(root, _cacheRelative));
  }

  static Future<String> _initCacheRoot() async {
    final dir = await getApplicationSupportDirectory();
    return p.normalize(p.join(dir.path, _cacheRelative));
  }

  Future<File> _thumbFile(String filePath) async {
    return File(p.join(await _cacheDirFor(filePath), '${_hash(filePath)}.png.copethumb'));
  }

  Future<File> _metaFile(String filePath) async {
    return File(p.join(await _cacheDirFor(filePath), '${_hash(filePath)}.meta.copethumb'));
  }

  String _pathCacheKey(String filePath) {
    final normalized = p.normalize(filePath);
    return Platform.isWindows ? normalized.toLowerCase() : normalized;
  }

  String _hash(String filePath) {
    return sha256.convert(utf8.encode(_pathCacheKey(filePath))).toString();
  }

  String _metaValue(DateTime modified, int size) =>
      '${modified.millisecondsSinceEpoch}|$size';

  String? _nearestStorageRoot(String path) {
    final normalized = p.normalize(path);
    for (final root in PermissionService.androidStorageRoots) {
      final r = p.normalize(root);
      if (normalized == r || normalized.startsWith('$r${Platform.pathSeparator}')) {
        return r;
      }
      if (normalized.startsWith('$r/')) return r;
    }
    if (Platform.isWindows) {
      final match = RegExp(r'^([A-Za-z]:\\)').firstMatch(normalized);
      return match?.group(1);
    }
    final match = RegExp(r'^(/storage/[^/]+)').firstMatch(normalized);
    return match?.group(1);
  }

  String _defaultStorageRoot() {
    if (Platform.isAndroid) {
      for (final root in PermissionService.androidStorageRoots) {
        if (Directory(root).existsSync()) return p.normalize(root);
      }
      return '/storage/emulated/0';
    }
    if (Platform.isWindows) {
      return Platform.environment['USERPROFILE'] ?? 'C:\\';
    }
    return Platform.environment['HOME'] ?? '/';
  }

  Future<Uint8List?> _generateImageThumbnail(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return null;
      if (await file.length() > _maxSourceBytes) return null;

      final bytes = await file.readAsBytes();
      final codecInfo = await ui.instantiateImageCodec(bytes);
      final frameInfo = await codecInfo.getNextFrame();
      final width = frameInfo.image.width;
      final height = frameInfo.image.height;
      frameInfo.image.dispose();
      codecInfo.dispose();

      int? tw, th;
      if (width >= height) {
        tw = _thumbMaxSize;
      } else {
        th = _thumbMaxSize;
      }

      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: tw,
        targetHeight: th,
      );
      final frame = await codec.getNextFrame();
      final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
      frame.image.dispose();
      if (data == null) return null;
      return data.buffer.asUint8List();
    } catch (_) {
      return _generateImageThumbnailFallback(path);
    }
  }

  Future<Uint8List?> _generateImageThumbnailFallback(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;
      final resized = img.copyResize(
        decoded,
        width: decoded.width >= decoded.height ? _thumbMaxSize : null,
        height: decoded.height > decoded.width ? _thumbMaxSize : null,
        maintainAspect: true,
      );
      return Uint8List.fromList(img.encodePng(resized));
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List?> _generateVideoThumbnail(String path) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final thumbPath = await VideoThumbnail.thumbnailFile(
        video: path,
        thumbnailPath: tempDir.path,
        imageFormat: ImageFormat.PNG,
        maxHeight: _thumbMaxSize,
        quality: 75,
      );
      if (thumbPath == null) return null;
      final bytes = await File(thumbPath).readAsBytes();
      try {
        await File(thumbPath).delete();
      } catch (_) {}
      return bytes;
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List?> _generatePdfThumbnail(String path) async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        return await _platform.getPdfThumbnailFromPath(
          path,
          maxSize: _thumbMaxSize,
        );
      } catch (_) {}
    }
    return null;
  }

  Future<Uint8List?> _generateApkThumbnail(String path) async {
    final ext = p.extension(path).toLowerCase();
    if (!kIsWeb && Platform.isAndroid && (ext == '.apk' || ext == '.xapk')) {
      try {
        final bytes = await _platform.getApkIconFromPath(path);
        if (bytes != null && bytes.isNotEmpty) {
          return _normalizeThumb(bytes);
        }
      } catch (_) {}
    }
    return _generateApkThumbnailFromZip(path);
  }

  Future<Uint8List?> _generateApkThumbnailFromZip(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return null;
      if (await file.length() > 80 * 1024 * 1024) return null;

      final archive = ZipDecoder().decodeBytes(await file.readAsBytes(), verify: false);
      final files = archive.files.where((f) => f.isFile).toList();

      if (path.toLowerCase().endsWith('.xapk') || path.toLowerCase().endsWith('.apks')) {
        final nestedApk = files.firstWhere(
          (f) => p.extension(f.name).toLowerCase() == '.apk',
          orElse: () => ArchiveFile('', 0, []),
        );
        if (nestedApk.name.isNotEmpty) {
          final tempDir = await getTemporaryDirectory();
          final tempApk = File(p.join(tempDir.path, p.basename(nestedApk.name)));
          await tempApk.writeAsBytes(nestedApk.content as List<int>, flush: true);
          try {
            final nestedThumb = await _generateApkThumbnail(tempApk.path);
            if (nestedThumb != null && nestedThumb.isNotEmpty) {
              return nestedThumb;
            }
          } finally {
            try {
              await tempApk.delete();
            } catch (_) {}
          }
        }
      }

      final icons = files.where((f) {
        final name = f.name.toLowerCase();
        return (name.contains('mipmap') || name.contains('drawable') || name.contains('ic_launcher')) &&
            (name.endsWith('.png') || name.endsWith('.webp'));
      }).toList();

      if (icons.isEmpty) {
        final drawables = files.where((f) {
          final name = f.name.toLowerCase();
          return (name.contains('res/') || name.contains('mipmap') || name.contains('drawable')) &&
              (name.endsWith('.png') || name.endsWith('.webp'));
        }).toList();
        if (drawables.isEmpty) return null;
        drawables.sort((a, b) => b.name.length.compareTo(a.name.length));
        return _normalizeThumb(Uint8List.fromList(drawables.first.content as List<int>));
      }

      icons.sort((a, b) {
        int score(String name) {
          if (name.contains('xxxhdpi')) return 5;
          if (name.contains('xxhdpi')) return 4;
          if (name.contains('xhdpi')) return 3;
          if (name.contains('hdpi')) return 2;
          if (name.contains('mdpi')) return 1;
          return 0;
        }

        return score(b.name).compareTo(score(a.name));
      });

      return _normalizeThumb(Uint8List.fromList(icons.first.content as List<int>));
    } catch (_) {
      return null;
    }
  }

  Uint8List? _normalizeThumb(Uint8List bytes) {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return bytes;
      if (decoded.width <= _thumbMaxSize && decoded.height <= _thumbMaxSize) {
        return Uint8List.fromList(img.encodePng(decoded));
      }
      final resized = img.copyResize(
        decoded,
        width: decoded.width >= decoded.height ? _thumbMaxSize : null,
        height: decoded.height > decoded.width ? _thumbMaxSize : null,
        maintainAspect: true,
      );
      return Uint8List.fromList(img.encodePng(resized));
    } catch (_) {
      return bytes;
    }
  }
}
