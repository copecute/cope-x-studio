import 'package:flutter/material.dart';

/// Cấu hình badge đè trên icon thư mục vàng mặc định.
class FolderIconConfig {
  const FolderIconConfig({
    this.overlayIcon,
    this.badgeColor,
    this.badgeBgColor,
  });

  final IconData? overlayIcon;

  /// Màu icon đè và viền/nhấn badge.
  final Color? badgeColor;

  /// Nền badge; mặc định do widget lấy từ theme.
  final Color? badgeBgColor;

  static const plain = FolderIconConfig();
}

class _NamedFolderRule {
  const _NamedFolderRule(this.names, this.config);

  final Set<String> names;
  final FolderIconConfig config;
}

/// Thư mục nền luôn vàng — chỉ badge/icon đè đổi theo tên.
const _folderRules = <_NamedFolderRule>[
  _NamedFolderRule(
    {'copecute'},
    FolderIconConfig(
      overlayIcon: Icons.admin_panel_settings_rounded,
      badgeColor: Colors.red,
    ),
  ),
  _NamedFolderRule(
    {'download'},
    FolderIconConfig(
      overlayIcon: Icons.download_rounded,
      badgeColor: Colors.blue,
    ),
  ),
  _NamedFolderRule(
    {'dcim', 'camera', 'pictures'},
    FolderIconConfig(
      overlayIcon: Icons.image_rounded,
      badgeColor: Colors.deepOrange,
    ),
  ),
  _NamedFolderRule(
    {'movies', 'videos'},
    FolderIconConfig(
      overlayIcon: Icons.movie_creation_rounded,
      badgeColor: Colors.redAccent,
    ),
  ),
  _NamedFolderRule(
    {'music', 'audio', 'podcasts'},
    FolderIconConfig(
      overlayIcon: Icons.music_note_rounded,
      badgeColor: Colors.teal,
    ),
  ),
  _NamedFolderRule(
    {'ringtones', 'alarms'},
    FolderIconConfig(
      overlayIcon: Icons.notifications_active_rounded,
      badgeColor: Colors.cyan,
    ),
  ),
  _NamedFolderRule(
    {'notifications'},
    FolderIconConfig(
      overlayIcon: Icons.notifications_rounded,
      badgeColor: Colors.deepOrange,
    ),
  ),
  _NamedFolderRule(
    {'recordings'},
    FolderIconConfig(
      overlayIcon: Icons.mic_rounded,
      badgeColor: Colors.brown,
    ),
  ),
  _NamedFolderRule(
    {'documents', 'document'},
    FolderIconConfig(
      overlayIcon: Icons.description_rounded,
      badgeColor: Colors.indigo,
    ),
  ),
  _NamedFolderRule(
    {'code'},
    FolderIconConfig(
      overlayIcon: Icons.code_rounded,
      badgeColor: Colors.deepPurple,
    ),
  ),
  _NamedFolderRule(
    {'android'},
    FolderIconConfig(
      overlayIcon: Icons.android_rounded,
      badgeColor: Colors.green,
    ),
  ),
];

/// Trả về cấu hình badge theo tên thư mục (không phân biệt hoa thường).
FolderIconConfig folderIconConfigForName(String folderName) {
  final key = folderName.trim().toLowerCase();
  if (key.isEmpty) return FolderIconConfig.plain;

  for (final rule in _folderRules) {
    if (rule.names.contains(key)) return rule.config;
  }
  return FolderIconConfig.plain;
}

/// Màu thư mục nền cố định (vàng gốc app).
const folderIconBaseColor = Color(0xFFDCA458);
