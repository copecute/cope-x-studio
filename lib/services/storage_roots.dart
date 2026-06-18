import 'dart:io';

import 'package:cope_x_studio/services/permission_service.dart';
import 'package:cope_x_studio/utils/path_utils.dart';
import 'package:path/path.dart' as p;

/// Khám phá các ổ / thư mục gốc có thể truy cập.
class StorageRoots {
  StorageRoots._();

  static List<String> discover(PermissionService permissionService) {
    if (Platform.isAndroid) {
      return _androidRoots(permissionService);
    }
    if (Platform.isWindows) {
      return _windowsRoots();
    }
    if (Platform.isMacOS) {
      final home = Platform.environment['HOME'] ?? '/Users';
      final roots = <String>['/'];
      if (Directory('/Volumes').existsSync()) roots.add('/Volumes');
      if (Directory(home).existsSync()) roots.add(p.normalize(home));
      return roots;
    }
    if (Platform.isLinux) {
      final home = Platform.environment['HOME'] ?? '/';
      return [home, '/'];
    }
    return [PathUtils.defaultBrowsePath(permissionService)];
  }

  static String defaultRoot(PermissionService permissionService) {
    return PathUtils.defaultBrowsePath(permissionService);
  }

  static List<String> _androidRoots(PermissionService permissionService) {
    final roots = <String>{};
    for (final root in PermissionService.androidStorageRoots) {
      if (Directory(root).existsSync()) roots.add(p.normalize(root));
    }
    final storageDir = Directory('/storage');
    if (storageDir.existsSync()) {
      try {
        for (final entity in storageDir.listSync(followLinks: false)) {
          if (entity is Directory) roots.add(p.normalize(entity.path));
        }
      } catch (_) {}
    }
    final resolved = permissionService.resolveAndroidStorageRoot();
    if (resolved != null) roots.add(p.normalize(resolved));
    if (roots.isEmpty) roots.add('/storage/emulated/0');
    return roots.toList()..sort();
  }

  static List<String> _windowsRoots() {
    final roots = <String>[];
    for (var code = 65; code <= 90; code++) {
      final drive = '${String.fromCharCode(code)}:\\';
      if (Directory(drive).existsSync()) roots.add(drive);
    }
    if (roots.isEmpty) {
      final home = Platform.environment['USERPROFILE'];
      if (home != null && Directory(home).existsSync()) {
        roots.add(p.normalize(home));
      } else {
        roots.add('C:\\');
      }
    }
    return roots;
  }
}
