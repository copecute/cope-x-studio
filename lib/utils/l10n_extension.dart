import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

extension L10nContext on BuildContext {
  /// Short access to generated localizations, e.g. `context.l10n.settings`.
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
