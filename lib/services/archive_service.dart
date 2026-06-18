import 'dart:io';

import 'package:archive/archive.dart';
import 'package:cope_x_studio/models/browser_entry.dart';
import 'package:path/path.dart' as p;

class ArchiveService {
  /// Nén một hoặc nhiều file/thư mục thành file .zip
  Future<void> zipPaths(List<String> sources, String zipPath) async {
    final archive = Archive();

    for (final source in sources) {
      final type = FileSystemEntity.typeSync(source);
      if (type == FileSystemEntityType.directory) {
        await _addDirectoryToArchive(archive, Directory(source), p.basename(source));
      } else if (type == FileSystemEntityType.file) {
        final file = File(source);
        final data = await file.readAsBytes();
        archive.addFile(ArchiveFile(p.basename(source), data.length, data));
      }
    }

    final encoder = ZipEncoder();
    final bytes = encoder.encode(archive);
    if (bytes == null) throw Exception('Không thể tạo file ZIP');

    final out = File(zipPath);
    if (!out.parent.existsSync()) {
      await out.parent.create(recursive: true);
    }
    await out.writeAsBytes(bytes);
  }

  Future<void> _addDirectoryToArchive(
    Archive archive,
    Directory dir,
    String basePath,
  ) async {
    await for (final entity in dir.list(recursive: false, followLinks: false)) {
      final name = p.basename(entity.path);
      final archivePath = basePath.isEmpty ? name : '$basePath/$name';

      if (entity is Directory) {
        await _addDirectoryToArchive(archive, entity, archivePath);
      } else if (entity is File) {
        final data = await entity.readAsBytes();
        archive.addFile(ArchiveFile(archivePath, data.length, data));
      }
    }
  }

  /// Giải nén file .zip vào thư mục đích
  Future<void> unzipTo(String zipPath, String destinationDir) async {
    final bytes = await File(zipPath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final dest = Directory(destinationDir);
    if (!dest.existsSync()) {
      await dest.create(recursive: true);
    }

    for (final file in archive.files) {
      if (!file.isFile) continue;

      final outPath = p.join(destinationDir, file.name);
      final outFile = File(outPath);
      if (!outFile.parent.existsSync()) {
        await outFile.parent.create(recursive: true);
      }
      await outFile.writeAsBytes(file.content as List<int>);
    }
  }

  /// Liệt kê mục con trực tiếp bên trong ZIP tại [innerPath] (rỗng = gốc).
  List<BrowserEntry> listZipDirectory(String zipPath, String innerPath) {
    final bytes = File(zipPath).readAsBytesSync();
    final archive = ZipDecoder().decodeBytes(bytes);
    final prefix = innerPath.isEmpty ? '' : '${innerPath.replaceAll('\\', '/')}/';
    final children = <String, BrowserEntry>{};

    for (final file in archive.files) {
      var name = file.name.replaceAll('\\', '/');
      if (prefix.isNotEmpty) {
        if (!name.startsWith(prefix)) continue;
        name = name.substring(prefix.length);
      }
      if (name.isEmpty) continue;

      final parts = name.split('/');
      final childName = parts.first;
      if (childName.isEmpty) continue;

      final childInner = innerPath.isEmpty ? childName : '$innerPath/$childName';

      if (parts.length == 1) {
        children[childName] = BrowserEntry(
          name: childName,
          path: childInner,
          isDirectory: !file.isFile,
          size: file.isFile ? file.size : null,
          isZipVirtual: true,
        );
      } else if (!children.containsKey(childName)) {
        children[childName] = BrowserEntry(
          name: childName,
          path: childInner,
          isDirectory: true,
          isZipVirtual: true,
        );
      }
    }

    final list = children.values.toList();
    list.sort((a, b) {
      if (a.isDirectory != b.isDirectory) return a.isDirectory ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return list;
  }
}
