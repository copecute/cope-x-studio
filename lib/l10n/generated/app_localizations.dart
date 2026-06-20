import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi')
  ];

  /// Application title shown in the task switcher and about screens.
  ///
  /// In en, this message translates to:
  /// **'Cope X Studio'**
  String get appTitle;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// Label for the @apps system shortcut.
  ///
  /// In en, this message translates to:
  /// **'App manager'**
  String get shortcutApps;

  /// No description provided for @shortcutSdCard.
  ///
  /// In en, this message translates to:
  /// **'SD card'**
  String get shortcutSdCard;

  /// No description provided for @shortcutInternalStorage.
  ///
  /// In en, this message translates to:
  /// **'Internal storage'**
  String get shortcutInternalStorage;

  /// No description provided for @shortcutSystemAppsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'System · Settings'**
  String get shortcutSystemAppsSubtitle;

  /// Archive extraction progress message.
  ///
  /// In en, this message translates to:
  /// **'Extracting: {percent}%'**
  String extractingProgress(int percent);

  /// Storage volume free space summary.
  ///
  /// In en, this message translates to:
  /// **'{free} free of {total}'**
  String storageFreeOfTotal(String free, String total);

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageVietnamese.
  ///
  /// In en, this message translates to:
  /// **'Vietnamese'**
  String get languageVietnamese;

  /// No description provided for @sectionAppLock.
  ///
  /// In en, this message translates to:
  /// **'App lock'**
  String get sectionAppLock;

  /// No description provided for @sectionBiometrics.
  ///
  /// In en, this message translates to:
  /// **'Biometrics'**
  String get sectionBiometrics;

  /// No description provided for @sectionRootAccess.
  ///
  /// In en, this message translates to:
  /// **'Root access'**
  String get sectionRootAccess;

  /// No description provided for @sectionDisplay.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get sectionDisplay;

  /// No description provided for @sectionTextEditor.
  ///
  /// In en, this message translates to:
  /// **'Text & editor'**
  String get sectionTextEditor;

  /// No description provided for @sectionUiAndActions.
  ///
  /// In en, this message translates to:
  /// **'UI & actions'**
  String get sectionUiAndActions;

  /// No description provided for @sectionApplication.
  ///
  /// In en, this message translates to:
  /// **'Application'**
  String get sectionApplication;

  /// No description provided for @appLockTitle.
  ///
  /// In en, this message translates to:
  /// **'App lock'**
  String get appLockTitle;

  /// No description provided for @appLockSubtitleActive.
  ///
  /// In en, this message translates to:
  /// **'Password required after 1 minute away. Tap to change password.'**
  String get appLockSubtitleActive;

  /// No description provided for @appLockSubtitleInactive.
  ///
  /// In en, this message translates to:
  /// **'Lock is off. Tap to change password.'**
  String get appLockSubtitleInactive;

  /// No description provided for @appLockSubtitleSetup.
  ///
  /// In en, this message translates to:
  /// **'Tap to set a password, then enable the switch to activate.'**
  String get appLockSubtitleSetup;

  /// No description provided for @passwordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed'**
  String get passwordChanged;

  /// No description provided for @passwordSet.
  ///
  /// In en, this message translates to:
  /// **'Password set'**
  String get passwordSet;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @setPassword.
  ///
  /// In en, this message translates to:
  /// **'Set password'**
  String get setPassword;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Password used to lock the app when reopened (after 1 minute away).'**
  String get passwordHint;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @passwordEmptyError.
  ///
  /// In en, this message translates to:
  /// **'Password cannot be empty'**
  String get passwordEmptyError;

  /// No description provided for @savePassword.
  ///
  /// In en, this message translates to:
  /// **'Save password'**
  String get savePassword;

  /// No description provided for @biometricNotSupported.
  ///
  /// In en, this message translates to:
  /// **'This device does not support fingerprint / Face ID.'**
  String get biometricNotSupported;

  /// No description provided for @biometricUnlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock with biometrics'**
  String get biometricUnlockTitle;

  /// No description provided for @biometricUnlockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use fingerprint or Face ID instead of password'**
  String get biometricUnlockSubtitle;

  /// No description provided for @biometricNeedsPassword.
  ///
  /// In en, this message translates to:
  /// **'Set a password first'**
  String get biometricNeedsPassword;

  /// No description provided for @checkingSuperuser.
  ///
  /// In en, this message translates to:
  /// **'Checking superuser access...'**
  String get checkingSuperuser;

  /// No description provided for @showHiddenFiles.
  ///
  /// In en, this message translates to:
  /// **'Show hidden files'**
  String get showHiddenFiles;

  /// No description provided for @showHiddenFilesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show dotfiles and system files'**
  String get showHiddenFilesSubtitle;

  /// No description provided for @openApkAsZip.
  ///
  /// In en, this message translates to:
  /// **'Open APK as ZIP'**
  String get openApkAsZip;

  /// No description provided for @openApkAsZipSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Browse APK files as ZIP. Turn off to open with the system installer.'**
  String get openApkAsZipSubtitle;

  /// No description provided for @textEncoding.
  ///
  /// In en, this message translates to:
  /// **'Text encoding'**
  String get textEncoding;

  /// No description provided for @textEncodingSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Text encoding'**
  String get textEncodingSheetTitle;

  /// No description provided for @textEncodingSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Used when opening and saving text files in the editor.'**
  String get textEncodingSheetSubtitle;

  /// No description provided for @editorFontSize.
  ///
  /// In en, this message translates to:
  /// **'Editor font size ({size})'**
  String editorFontSize(int size);

  /// No description provided for @editorFontSizeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Applies only in the editor, not the rest of the UI'**
  String get editorFontSizeSubtitle;

  /// No description provided for @editorLineNumbers.
  ///
  /// In en, this message translates to:
  /// **'Show line numbers'**
  String get editorLineNumbers;

  /// No description provided for @editorLineNumbersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Line number column on the left in the editor'**
  String get editorLineNumbersSubtitle;

  /// No description provided for @editorWordWrap.
  ///
  /// In en, this message translates to:
  /// **'Word wrap'**
  String get editorWordWrap;

  /// No description provided for @editorWordWrapSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Wrap long lines to fit the screen width'**
  String get editorWordWrapSubtitle;

  /// No description provided for @themeModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme mode'**
  String get themeModeTitle;

  /// No description provided for @uiScale.
  ///
  /// In en, this message translates to:
  /// **'Display scale ({percent}%)'**
  String uiScale(int percent);

  /// No description provided for @fullscreen.
  ///
  /// In en, this message translates to:
  /// **'Fullscreen'**
  String get fullscreen;

  /// No description provided for @fullscreenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hide the status bar and system navigation'**
  String get fullscreenSubtitle;

  /// No description provided for @hapticFeedback.
  ///
  /// In en, this message translates to:
  /// **'Haptic feedback on completion'**
  String get hapticFeedback;

  /// No description provided for @hapticFeedbackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Light vibration after copy, move, or delete'**
  String get hapticFeedbackSubtitle;

  /// No description provided for @rememberLastPath.
  ///
  /// In en, this message translates to:
  /// **'Remember last path'**
  String get rememberLastPath;

  /// No description provided for @rememberLastPathSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reopen tabs and folders after restarting the app'**
  String get rememberLastPathSubtitle;

  /// No description provided for @requireExitConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Confirm before exit'**
  String get requireExitConfirmation;

  /// No description provided for @requireExitConfirmationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show a dialog before closing the app'**
  String get requireExitConfirmationSubtitle;

  /// No description provided for @useTrash.
  ///
  /// In en, this message translates to:
  /// **'Use trash'**
  String get useTrash;

  /// No description provided for @useTrashSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Deleted files go to /copecute/.trash and are removed after 30 days'**
  String get useTrashSubtitle;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'vi': return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
