import 'dart:convert';
import 'dart:typed_data';

class InstalledAppInfo {
  const InstalledAppInfo({
    required this.packageName,
    required this.appName,
    required this.versionName,
    required this.versionCode,
    required this.installTime,
    required this.updateTime,
    required this.apkSize,
    required this.apkPath,
    required this.isSystem,
    this.iconBytes,
  });

  final String packageName;
  final String appName;
  final String versionName;
  final int versionCode;
  final DateTime installTime;
  final DateTime updateTime;
  final int apkSize;
  final String apkPath;
  final bool isSystem;
  final Uint8List? iconBytes;

  String get virtualPath => '@apps/pkg/$packageName';

  factory InstalledAppInfo.fromMap(Map<dynamic, dynamic> map) {
    Uint8List? icon;
    final iconBase64 = map['iconBase64'] as String?;
    if (iconBase64 != null && iconBase64.isNotEmpty) {
      try {
        icon = base64Decode(iconBase64);
      } catch (_) {}
    }

    return InstalledAppInfo(
      packageName: map['packageName'] as String,
      appName: map['appName'] as String? ?? map['packageName'] as String,
      versionName: map['versionName'] as String? ?? '',
      versionCode: (map['versionCode'] as num?)?.toInt() ?? 0,
      installTime: DateTime.fromMillisecondsSinceEpoch(
        (map['installTime'] as num?)?.toInt() ?? 0,
      ),
      updateTime: DateTime.fromMillisecondsSinceEpoch(
        (map['updateTime'] as num?)?.toInt() ?? 0,
      ),
      apkSize: (map['apkSize'] as num?)?.toInt() ?? 0,
      apkPath: map['apkPath'] as String? ?? '',
      isSystem: map['isSystem'] as bool? ?? false,
      iconBytes: icon,
    );
  }
}
