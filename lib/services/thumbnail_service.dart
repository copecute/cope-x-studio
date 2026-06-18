import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:cope_x_studio/utils/file_type_utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class ThumbnailService {
  ThumbnailService._();
  static final ThumbnailService instance = ThumbnailService._();

  final _memoryCache = <String, Uint8List?>{};

  Future<Uint8List?> load(String filePath) async {
    if (_memoryCache.containsKey(filePath)) {
      return _memoryCache[filePath];
    }

    Uint8List? bytes;
    if (FileTypeUtils.isVideo(filePath)) {
      bytes = await _loadVideoThumbnail(filePath);
    } else if (FileTypeUtils.isApk(filePath)) {
      bytes = await _loadApkIcon(filePath);
    } else if (FileTypeUtils.isImage(filePath)) {
      bytes = await _loadImageThumbnail(filePath);
    }

    _memoryCache[filePath] = bytes;
    return bytes;
  }

  void evict(String filePath) => _memoryCache.remove(filePath);

  void clear() => _memoryCache.clear();

  Future<Uint8List?> _loadImageThumbnail(String path) async {
    try {
      final file = File(path);
      final data = await file.readAsBytes();
      // Giới hạn 512KB cho thumb preview trong list
      if (data.length > 512 * 1024) {
        return null;
      }
      return data;
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List?> _loadVideoThumbnail(String path) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final thumbPath = await VideoThumbnail.thumbnailFile(
        video: path,
        thumbnailPath: tempDir.path,
        imageFormat: ImageFormat.PNG,
        maxHeight: 120,
        quality: 75,
      );
      if (thumbPath == null) return null;
      return File(thumbPath).readAsBytes();
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List?> _loadApkIcon(String path) async {
    try {
      final archive = ZipDecoder().decodeBytes(await File(path).readAsBytes());
      final icons = archive.files
          .where((f) =>
              f.isFile &&
              f.name.contains('mipmap') &&
              (f.name.endsWith('.png') || f.name.endsWith('.webp')))
          .toList();

      if (icons.isEmpty) {
        final drawables = archive.files
            .where((f) =>
                f.isFile &&
                f.name.contains('res/drawable') &&
                f.name.endsWith('.png'))
            .toList();
        if (drawables.isEmpty) return null;
        drawables.sort((a, b) => b.name.length.compareTo(a.name.length));
        return Uint8List.fromList(drawables.first.content as List<int>);
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

      return Uint8List.fromList(icons.first.content as List<int>);
    } catch (_) {
      return null;
    }
  }
}
