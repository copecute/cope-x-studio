import 'dart:io';

import 'package:cope_x_studio/services/permission_service.dart';
import 'package:cope_x_studio/utils/path_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Ổ bộ nhớ hiển thị trên màn hình @home.
class HomeStorageVolume {
  const HomeStorageVolume({
    required this.path,
    required this.isRemovable,
    this.volumeId,
  });

  final String path;
  final bool isRemovable;

  /// Mã volume (ví dụ `A1B2-C3D4` từ `/storage/A1B2-C3D4`).
  final String? volumeId;
}

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

  /// Quét bộ nhớ trong + thẻ SD / USB OTG cho màn hình @home.
  static Future<List<HomeStorageVolume>> discoverHomeVolumes(
    PermissionService permissionService,
  ) async {
    if (kIsWeb || !Platform.isAndroid) {
      final root = defaultRoot(permissionService);
      return [HomeStorageVolume(path: p.normalize(root), isRemovable: false)];
    }

    final scannedRoots = <String>{};

    try {
      final primary = await getExternalStorageDirectory();
      if (primary != null) {
        final root = extractAndroidStorageRoot(primary.path);
        if (root != null && Directory(root).existsSync()) {
          scannedRoots.add(p.normalize(root));
        }
      }
    } catch (_) {}

    try {
      final dirs = await getExternalStorageDirectories();
      if (dirs != null) {
        for (final dir in dirs) {
          final root = extractAndroidStorageRoot(dir.path);
          if (root != null && Directory(root).existsSync()) {
            scannedRoots.add(p.normalize(root));
          }
        }
      }
    } catch (_) {}

    for (final root in _androidRoots(permissionService)) {
      scannedRoots.add(p.normalize(root));
    }

    if (scannedRoots.isEmpty) {
      scannedRoots.add('/storage/emulated/0');
    }

    final internalPath = _pickInternalStoragePath(scannedRoots, permissionService);
    final externalPaths = scannedRoots
        .where((root) => !_isInternalStoragePath(root))
        .where((root) => !root.contains('self'))
        .map(p.normalize)
        .toSet()
        .toList()
      ..sort();

    final volumes = <HomeStorageVolume>[
      HomeStorageVolume(path: internalPath, isRemovable: false),
    ];

    for (final path in externalPaths) {
      if (path == internalPath) continue;
      volumes.add(
        HomeStorageVolume(
          path: path,
          isRemovable: true,
          volumeId: p.basename(path),
        ),
      );
    }

    return volumes;
  }

  /// Bóc tách đường dẫn gốc `/storage/XXXX-XXXX` từ đường dẫn app-specific.
  static String? extractAndroidStorageRoot(String appSpecificPath) {
    final normalized = p.normalize(appSpecificPath);
    final match = RegExp(r'^(/storage/[^/]+)').firstMatch(normalized);
    return match?.group(1);
  }

  static bool _isInternalStoragePath(String path) {
    return path.contains('emulated') || path == '/sdcard';
  }

  static String _pickInternalStoragePath(
    Set<String> roots,
    PermissionService permissionService,
  ) {
    const preferred = '/storage/emulated/0';
    if (Directory(preferred).existsSync()) return preferred;

    for (final root in roots) {
      if (_isInternalStoragePath(root)) return p.normalize(root);
    }

    final resolved = permissionService.resolveAndroidStorageRoot();
    if (resolved != null) return p.normalize(resolved);

    return preferred;
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
