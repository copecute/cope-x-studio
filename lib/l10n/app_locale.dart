import 'dart:ui';

import 'package:flutter/material.dart';

/// Supported app locales and helpers shared by [LocaleProvider] and [MaterialApp].
abstract final class AppLocale {
  static const Locale english = Locale('en');
  static const Locale vietnamese = Locale('vi');

  static const List<Locale> supported = [english, vietnamese];

  static const String storageKey = 'app_locale';

  /// English by default; Vietnamese when the device locale is Vietnamese.
  static Locale deviceDefault() {
    final code = PlatformDispatcher.instance.locale.languageCode;
    return code == 'vi' ? vietnamese : english;
  }

  static Locale? fromLanguageCode(String? code) {
    if (code == null || code.isEmpty) return null;
    return supported.firstWhere(
      (locale) => locale.languageCode == code,
      orElse: () => english,
    );
  }
}
