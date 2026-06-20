import 'package:flutter/material.dart';

enum AppThemeMode {
  dark,
  light,
  system;

  String get storageValue => name;

  String get label => switch (this) {
        AppThemeMode.dark => 'Tối',
        AppThemeMode.light => 'Sáng',
        AppThemeMode.system => 'Theo hệ thống',
      };

  ThemeMode get themeMode => switch (this) {
        AppThemeMode.dark => ThemeMode.dark,
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.system => ThemeMode.system,
      };

  static AppThemeMode fromStorage(String? value) {
    if (value == null || value.isEmpty) return AppThemeMode.dark;
    return AppThemeMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => AppThemeMode.dark,
    );
  }
}
