import 'dart:io';

import 'package:cope_x_studio/services/permission_service.dart';
import 'package:path/path.dart' as p;

class PathUtils {
  static String normalize(String path) {
    final normalized = p.normalize(path);
    if (Platform.isWindows) {
      return normalized.replaceAll('/', '\\').toLowerCase();
    }
    return normalized;
  }

  static String displayName(String path) {
    final name = p.basename(path);
    return name.isEmpty ? path : name;
  }

  static String? parentPath(String path) {
    final parent = p.dirname(path);
    if (parent == path) return null;
    return parent;
  }

  static String defaultBrowsePath(PermissionService permissionService) {
    if (Platform.isAndroid) {
      return permissionService.resolveAndroidStorageRoot() ?? '/storage/emulated/0';
    }
    if (Platform.isWindows) {
      return Platform.environment['USERPROFILE'] ?? 'C:\\';
    }
    return Platform.environment['HOME'] ?? '/';
  }
}
