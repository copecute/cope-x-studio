import 'dart:io';

import 'package:cope_x_studio/services/permission_service.dart';
import 'package:cope_x_studio/utils/app_path_utils.dart';
import 'package:path/path.dart' as p;

class PathUtils {
  static String normalize(String path) {
    final normalized = p.normalize(path);
    if (Platform.isWindows) {
      return normalized.replaceAll('/', '\\').toLowerCase();
    }
    return normalized;
  }

  /// Màn hình được phép dùng «Nén thư mục hiện tại» (bộ nhớ, root, gần đây, FTP).
  static bool canZipCurrentFolder(String path, {bool isZipViewer = false}) {
    if (isZipViewer) return false;
    if (path == '@home' || path == '@apps' || path == '@ftp') return false;
    if (AppPathUtils.isAppsList(path) || AppPathUtils.isAppPackage(path)) return false;
    if (path.startsWith('@ftp/')) return true;
    if (path == '@recent') return true;
    return !path.startsWith('@');
  }

  static String displayName(String path) {
    switch (path) {
      case '@home':
        return 'Trang chủ';
      case '@recent':
        return 'Các tập tin gần đây';
      case '@ftp':
        return 'FTP';
      case '@apps':
        return 'Trình quản lý ứng dụng';
    }
    if (AppPathUtils.isAppsList(path)) {
      return AppPathUtils.isSystemList(path) ? 'Hệ thống' : 'Cài đặt';
    }
    if (AppPathUtils.isAppPackage(path)) {
      final pkg = AppPathUtils.packageFromPath(path);
      return pkg ?? path;
    }
    final name = p.basename(path);
    return name.isEmpty ? path : name;
  }

  static String? parentPath(String path) {
    final parent = p.dirname(path);
    if (parent == path) return null;
    return parent;
  }

  /// Đường dẫn thư mục chứa file, rút gọn sau `/storage/emulated/0` (hoặc ổ tương đương).
  /// Ví dụ: `/storage/emulated/0/copecute/a.php` → `/copecute`
  static String shortDisplayDir(String filePath) {
    final normalized = p.normalize(filePath.replaceAll('\\', '/'));
    final parent = p.dirname(normalized);

    const roots = ['/storage/emulated/0', '/sdcard'];
    for (final root in roots) {
      if (parent == root || parent.startsWith('$root/')) {
        final suffix = parent.length == root.length ? '' : parent.substring(root.length);
        return suffix.isEmpty ? '/' : suffix;
      }
    }

    final storageMatch = RegExp(r'^/storage/[^/]+').firstMatch(parent);
    if (storageMatch != null) {
      final root = storageMatch.group(0)!;
      if (parent == root || parent.startsWith('$root/')) {
        final suffix = parent.length == root.length ? '' : parent.substring(root.length);
        return suffix.isEmpty ? '/' : suffix;
      }
    }

    const marker = '/emulated/0';
    final idx = parent.indexOf(marker);
    if (idx != -1) {
      final suffix = parent.substring(idx + marker.length);
      return suffix.isEmpty ? '/' : suffix;
    }

    if (Platform.isWindows) {
      final home = Platform.environment['USERPROFILE'];
      if (home != null) {
        final homeNorm = p.normalize(home.replaceAll('\\', '/'));
        if (parent == homeNorm || parent.startsWith('$homeNorm/')) {
          final suffix = parent.length == homeNorm.length ? '' : parent.substring(homeNorm.length);
          return suffix.isEmpty ? '/' : suffix.replaceAll('\\', '/');
        }
      }
    }

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
