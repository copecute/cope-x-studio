import 'dart:io';
import 'dart:typed_data';

import 'package:cope_x_studio/models/installed_app_info.dart';
import 'package:cope_x_studio/services/platform_bridge.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

class AppManagerService {
  AppManagerService({PlatformBridge? platform}) : _platform = platform ?? PlatformBridge();

  final PlatformBridge _platform;
  static const backupDir = '/storage/emulated/0/copecute/X-Studio/backup-apks';

  Future<List<InstalledAppInfo>> listApps({required bool systemApps}) {
    return _platform.listInstalledApps(systemApps: systemApps);
  }

  Future<Uint8List?> getAppIcon(String packageName) {
    return _platform.getAppIcon(packageName);
  }

  Future<void> openAppSettings(String packageName) => _platform.openAppSettings(packageName);

  Future<void> openApp(String packageName) => _platform.openApp(packageName);

  Future<void> openPlayStore(String packageName) => _platform.openPlayStore(packageName);

  Future<void> uninstallApp(String packageName) => _platform.uninstallApp(packageName);

  Future<String> resolveApkPath(InstalledAppInfo app) async {
    if (app.apkPath.isNotEmpty && File(app.apkPath).existsSync()) {
      return app.apkPath;
    }
    return _platform.getApkPath(app.packageName);
  }

  Future<void> shareApk(InstalledAppInfo app) async {
    final path = await resolveApkPath(app);
    await SharePlus.instance.share(ShareParams(files: [XFile(path)]));
  }

  Future<String> backupApk(InstalledAppInfo app) async {
    final safeName = _safeFileName('${app.appName}_${app.versionName}.apk');
    final dest = p.join(backupDir, safeName);
    return _platform.backupApk(app.packageName, dest);
  }

  static String formatSubtitle(InstalledAppInfo app) {
    final date = DateFormat('dd/MM/yyyy').format(app.updateTime);
    final size = _formatSize(app.apkSize);
    final version = app.versionName.isEmpty ? 'v${app.versionCode}' : 'v${app.versionName}';
    return '$date · $size · $version';
  }

  static String _formatSize(int size) {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  static String _safeFileName(String name) {
    return name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }
}
