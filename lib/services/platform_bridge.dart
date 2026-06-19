import 'dart:convert';

import 'package:cope_x_studio/models/installed_app_info.dart';
import 'package:cope_x_studio/services/file_service.dart';
import 'package:cope_x_studio/services/shell_list_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PlatformBridge {
  PlatformBridge({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('cope_x_studio/platform');

  final MethodChannel _channel;

  Future<List<ListedEntry>> listDirectoryShell(
    String dirPath, {
    bool showHidden = false,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      throw FileAccessException(dirPath, 'Shell listing chỉ hỗ trợ Android');
    }

    final result = await _channel.invokeMethod<List<dynamic>>(
      'listDirectoryShell',
      {'path': dirPath, 'showHidden': showHidden},
    );
    if (result == null) return [];

    return result.map((item) {
      final map = Map<dynamic, dynamic>.from(item as Map);
      return ListedEntry(
        path: map['path'] as String,
        isDirectory: map['isDirectory'] as bool? ?? false,
      );
    }).toList();
  }

  Future<List<InstalledAppInfo>> listInstalledApps({required bool systemApps}) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return [];

    final result = await _channel.invokeMethod<List<dynamic>>(
      'listInstalledApps',
      {'systemApps': systemApps},
    );
    if (result == null) return [];

    return result
        .map((item) => InstalledAppInfo.fromMap(Map<dynamic, dynamic>.from(item as Map)))
        .toList();
  }

  Future<Uint8List?> getAppIcon(String packageName) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;

    final result = await _channel.invokeMethod<String>('getAppIcon', {
      'packageName': packageName,
    });
    if (result == null || result.isEmpty) return null;
    try {
      return base64Decode(result);
    } catch (_) {
      return null;
    }
  }

  Future<void> openAppSettings(String packageName) async {
    await _channel.invokeMethod<void>('openAppSettings', {'packageName': packageName});
  }

  Future<void> openApp(String packageName) async {
    await _channel.invokeMethod<void>('openApp', {'packageName': packageName});
  }

  Future<void> openPlayStore(String packageName) async {
    await _channel.invokeMethod<void>('openPlayStore', {'packageName': packageName});
  }

  Future<void> uninstallApp(String packageName) async {
    await _channel.invokeMethod<void>('uninstallApp', {'packageName': packageName});
  }

  Future<String> getApkPath(String packageName) async {
    final path = await _channel.invokeMethod<String>('getApkPath', {'packageName': packageName});
    if (path == null || path.isEmpty) {
      throw FileAccessException(packageName, 'Không tìm thấy APK');
    }
    return path;
  }

  Future<String> backupApk(String packageName, String destPath) async {
    final path = await _channel.invokeMethod<String>(
      'backupApk',
      {'packageName': packageName, 'destPath': destPath},
    );
    if (path == null || path.isEmpty) {
      throw FileAccessException(packageName, 'Backup thất bại');
    }
    return path;
  }
}
