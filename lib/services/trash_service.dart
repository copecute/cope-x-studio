import 'dart:io';

import 'package:cope_x_studio/services/permission_service.dart';
import 'package:path/path.dart' as p;

class TrashService {
  TrashService._();
  static final TrashService instance = TrashService._();

  static const retentionDays = 30;
  static const trashRelative = 'copecute/.trash';

  String trashRootFor(String storageRoot) => p.normalize(p.join(storageRoot, trashRelative));

  String defaultTrashRoot() {
    for (final root in PermissionService.androidStorageRoots) {
      if (Directory(root).existsSync()) {
        return trashRootFor(root);
      }
    }
    return trashRootFor('/storage/emulated/0');
  }

  Future<Directory> ensureTrashDir([String? storageRoot]) async {
    final dir = Directory(storageRoot != null ? trashRootFor(storageRoot) : defaultTrashRoot());
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  String _trashDestFor(String trashDir, String originalPath) {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final base = p.basename(originalPath);
    var candidate = p.join(trashDir, '${stamp}_$base');
    var counter = 1;
    while (FileSystemEntity.typeSync(candidate) != FileSystemEntityType.notFound) {
      candidate = p.join(trashDir, '${stamp}_${counter}_$base');
      counter++;
    }
    return candidate;
  }

  Future<void> moveToTrash(String path) async {
    final entityType = FileSystemEntity.typeSync(path);
    if (entityType == FileSystemEntityType.notFound) return;

    final storageRoot = _nearestStorageRoot(path);
    final trashDir = await ensureTrashDir(storageRoot);
    final dest = _trashDestFor(trashDir.path, path);

    if (entityType == FileSystemEntityType.directory) {
      await Directory(path).rename(dest);
    } else {
      await File(path).rename(dest);
    }
  }

  String? _nearestStorageRoot(String path) {
    final normalized = p.normalize(path);
    for (final root in PermissionService.androidStorageRoots) {
      final r = p.normalize(root);
      if (normalized == r || normalized.startsWith('$r/')) return r;
    }
    final match = RegExp(r'^(/storage/[^/]+)').firstMatch(normalized);
    return match?.group(1);
  }

  Future<int> purgeExpired({int days = retentionDays}) async {
    var removed = 0;
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final roots = <String>{defaultTrashRoot()};
    final storageDir = Directory('/storage');
    if (storageDir.existsSync()) {
      try {
        for (final entity in storageDir.listSync(followLinks: false)) {
          if (entity is Directory) {
            roots.add(trashRootFor(entity.path));
          }
        }
      } catch (_) {}
    }

    for (final root in roots) {
      final dir = Directory(root);
      if (!dir.existsSync()) continue;
      for (final entity in dir.listSync(followLinks: false)) {
        try {
          final modified = entity.statSync().modified;
          if (modified.isBefore(cutoff)) {
            if (entity is Directory) {
              await entity.delete(recursive: true);
            } else if (entity is File) {
              await entity.delete();
            }
            removed++;
          }
        } catch (_) {}
      }
    }
    return removed;
  }
}
