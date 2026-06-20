// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Cope X Studio';

  @override
  String get settings => 'Settings';

  @override
  String get back => 'Back';

  @override
  String get cancel => 'Cancel';

  @override
  String get ok => 'OK';

  @override
  String get confirm => 'Confirm';

  @override
  String get save => 'Save';

  @override
  String get close => 'Close';

  @override
  String get delete => 'Delete';

  @override
  String get rename => 'Rename';

  @override
  String get search => 'Search';

  @override
  String get retry => 'Retry';

  @override
  String get done => 'Done';

  @override
  String get shortcutApps => 'App manager';

  @override
  String get shortcutSdCard => 'SD card';

  @override
  String get shortcutInternalStorage => 'Internal storage';

  @override
  String get shortcutSystemAppsSubtitle => 'System · Settings';

  @override
  String extractingProgress(int percent) {
    return 'Extracting: $percent%';
  }

  @override
  String storageFreeOfTotal(String free, String total) {
    return '$free free of $total';
  }

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageVietnamese => 'Vietnamese';

  @override
  String get sectionAppLock => 'App lock';

  @override
  String get sectionBiometrics => 'Biometrics';

  @override
  String get sectionRootAccess => 'Root access';

  @override
  String get sectionDisplay => 'Display';

  @override
  String get sectionTextEditor => 'Text & editor';

  @override
  String get sectionUiAndActions => 'UI & actions';

  @override
  String get sectionApplication => 'Application';

  @override
  String get appLockTitle => 'App lock';

  @override
  String get appLockSubtitleActive => 'Password required after 1 minute away. Tap to change password.';

  @override
  String get appLockSubtitleInactive => 'Lock is off. Tap to change password.';

  @override
  String get appLockSubtitleSetup => 'Tap to set a password, then enable the switch to activate.';

  @override
  String get passwordChanged => 'Password changed';

  @override
  String get passwordSet => 'Password set';

  @override
  String get changePassword => 'Change password';

  @override
  String get setPassword => 'Set password';

  @override
  String get passwordHint => 'Password used to lock the app when reopened (after 1 minute away).';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordEmptyError => 'Password cannot be empty';

  @override
  String get savePassword => 'Save password';

  @override
  String get biometricNotSupported => 'This device does not support fingerprint / Face ID.';

  @override
  String get biometricUnlockTitle => 'Unlock with biometrics';

  @override
  String get biometricUnlockSubtitle => 'Use fingerprint or Face ID instead of password';

  @override
  String get biometricNeedsPassword => 'Set a password first';

  @override
  String get checkingSuperuser => 'Checking superuser access...';

  @override
  String get showHiddenFiles => 'Show hidden files';

  @override
  String get showHiddenFilesSubtitle => 'Show dotfiles and system files';

  @override
  String get openApkAsZip => 'Open APK as ZIP';

  @override
  String get openApkAsZipSubtitle => 'Browse APK files as ZIP. Turn off to open with the system installer.';

  @override
  String get textEncoding => 'Text encoding';

  @override
  String get textEncodingSheetTitle => 'Text encoding';

  @override
  String get textEncodingSheetSubtitle => 'Used when opening and saving text files in the editor.';

  @override
  String editorFontSize(int size) {
    return 'Editor font size ($size)';
  }

  @override
  String get editorFontSizeSubtitle => 'Applies only in the editor, not the rest of the UI';

  @override
  String get editorLineNumbers => 'Show line numbers';

  @override
  String get editorLineNumbersSubtitle => 'Line number column on the left in the editor';

  @override
  String get editorWordWrap => 'Word wrap';

  @override
  String get editorWordWrapSubtitle => 'Wrap long lines to fit the screen width';

  @override
  String get themeModeTitle => 'Theme mode';

  @override
  String uiScale(int percent) {
    return 'Display scale ($percent%)';
  }

  @override
  String get fullscreen => 'Fullscreen';

  @override
  String get fullscreenSubtitle => 'Hide the status bar and system navigation';

  @override
  String get hapticFeedback => 'Haptic feedback on completion';

  @override
  String get hapticFeedbackSubtitle => 'Light vibration after copy, move, or delete';

  @override
  String get rememberLastPath => 'Remember last path';

  @override
  String get rememberLastPathSubtitle => 'Reopen tabs and folders after restarting the app';

  @override
  String get requireExitConfirmation => 'Confirm before exit';

  @override
  String get requireExitConfirmationSubtitle => 'Show a dialog before closing the app';

  @override
  String get useTrash => 'Use trash';

  @override
  String get useTrashSubtitle => 'Deleted files go to /copecute/.trash and are removed after 30 days';
}
