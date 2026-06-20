import 'dart:io';

import 'package:cope_x_studio/models/text_encoding.dart';
import 'package:cope_x_studio/services/archive_cancel_token.dart';
import 'package:cope_x_studio/services/text_encoding_service.dart';
import 'package:cope_x_studio/utils/entry_progress_tracker.dart';
import 'package:path/path.dart' as p;

class FileAccessException implements Exception {
  FileAccessException(this.path, this.message);
  final String path;
  final String message;

  @override
  String toString() => 'Không thể truy cập $path: $message';
}

class FileService {
  List<FileSystemEntity> listDirectory(String dirPath, {bool showHidden = false}) {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) return [];

    List<FileSystemEntity> raw;
    try {
      raw = dir.listSync(followLinks: false);
    } on FileSystemException catch (e) {
      throw FileAccessException(dirPath, e.message);
    }

    final entries = <FileSystemEntity>[];
    for (final entity in raw) {
      try {
        final name = p.basename(entity.path);
        if (!showHidden && (name.startsWith('.') || name == 'Thumbs.db' || name == 'desktop.ini')) {
          continue;
        }
        if (entity is Directory) {
          entries.add(entity);
        } else if (entity is File) {
          entries.add(entity);
        }
      } catch (_) {
        // Bỏ qua mục không đọc được
      }
    }

