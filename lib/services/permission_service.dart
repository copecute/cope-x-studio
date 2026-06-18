import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

class PermissionService {
  static const androidStorageRoots = [
    '/storage/emulated/0',
    '/sdcard',
  ];

  /// Chỉ kiểm tra MANAGE_EXTERNAL_STORAGE (Android 11+) hoặc storage (Android 10-).
  Future<bool> hasManageExternalStorage() async {
    if (kIsWeb || Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return true;
    }
    if (!Platform.isAndroid) return true;

    if (await ph.Permission.manageExternalStorage.isGranted) return true;

    // Android 10 trở xuống dùng storage
    return ph.Permission.storage.isGranted;
  }

  /// Mở màn hình hệ thống để bật "Truy cập tất cả file" (MANAGE_EXTERNAL_STORAGE).
  /// Trên Android 11+, [request] sẽ chuyển tới Settings — người dùng bật toggle thủ công.
  Future<PermissionResult> requestManageExternalStorage() async {
    if (kIsWeb || Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return PermissionResult.granted;
    }
    if (!Platform.isAndroid) return PermissionResult.granted;

    // Android 11+ (API 30+): MANAGE_EXTERNAL_STORAGE
    final manageStatus = await ph.Permission.manageExternalStorage.status;
    if (manageStatus.isGranted) return PermissionResult.granted;

    final manageResult = await ph.Permission.manageExternalStorage.request();
    if (manageResult.isGranted) return PermissionResult.granted;

    // Android 10 trở xuống: READ/WRITE_EXTERNAL_STORAGE
    final storageResult = await ph.Permission.storage.request();
    if (storageResult.isGranted) return PermissionResult.granted;

    if (manageResult.isPermanentlyDenied || storageResult.isPermanentlyDenied) {
      return PermissionResult.permanentlyDenied;
    }
    // Đã mở Settings nhưng chưa bật toggle → denied
    return PermissionResult.denied;
  }

  /// Tìm thư mục gốc bộ nhớ trong thiết bị Android.
  String? resolveAndroidStorageRoot() {
    if (!Platform.isAndroid) return null;
    for (final root in androidStorageRoots) {
      if (Directory(root).existsSync()) return root;
    }
    return null;
  }

  Future<void> openAllFilesAccessSettings() => ph.openAppSettings();
}

enum PermissionResult {
  granted,
  denied,
  permanentlyDenied,
}
