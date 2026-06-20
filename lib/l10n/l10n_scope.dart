import 'package:cope_x_studio/l10n/app_locale.dart';
import 'package:cope_x_studio/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Global access to the active [AppLocalizations] for layers without [BuildContext].
abstract final class L10nScope {
  static Locale _locale = AppLocale.deviceDefault();

  static Locale get locale => _locale;

  static AppLocalizations get current => lookupAppLocalizations(_locale);

  static void update(Locale locale) {
    _locale = locale;
  }
}