    entries.sort((a, b) {
      final aIsDir = a is Directory;
      final bIsDir = b is Directory;
      if (aIsDir != bIsDir) return aIsDir ? -1 : 1;
      return p.basename(a.path).toLowerCase().compareTo(
            p.basename(b.path).toLowerCase(),
          );
    });
    return entries;
  }

  Future<String> readText(String filePath, {TextEncoding encoding = TextEncoding.utf8}) async {
    final bytes = await File(filePath).readAsBytes();
    return TextEncodingService.instance.decode(bytes, encoding);
  }

  Future<void> writeText(
    String filePath,
    String content, {
    TextEncoding encoding = TextEncoding.utf8,
  }) async {
    final bytes = TextEncodingService.instance.encode(content, encoding);
    await File(filePath).writeAsBytes(bytes);
  }

  Future<void> writeBytes(String filePath, List<int> bytes) async {
    await File(filePath).writeAsBytes(bytes);
  }

  Future<List<int>> readBytes(String filePath) async {
    return File(filePath).readAsBytes();
  }

  Future<void> createFile(String filePath, {String content = ''}) async {
    final file = File(filePath);
    if (!file.parent.existsSync()) {
      await file.parent.create(recursive: true);
    }
    await file.writeAsString(content);
  }

  Future<void> createFolder(String folderPath) async {
    await Directory(folderPath).create(recursive: true);
  }

  Future<void> delete(String path) async {
    await deletePath(path);
  }

  /// Đếm số mục sẽ bị xóa (file + thư mục, gồm cả nội dung đệ quy).
  Future<int> countDeletionItems(String path) async {
    final type = FileSystemEntity.typeSync(path);
    if (type == FileSystemEntityType.notFound) return 0;
    if (type == FileSystemEntityType.file) return 1;
    if (type == FileSystemEntityType.directory) {
      var count = 1;
      final dir = Directory(path);
      if (!dir.existsSync()) return 0;
      await for (final _ in dir.list(recursive: true, followLinks: false)) {
        count++;
      }
      return count;
    }
    return 1;
  }

  Future<int> countDeletionItemsInPaths(List<String> paths) async {
    var total = 0;
    for (final path in paths) {
      total += await countDeletionItems(path);
    }
    return total;
  }

  /// Xóa và báo tiến độ theo từng mục. Kiểm tra [shouldCancel] sau mỗi mục đã xóa xong.
  Future<void> deletePathWithProgress(
    String path,
    EntryProgressTracker tracker,
    void Function(String name, double progress) onProgress, {
    bool Function()? shouldCancel,
  }) async {
    bool stopIfRequested() {
      if (shouldCancel?.call() == true) return true;
      return false;
    }

    final type = FileSystemEntity.typeSync(path);
    if (type == FileSystemEntityType.file) {
      final file = File(path);
      if (file.existsSync()) {
        await file.delete();
      }
      onProgress(p.basename(path), tracker.advance());
      return;
    }
    if (type == FileSystemEntityType.directory) {
      final dir = Directory(path);
      if (!dir.existsSync()) return;

      await for (final entity in dir.list(followLinks: false)) {
        if (entity is File) {
          await entity.delete();
          onProgress(p.basename(entity.path), tracker.advance());
          if (stopIfRequested()) return;
        } else if (entity is Directory) {
          await deletePathWithProgress(entity.path, tracker, onProgress, shouldCancel: shouldCancel);
          if (stopIfRequested()) return;
        }
      }
      if (stopIfRequested()) return;
      if (dir.existsSync()) {
        await dir.delete();
        onProgress(p.basename(path), tracker.advance());
      }
    }
  }

  Future<void> deletePath(String path) async {
    final entity = FileSystemEntity.typeSync(path);
    if (entity == FileSystemEntityType.directory) {
      await Directory(path).delete(recursive: true);
    } else if (entity == FileSystemEntityType.file) {
      await File(path).delete();
    }
  }

  Future<void> renameEntity(String oldPath, String newPath) async {
    final entity = FileSystemEntity.typeSync(oldPath);
    if (entity == FileSystemEntityType.directory) {
      await Directory(oldPath).rename(newPath);
    } else {
      await File(oldPath).rename(newPath);
    }
  }

  Future<void> copyPaths(List<String> sources, String destinationDir) async {
    for (final source in sources) {
      await copyPath(source, destinationDir);
    }
  }

  Future<String> copyPath(String source, String destinationDir) async {
    final name = p.basename(source);
    final dest = p.join(destinationDir, name);
    if (exists(dest)) {
      throw FileSystemException('Đã tồn tại', dest);
    }
    final type = FileSystemEntity.typeSync(source);
    if (type == FileSystemEntityType.directory) {
      await _copyDirectory(Directory(source), Directory(dest));
    } else {
      await File(source).copy(dest);
    }
    return dest;
  }

  Future<String> copyPathWithProgress(
    String source,
    String destinationDir,
    EntryProgressTracker tracker,
    void Function(String name, double progress) onProgress, {
    bool Function()? shouldCancel,
  }) async {
    void checkCancel() {
      if (shouldCancel?.call() == true) throw const ArchiveCancelledException();
    }

    checkCancel();
    final name = p.basename(source);
    final dest = p.join(destinationDir, name);
    if (exists(dest)) {
      throw FileSystemException('Đã tồn tại', dest);
    }

    final type = FileSystemEntity.typeSync(source);
    if (type == FileSystemEntityType.directory) {
      await _copyDirectoryWithProgress(
        Directory(source),
        Directory(dest),
        tracker,
        onProgress,
        shouldCancel: shouldCancel,
      );
    } else {
      await File(source).copy(dest);
      onProgress(name, tracker.advance());
    }
    return dest;
  }

  Future<String> duplicateWithProgress(
    String sourcePath,
    EntryProgressTracker tracker,
    void Function(String name, double progress) onProgress, {
    bool Function()? shouldCancel,
  }) async {
    final dir = p.dirname(sourcePath);
    final base = p.basename(sourcePath);
    final isDir = isDirectory(sourcePath);
    final String newName;
    if (isDir) {
      newName = uniqueName(dir, '$base - Copy');
    } else {
      final ext = p.extension(base);
      final name = p.basenameWithoutExtension(base);
      newName = uniqueName(dir, '$name - Copy$ext');
    }
    final dest = p.join(dir, newName);
    if (isDir) {
      await _copyDirectoryWithProgress(
        Directory(sourcePath),
        Directory(dest),
        tracker,
        onProgress,
        shouldCancel: shouldCancel,
      );
    } else {
      if (shouldCancel?.call() == true) throw const ArchiveCancelledException();
      await File(sourcePath).copy(dest);
      onProgress(newName, tracker.advance());
    }
    return dest;
  }

  Future<void> _copyDirectoryWithProgress(
    Directory source,
    Directory dest,
    EntryProgressTracker tracker,
    void Function(String name, double progress) onProgress, {
    bool Function()? shouldCancel,
  }) async {
    void checkCancel() {
      if (shouldCancel?.call() == true) throw const ArchiveCancelledException();
    }

    if (!dest.existsSync()) {
      await dest.create(recursive: true);
    }
    await for (final entity in source.list(recursive: false, followLinks: false)) {
      checkCancel();
      final newPath = p.join(dest.path, p.basename(entity.path));
      if (entity is Directory) {
        await _copyDirectoryWithProgress(
          entity,
          Directory(newPath),
          tracker,
          onProgress,
          shouldCancel: shouldCancel,
        );
      } else if (entity is File) {
        await entity.copy(newPath);
        onProgress(p.basename(entity.path), tracker.advance());
      }
    }
  }

  Future<void> movePaths(List<String> sources, String destinationDir) async {
    for (final source in sources) {
      final name = p.basename(source);
      final dest = p.join(destinationDir, name);
      await renameEntity(source, dest);
    }
  }

  Future<void> _copyDirectory(Directory source, Directory dest) async {
    if (!dest.existsSync()) {
      await dest.create(recursive: true);
    }
    await for (final entity in source.list(recursive: false, followLinks: false)) {
      final newPath = p.join(dest.path, p.basename(entity.path));
      if (entity is Directory) {
        await _copyDirectory(entity, Directory(newPath));
      } else if (entity is File) {
        await entity.copy(newPath);
      }
    }
  }

  bool exists(String path) =>
      FileSystemEntity.typeSync(path) != FileSystemEntityType.notFound;

  bool isDirectory(String path) =>
      FileSystemEntity.typeSync(path) == FileSystemEntityType.directory;

  Future<String> duplicate(String sourcePath) async {
    final dir = p.dirname(sourcePath);
    final base = p.basename(sourcePath);
    final isDir = isDirectory(sourcePath);
    final String newName;
    if (isDir) {
      newName = uniqueName(dir, '$base - Copy');
    } else {
      final ext = p.extension(base);
      final name = p.basenameWithoutExtension(base);
      newName = uniqueName(dir, '$name - Copy$ext');
    }
    final dest = p.join(dir, newName);
    if (isDir) {
      await _copyDirectory(Directory(sourcePath), Directory(dest));
    } else {
      await File(sourcePath).copy(dest);
    }
    return dest;
  }

  String uniqueName(String dirPath, String baseName) {
    var candidate = baseName;
    var counter = 1;
    while (exists(p.join(dirPath, candidate))) {
      final ext = p.extension(baseName);
      final nameWithoutExt = p.basenameWithoutExtension(baseName);
      candidate = ext.isEmpty
          ? '$nameWithoutExt ($counter)'
          : '$nameWithoutExt ($counter)$ext';
      counter++;
    }
    return candidate;
  }
}
