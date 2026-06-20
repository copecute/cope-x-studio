import 'package:flutter/widgets.dart';
import 'package:cope_x_studio/l10n/generated/app_localizations.dart';

extension L10nContext on BuildContext {
  /// Short access to generated localizations, e.g. `context.l10n.settings`.
  AppLocalizations get l10n => AppLocalizations.of(this);
}
