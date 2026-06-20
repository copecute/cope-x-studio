import 'package:cope_x_studio/l10n/l10n_scope.dart';
import 'package:flutter/material.dart';

enum AppThemeMode {
  dark,
  light,
  system;

  String get storageValue => name;

  String get label => switch (this) {
        AppThemeMode.dark => L10nScope.current.themeDark,
        AppThemeMode.light => L10nScope.current.themeLight,
        AppThemeMode.system => L10nScope.current.themeSystem,
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
