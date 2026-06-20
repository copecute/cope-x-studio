import 'dart:async';
import 'dart:convert';

import 'package:cope_x_studio/models/installed_app_info.dart';
import 'package:cope_x_studio/models/root_access_mode.dart';
import 'package:cope_x_studio/services/file_service.dart';
import 'package:cope_x_studio/services/shell_list_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:cope_x_studio/l10n/l10n_scope.dart';

class PlatformBridge {
  PlatformBridge({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('cope_x_studio/platform');

  final MethodChannel _channel;
  static const _rootAccessCheckTimeout = Duration(seconds: 6);

  Future<List<ListedEntry>> listDirectoryShell(
    String dirPath, {
    bool showHidden = false,
    RootAccessMode rootMode = RootAccessMode.normal,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      throw FileAccessException(dirPath, L10nScope.current.errShellListingAndroidOnly);
    }

    final result = await _channel.invokeMethod<List<dynamic>>(
      'listDirectoryShell',
      {
        'path': dirPath,
        'showHidden': showHidden,
        'useSu': rootMode.usesSuperuser,
        'mountWritable': rootMode.mountWritable,
      },
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

  Future<RootAccessCheckResult> checkRootAccess({required bool mountWritable}) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return RootAccessCheckResult(
        granted: false,
        message: L10nScope.current.errSuperuserAndroidOnly,
      );
    }

    try {
      final result = await _channel
          .invokeMethod<Map<dynamic, dynamic>>(
            'checkRootAccess',
            {'mountWritable': mountWritable},
          )
          .timeout(
            _rootAccessCheckTimeout,
            onTimeout: () => throw TimeoutException('root access check timeout'),
          );
      if (result == null) {
        return RootAccessCheckResult(
          granted: false,
          message: L10nScope.current.errCannotCheckSuperuser,
        );
      }
      return RootAccessCheckResult.fromMap(result);
    } on TimeoutException {
      return RootAccessCheckResult(
        granted: false,
        message: L10nScope.current.errSuperuserCheckTimeout,
      );
    } on PlatformException catch (e) {
      return RootAccessCheckResult(
        granted: false,
        message: e.message ?? L10nScope.current.errCannotCheckSuperuser,
      );
    }
  }

  Future<void> installApk(String apkPath) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      throw FileAccessException(apkPath, L10nScope.current.errInstallApkAndroidOnly);
    }
    await _channel.invokeMethod<void>('installApk', {'apkPath': apkPath});
  }

  Future<Uint8List?> getApkIconFromPath(String apkPath) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;

    final result = await _channel.invokeMethod<String>('getApkIconFromPath', {
      'apkPath': apkPath,
    });
    if (result == null || result.isEmpty) return null;
    try {
      return base64Decode(result);
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List?> getPdfThumbnailFromPath(
    String pdfPath, {
    int maxSize = 120,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;

    final result = await _channel.invokeMethod<String>('getPdfThumbnailFromPath', {
      'pdfPath': pdfPath,
      'maxSize': maxSize,
    });
    if (result == null || result.isEmpty) return null;
    try {
      return base64Decode(result);
    } catch (_) {
      return null;
    }
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
      throw FileAccessException(packageName, L10nScope.current.errApkNotFound);
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
