import 'package:cope_x_studio/l10n/generated/app_localizations.dart';
import 'package:cope_x_studio/l10n/l10n_scope.dart';
import 'package:cope_x_studio/models/app_theme_mode.dart';
import 'package:cope_x_studio/models/browser_view_mode.dart';
import 'package:cope_x_studio/models/root_access_mode.dart';
import 'package:cope_x_studio/models/tab_file_operation.dart';
import 'package:cope_x_studio/models/tab_file_operation_state.dart';

extension RootAccessModeL10n on RootAccessMode {
  String localizedLabel([AppLocalizations? l10n]) {
    final l = l10n ?? L10nScope.current;
    return switch (this) {
      RootAccessMode.disabled => l.rootAccessDisabled,
      RootAccessMode.normal => l.rootAccessNormal,
      RootAccessMode.superuser => l.rootAccessSuperuser,
      RootAccessMode.superuserMountWritable => l.rootAccessSuperuserWritable,
    };
  }

  String localizedDescription([AppLocalizations? l10n]) {
    final l = l10n ?? L10nScope.current;
    return switch (this) {
      RootAccessMode.disabled => l.rootAccessDisabledDesc,
      RootAccessMode.normal => l.rootAccessNormalDesc,
      RootAccessMode.superuser => l.rootAccessSuperuserDesc,
      RootAccessMode.superuserMountWritable => l.rootAccessSuperuserWritableDesc,
    };
  }
}

extension AppThemeModeL10n on AppThemeMode {
  String localizedLabel([AppLocalizations? l10n]) {
    final l = l10n ?? L10nScope.current;
    return switch (this) {
      AppThemeMode.dark => l.themeDark,
      AppThemeMode.light => l.themeLight,
      AppThemeMode.system => l.themeSystem,
    };
  }
}

extension BrowserViewModeL10n on BrowserViewMode {
  String localizedLabel([AppLocalizations? l10n]) {
    final l = l10n ?? L10nScope.current;
    return switch (this) {
      BrowserViewMode.list => l.viewModeList,
      BrowserViewMode.grid => l.viewModeGrid,
      BrowserViewMode.tree => l.viewModeTree,
    };
  }
}

extension TabFileOperationStateL10n on TabFileOperationState {
  String localizedOverlayTitle([AppLocalizations? l10n]) {
    final l = l10n ?? L10nScope.current;
    if (isRollingBack) return l.rollingBack;
    return switch (type) {
      TabFileOperation.unzip => l.unzipping,
      TabFileOperation.zip => l.zipping,
      TabFileOperation.delete => l.deleting,
      TabFileOperation.paste => l.pasting,
      TabFileOperation.duplicate => l.duplicating,
      TabFileOperation.none => '',
    };
  }
}
