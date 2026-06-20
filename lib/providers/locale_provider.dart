import 'dart:ui';

import 'package:cope_x_studio/l10n/app_locale.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the active UI locale and persists the user's choice.
class LocaleProvider extends ChangeNotifier {
  Locale? _locale;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  /// Effective locale: saved preference, otherwise device-based default.
  Locale get locale => _locale ?? AppLocale.deviceDefault();

  /// Loads persisted locale before the first frame when possible.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(AppLocale.storageKey);
    _locale = AppLocale.fromLanguageCode(saved);
    _initialized = true;
    notifyListeners();
  }

  Future<void> setLocale(Locale value) async {
    if (!AppLocale.supported.any((l) => l.languageCode == value.languageCode)) {
      return;
    }
    if (_locale?.languageCode == value.languageCode) return;

    _locale = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppLocale.storageKey, value.languageCode);
  }

  bool isSelected(Locale candidate) => locale.languageCode == candidate.languageCode;
}
