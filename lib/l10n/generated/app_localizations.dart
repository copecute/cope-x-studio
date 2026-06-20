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

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @cut.
  ///
  /// In en, this message translates to:
  /// **'Cut'**
  String get cut;

  /// No description provided for @paste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get paste;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @parentFolder.
  ///
  /// In en, this message translates to:
  /// **'Parent folder'**
  String get parentFolder;

  /// No description provided for @extract.
  ///
  /// In en, this message translates to:
  /// **'Extract'**
  String get extract;

  /// No description provided for @searchInFolder.
  ///
  /// In en, this message translates to:
  /// **'Search in folder...'**
  String get searchInFolder;

  /// No description provided for @hideHiddenFilesToggle.
  ///
  /// In en, this message translates to:
  /// **'Hide hidden files'**
  String get hideHiddenFilesToggle;

  /// No description provided for @showHiddenFilesToggle.
  ///
  /// In en, this message translates to:
  /// **'Show hidden files'**
  String get showHiddenFilesToggle;

  /// No description provided for @pleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait...'**
  String get pleaseWait;

  /// No description provided for @understood.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get understood;

  /// No description provided for @grantPermission.
  ///
  /// In en, this message translates to:
  /// **'Grant permission'**
  String get grantPermission;

  /// No description provided for @storagePermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'All-files access required'**
  String get storagePermissionTitle;

  /// No description provided for @storagePermissionBody.
  ///
  /// In en, this message translates to:
  /// **'Enable MANAGE_EXTERNAL_STORAGE to browse all storage.'**
  String get storagePermissionBody;

  /// No description provided for @newFile.
  ///
  /// In en, this message translates to:
  /// **'New file'**
  String get newFile;

  /// No description provided for @newFolder.
  ///
  /// In en, this message translates to:
  /// **'New folder'**
  String get newFolder;

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedCount(int count);

  /// No description provided for @duplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicate;

  /// No description provided for @installApk.
  ///
  /// In en, this message translates to:
  /// **'Install APK'**
  String get installApk;

  /// No description provided for @openAs.
  ///
  /// In en, this message translates to:
  /// **'Open as'**
  String get openAs;

  /// No description provided for @openWithSystem.
  ///
  /// In en, this message translates to:
  /// **'Open with another app'**
  String get openWithSystem;

  /// No description provided for @openInNewTab.
  ///
  /// In en, this message translates to:
  /// **'Open in new tab'**
  String get openInNewTab;

  /// No description provided for @revealLocation.
  ///
  /// In en, this message translates to:
  /// **'Show file location'**
  String get revealLocation;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @openApp.
  ///
  /// In en, this message translates to:
  /// **'Open app'**
  String get openApp;

  /// No description provided for @appInfo.
  ///
  /// In en, this message translates to:
  /// **'App info'**
  String get appInfo;

  /// No description provided for @copyApk.
  ///
  /// In en, this message translates to:
  /// **'Copy APK'**
  String get copyApk;

  /// No description provided for @shareApk.
  ///
  /// In en, this message translates to:
  /// **'Share APK'**
  String get shareApk;

  /// No description provided for @viewPlayStore.
  ///
  /// In en, this message translates to:
  /// **'View on Play Store'**
  String get viewPlayStore;

  /// No description provided for @backupApk.
  ///
  /// In en, this message translates to:
  /// **'Backup APK (Extract)'**
  String get backupApk;

  /// No description provided for @uninstall.
  ///
  /// In en, this message translates to:
  /// **'Uninstall'**
  String get uninstall;

  /// No description provided for @openAsText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get openAsText;

  /// No description provided for @openAsImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get openAsImage;

  /// No description provided for @openAsAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get openAsAudio;

  /// No description provided for @openAsVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get openAsVideo;

  /// No description provided for @openAsArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get openAsArchive;

  /// No description provided for @viewModeList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get viewModeList;

  /// No description provided for @viewModeGrid.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get viewModeGrid;

  /// No description provided for @viewModeTree.
  ///
  /// In en, this message translates to:
  /// **'Folder tree'**
  String get viewModeTree;

  /// No description provided for @emptyFolder.
  ///
  /// In en, this message translates to:
  /// **'Folder is empty'**
  String get emptyFolder;

  /// No description provided for @emptyZip.
  ///
  /// In en, this message translates to:
  /// **'ZIP is empty'**
  String get emptyZip;

  /// No description provided for @noApps.
  ///
  /// In en, this message translates to:
  /// **'No apps'**
  String get noApps;

  /// No description provided for @noRecentFiles.
  ///
  /// In en, this message translates to:
  /// **'No recent files'**
  String get noRecentFiles;

  /// No description provided for @noSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noSearchResults;

  /// No description provided for @loadingFtp.
  ///
  /// In en, this message translates to:
  /// **'Loading FTP folder...'**
  String get loadingFtp;

  /// No description provided for @loadingZip.
  ///
  /// In en, this message translates to:
  /// **'Reading ZIP contents...'**
  String get loadingZip;

  /// No description provided for @loadingDirectory.
  ///
  /// In en, this message translates to:
  /// **'Reading folder...'**
  String get loadingDirectory;

  /// No description provided for @loadingApps.
  ///
  /// In en, this message translates to:
  /// **'Loading app list...'**
  String get loadingApps;

  /// No description provided for @scanningStorage.
  ///
  /// In en, this message translates to:
  /// **'Scanning storage...'**
  String get scanningStorage;

  /// No description provided for @scanningRecent.
  ///
  /// In en, this message translates to:
  /// **'Scanning recent files...'**
  String get scanningRecent;

  /// No description provided for @extractingAndOpening.
  ///
  /// In en, this message translates to:
  /// **'Extracting and opening file...'**
  String get extractingAndOpening;

  /// No description provided for @ftpConnectionError.
  ///
  /// In en, this message translates to:
  /// **'FTP connection error'**
  String get ftpConnectionError;

  /// No description provided for @cannotReadDirectory.
  ///
  /// In en, this message translates to:
  /// **'Cannot read folder'**
  String get cannotReadDirectory;

  /// No description provided for @cannotReadPath.
  ///
  /// In en, this message translates to:
  /// **'Cannot read {name}'**
  String cannotReadPath(String name);

  /// No description provided for @cannotLoadApps.
  ///
  /// In en, this message translates to:
  /// **'Cannot load apps'**
  String get cannotLoadApps;

  /// No description provided for @pathCopied.
  ///
  /// In en, this message translates to:
  /// **'Path copied: {path}'**
  String pathCopied(String path);

  /// No description provided for @noFilesToZip.
  ///
  /// In en, this message translates to:
  /// **'No files to compress'**
  String get noFilesToZip;

  /// No description provided for @formatNotSupportedExtract.
  ///
  /// In en, this message translates to:
  /// **'Format {format} is not supported for extraction.'**
  String formatNotSupportedExtract(String format);

  /// No description provided for @zipPasswordExtractTitle.
  ///
  /// In en, this message translates to:
  /// **'Extract password-protected ZIP'**
  String get zipPasswordExtractTitle;

  /// No description provided for @zipFileTitle.
  ///
  /// In en, this message translates to:
  /// **'Compress to ZIP'**
  String get zipFileTitle;

  /// No description provided for @fileName.
  ///
  /// In en, this message translates to:
  /// **'File name'**
  String get fileName;

  /// No description provided for @passwordProtect.
  ///
  /// In en, this message translates to:
  /// **'Password protect'**
  String get passwordProtect;

  /// No description provided for @compress.
  ///
  /// In en, this message translates to:
  /// **'Compress'**
  String get compress;

  /// No description provided for @passwordOptional.
  ///
  /// In en, this message translates to:
  /// **'Password (optional)'**
  String get passwordOptional;

  /// No description provided for @wrongPasswordRetry.
  ///
  /// In en, this message translates to:
  /// **'Wrong password. Please try again.'**
  String get wrongPasswordRetry;

  /// No description provided for @zipPasswordProtected.
  ///
  /// In en, this message translates to:
  /// **'Archive is password protected.'**
  String get zipPasswordProtected;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @editFtpConfig.
  ///
  /// In en, this message translates to:
  /// **'Edit configuration'**
  String get editFtpConfig;

  /// No description provided for @deleteFtpServer.
  ///
  /// In en, this message translates to:
  /// **'Delete server configuration'**
  String get deleteFtpServer;

  /// No description provided for @editFtpServer.
  ///
  /// In en, this message translates to:
  /// **'Edit FTP server'**
  String get editFtpServer;

  /// No description provided for @addFtpServer.
  ///
  /// In en, this message translates to:
  /// **'Add FTP server'**
  String get addFtpServer;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get displayName;

  /// No description provided for @hostAddress.
  ///
  /// In en, this message translates to:
  /// **'IP address / Host'**
  String get hostAddress;

  /// No description provided for @port.
  ///
  /// In en, this message translates to:
  /// **'Port (Port)'**
  String get port;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @itemCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String itemCount(int count);

  /// No description provided for @zipCurrentFolder.
  ///
  /// In en, this message translates to:
  /// **'Compress current folder'**
  String get zipCurrentFolder;

  /// No description provided for @zipRecentFiles.
  ///
  /// In en, this message translates to:
  /// **'Compress recent files'**
  String get zipRecentFiles;

  /// No description provided for @zipCopiedItems.
  ///
  /// In en, this message translates to:
  /// **'Compress copied items'**
  String get zipCopiedItems;

  /// No description provided for @deselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect all'**
  String get deselectAll;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectAll;

  /// No description provided for @move.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get move;

  /// No description provided for @shortcutHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get shortcutHome;

  /// No description provided for @shortcutRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent files'**
  String get shortcutRecent;

  /// No description provided for @shortcutFtp.
  ///
  /// In en, this message translates to:
  /// **'FTP'**
  String get shortcutFtp;

  /// No description provided for @shortcutAddFtp.
  ///
  /// In en, this message translates to:
  /// **'+ Add server'**
  String get shortcutAddFtp;

  /// No description provided for @deviceStorage.
  ///
  /// In en, this message translates to:
  /// **'Device storage'**
  String get deviceStorage;

  /// No description provided for @systemApps.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemApps;

  /// No description provided for @userApps.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get userApps;

  /// No description provided for @systemApp.
  ///
  /// In en, this message translates to:
  /// **'System app'**
  String get systemApp;

  /// No description provided for @userApp.
  ///
  /// In en, this message translates to:
  /// **'User-installed app'**
  String get userApp;

  /// No description provided for @accessDenied.
  ///
  /// In en, this message translates to:
  /// **'Access denied'**
  String get accessDenied;

  /// No description provided for @superuserNotGranted.
  ///
  /// In en, this message translates to:
  /// **'Superuser access not granted'**
  String get superuserNotGranted;

  /// No description provided for @superuserRevertedNormal.
  ///
  /// In en, this message translates to:
  /// **'Superuser access not granted — reverted to Normal'**
  String get superuserRevertedNormal;

  /// No description provided for @wrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Wrong password'**
  String get wrongPassword;

  /// No description provided for @cancelUnzip.
  ///
  /// In en, this message translates to:
  /// **'Extraction cancelled'**
  String get cancelUnzip;

  /// No description provided for @cancelZip.
  ///
  /// In en, this message translates to:
  /// **'Compression cancelled'**
  String get cancelZip;

  /// No description provided for @cancelPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste cancelled'**
  String get cancelPaste;

  /// No description provided for @cancelDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate cancelled'**
  String get cancelDuplicate;

  /// No description provided for @cancelOperation.
  ///
  /// In en, this message translates to:
  /// **'Operation cancelled'**
  String get cancelOperation;

  /// No description provided for @rollingBack.
  ///
  /// In en, this message translates to:
  /// **'Rolling back...'**
  String get rollingBack;

  /// No description provided for @zipping.
  ///
  /// In en, this message translates to:
  /// **'Compressing...'**
  String get zipping;

  /// No description provided for @deleting.
  ///
  /// In en, this message translates to:
  /// **'Deleting...'**
  String get deleting;

  /// No description provided for @pasting.
  ///
  /// In en, this message translates to:
  /// **'Pasting...'**
  String get pasting;

  /// No description provided for @duplicating.
  ///
  /// In en, this message translates to:
  /// **'Duplicating...'**
  String get duplicating;

  /// No description provided for @moving.
  ///
  /// In en, this message translates to:
  /// **'Moving...'**
  String get moving;

  /// No description provided for @moveProgress.
  ///
  /// In en, this message translates to:
  /// **'Move: {name} ({percent}%)'**
  String moveProgress(String name, int percent);

  /// No description provided for @pasteProgress.
  ///
  /// In en, this message translates to:
  /// **'Paste: {name} ({percent}%)'**
  String pasteProgress(String name, int percent);

  /// No description provided for @duplicateProgress.
  ///
  /// In en, this message translates to:
  /// **'Duplicate: {name} ({percent}%)'**
  String duplicateProgress(String name, int percent);

  /// No description provided for @deleteProgress.
  ///
  /// In en, this message translates to:
  /// **'Delete: {name} ({percent}%)'**
  String deleteProgress(String name, int percent);

  /// No description provided for @zipProgress.
  ///
  /// In en, this message translates to:
  /// **'Compress: {name} ({percent}%)'**
  String zipProgress(String name, int percent);

  /// No description provided for @unzipProgress.
  ///
  /// In en, this message translates to:
  /// **'Extract: {name} ({percent}%)'**
  String unzipProgress(String name, int percent);

  /// No description provided for @openFileProgress.
  ///
  /// In en, this message translates to:
  /// **'Opening {name}...'**
  String openFileProgress(String name);

  /// No description provided for @ready.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get ready;

  /// No description provided for @notSaved.
  ///
  /// In en, this message translates to:
  /// **'Unsaved'**
  String get notSaved;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @deleteStopped.
  ///
  /// In en, this message translates to:
  /// **'Delete stopped'**
  String get deleteStopped;

  /// No description provided for @exitAppTitle.
  ///
  /// In en, this message translates to:
  /// **'Exit app'**
  String get exitAppTitle;

  /// No description provided for @exitAppBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to exit Cope X Studio?'**
  String get exitAppBody;

  /// No description provided for @exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// No description provided for @webServer.
  ///
  /// In en, this message translates to:
  /// **'Web Server'**
  String get webServer;

  /// No description provided for @shareViaWifi.
  ///
  /// In en, this message translates to:
  /// **'Share files over Wi‑Fi. Other devices can open the address or scan the QR code.'**
  String get shareViaWifi;

  /// No description provided for @sharedFolder.
  ///
  /// In en, this message translates to:
  /// **'Shared folder'**
  String get sharedFolder;

  /// No description provided for @pickFolder.
  ///
  /// In en, this message translates to:
  /// **'Choose folder'**
  String get pickFolder;

  /// No description provided for @entireStorage.
  ///
  /// In en, this message translates to:
  /// **'Entire device storage'**
  String get entireStorage;

  /// No description provided for @useAppLockPassword.
  ///
  /// In en, this message translates to:
  /// **'Use app lock password'**
  String get useAppLockPassword;

  /// No description provided for @httpBasicAuthHint.
  ///
  /// In en, this message translates to:
  /// **'HTTP Basic Auth — any username'**
  String get httpBasicAuthHint;

  /// No description provided for @webServerPassword.
  ///
  /// In en, this message translates to:
  /// **'Web Server password'**
  String get webServerPassword;

  /// No description provided for @webServerPasswordSet.
  ///
  /// In en, this message translates to:
  /// **'Set — tap to change'**
  String get webServerPasswordSet;

  /// No description provided for @webServerPasswordUnset.
  ///
  /// In en, this message translates to:
  /// **'Not set — anyone on the network can access'**
  String get webServerPasswordUnset;

  /// No description provided for @serverRunning.
  ///
  /// In en, this message translates to:
  /// **'Running — port {port}'**
  String serverRunning(int port);

  /// No description provided for @startServer.
  ///
  /// In en, this message translates to:
  /// **'Start server'**
  String get startServer;

  /// No description provided for @onlyFolder.
  ///
  /// In en, this message translates to:
  /// **'Only: {path}'**
  String onlyFolder(String path);

  /// No description provided for @addressCopied.
  ///
  /// In en, this message translates to:
  /// **'Address copied'**
  String get addressCopied;

  /// No description provided for @changeWebServerPassword.
  ///
  /// In en, this message translates to:
  /// **'Change Web Server password'**
  String get changeWebServerPassword;

  /// No description provided for @setWebServerPassword.
  ///
  /// In en, this message translates to:
  /// **'Set Web Server password'**
  String get setWebServerPassword;

  /// No description provided for @removeWebServerPassword.
  ///
  /// In en, this message translates to:
  /// **'Remove password'**
  String get removeWebServerPassword;

  /// No description provided for @consoleLog.
  ///
  /// In en, this message translates to:
  /// **'Console Log'**
  String get consoleLog;

  /// No description provided for @clearLog.
  ///
  /// In en, this message translates to:
  /// **'Clear log'**
  String get clearLog;

  /// No description provided for @noLogsYet.
  ///
  /// In en, this message translates to:
  /// **'No logs yet'**
  String get noLogsYet;

  /// No description provided for @newBrowserTab.
  ///
  /// In en, this message translates to:
  /// **'New file browser tab'**
  String get newBrowserTab;

  /// No description provided for @pickSharedFolder.
  ///
  /// In en, this message translates to:
  /// **'Choose shared folder'**
  String get pickSharedFolder;

  /// No description provided for @cannotReadFolder.
  ///
  /// In en, this message translates to:
  /// **'Cannot read folder'**
  String get cannotReadFolder;

  /// No description provided for @noSubfolders.
  ///
  /// In en, this message translates to:
  /// **'No subfolders'**
  String get noSubfolders;

  /// No description provided for @selectThisFolder.
  ///
  /// In en, this message translates to:
  /// **'Select this folder'**
  String get selectThisFolder;

  /// No description provided for @enterPasswordUnlock.
  ///
  /// In en, this message translates to:
  /// **'Enter password to unlock'**
  String get enterPasswordUnlock;

  /// No description provided for @wrongPasswordLock.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password'**
  String get wrongPasswordLock;

  /// No description provided for @biometrics.
  ///
  /// In en, this message translates to:
  /// **'Biometrics'**
  String get biometrics;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @loadingFile.
  ///
  /// In en, this message translates to:
  /// **'Loading file...'**
  String get loadingFile;

  /// No description provided for @cannotLoadFile.
  ///
  /// In en, this message translates to:
  /// **'Cannot load file'**
  String get cannotLoadFile;

  /// No description provided for @formatNotSupported.
  ///
  /// In en, this message translates to:
  /// **'Format not supported'**
  String get formatNotSupported;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @rewind10s.
  ///
  /// In en, this message translates to:
  /// **'Rewind 10s'**
  String get rewind10s;

  /// No description provided for @forward10s.
  ///
  /// In en, this message translates to:
  /// **'Forward 10s'**
  String get forward10s;

  /// No description provided for @playlist.
  ///
  /// In en, this message translates to:
  /// **'Playlist'**
  String get playlist;

  /// No description provided for @nowPlaying.
  ///
  /// In en, this message translates to:
  /// **'Now playing'**
  String get nowPlaying;

  /// No description provided for @exitFullscreen.
  ///
  /// In en, this message translates to:
  /// **'Exit fullscreen'**
  String get exitFullscreen;

  /// No description provided for @rotatePortrait.
  ///
  /// In en, this message translates to:
  /// **'Rotate portrait'**
  String get rotatePortrait;

  /// No description provided for @rotateLandscape.
  ///
  /// In en, this message translates to:
  /// **'Rotate landscape'**
  String get rotateLandscape;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @redo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get redo;

  /// No description provided for @findReplace.
  ///
  /// In en, this message translates to:
  /// **'Find & Replace'**
  String get findReplace;

  /// No description provided for @hideLineNumbers.
  ///
  /// In en, this message translates to:
  /// **'Hide line numbers'**
  String get hideLineNumbers;

  /// No description provided for @showLineNumbersToggle.
  ///
  /// In en, this message translates to:
  /// **'Show line numbers'**
  String get showLineNumbersToggle;

  /// No description provided for @disableWordWrap.
  ///
  /// In en, this message translates to:
  /// **'Disable word wrap'**
  String get disableWordWrap;

  /// No description provided for @enableWordWrap.
  ///
  /// In en, this message translates to:
  /// **'Enable word wrap'**
  String get enableWordWrap;

  /// No description provided for @decreaseFontSize.
  ///
  /// In en, this message translates to:
  /// **'Decrease font size'**
  String get decreaseFontSize;

  /// No description provided for @increaseFontSize.
  ///
  /// In en, this message translates to:
  /// **'Increase font size'**
  String get increaseFontSize;

  /// No description provided for @notFound.
  ///
  /// In en, this message translates to:
  /// **'Not found'**
  String get notFound;

  /// No description provided for @findHint.
  ///
  /// In en, this message translates to:
  /// **'Find...'**
  String get findHint;

  /// No description provided for @replaceHint.
  ///
  /// In en, this message translates to:
  /// **'Replace...'**
  String get replaceHint;

  /// No description provided for @replace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get replace;

  /// No description provided for @replaceAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get replaceAll;

  /// No description provided for @backToBrowser.
  ///
  /// In en, this message translates to:
  /// **'Back to file browser'**
  String get backToBrowser;

  /// No description provided for @createBrowserTab.
  ///
  /// In en, this message translates to:
  /// **'New file browser tab'**
  String get createBrowserTab;

  /// No description provided for @propertyDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get propertyDetails;

  /// No description provided for @loadingProperties.
  ///
  /// In en, this message translates to:
  /// **'Loading info...'**
  String get loadingProperties;

  /// No description provided for @cannotReadProperties.
  ///
  /// In en, this message translates to:
  /// **'Cannot read info: {error}'**
  String cannotReadProperties(String error);

  /// No description provided for @propertyName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get propertyName;

  /// No description provided for @propertyType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get propertyType;

  /// No description provided for @propertyLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get propertyLocation;

  /// No description provided for @propertyItemCount.
  ///
  /// In en, this message translates to:
  /// **'Item count'**
  String get propertyItemCount;

  /// No description provided for @propertySize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get propertySize;

  /// No description provided for @propertyFiles.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get propertyFiles;

  /// No description provided for @propertySubfolders.
  ///
  /// In en, this message translates to:
  /// **'Subfolders'**
  String get propertySubfolders;

  /// No description provided for @propertyModified.
  ///
  /// In en, this message translates to:
  /// **'Modified'**
  String get propertyModified;

  /// No description provided for @propertyAccessed.
  ///
  /// In en, this message translates to:
  /// **'Accessed'**
  String get propertyAccessed;

  /// No description provided for @propertyNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get propertyNotes;

  /// No description provided for @propertyResolution.
  ///
  /// In en, this message translates to:
  /// **'Resolution'**
  String get propertyResolution;

  /// No description provided for @propertyDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get propertyDuration;

  /// No description provided for @propertyCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get propertyCamera;

  /// No description provided for @propertyCapturedAt.
  ///
  /// In en, this message translates to:
  /// **'Captured at'**
  String get propertyCapturedAt;

  /// No description provided for @propertyDateModified.
  ///
  /// In en, this message translates to:
  /// **'Date modified'**
  String get propertyDateModified;

  /// No description provided for @propertyOrientation.
  ///
  /// In en, this message translates to:
  /// **'Orientation'**
  String get propertyOrientation;

  /// No description provided for @propertyTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get propertyTitle;

  /// No description provided for @propertyArtist.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get propertyArtist;

  /// No description provided for @propertyGenre.
  ///
  /// In en, this message translates to:
  /// **'Genre'**
  String get propertyGenre;

  /// No description provided for @propertyYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get propertyYear;

  /// No description provided for @folderType.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get folderType;

  /// No description provided for @fileType.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get fileType;

  /// No description provided for @fileTypeExt.
  ///
  /// In en, this message translates to:
  /// **'File {ext}'**
  String fileTypeExt(String ext);

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @rootAccessDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get rootAccessDisabled;

  /// No description provided for @rootAccessNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get rootAccessNormal;

  /// No description provided for @rootAccessSuperuser.
  ///
  /// In en, this message translates to:
  /// **'Superuser'**
  String get rootAccessSuperuser;

  /// No description provided for @rootAccessSuperuserWritable.
  ///
  /// In en, this message translates to:
  /// **'Superuser + mount writable'**
  String get rootAccessSuperuserWritable;

  /// No description provided for @rootAccessDisabledDesc.
  ///
  /// In en, this message translates to:
  /// **'Root directories are not shown'**
  String get rootAccessDisabledDesc;

  /// No description provided for @rootAccessNormalDesc.
  ///
  /// In en, this message translates to:
  /// **'Show root directories normally, works on all devices'**
  String get rootAccessNormalDesc;

  /// No description provided for @rootAccessSuperuserDesc.
  ///
  /// In en, this message translates to:
  /// **'Access via superuser, works on rooted devices'**
  String get rootAccessSuperuserDesc;

  /// No description provided for @rootAccessSuperuserWritableDesc.
  ///
  /// In en, this message translates to:
  /// **'Superuser mode allowing writes to read-only directories'**
  String get rootAccessSuperuserWritableDesc;

  /// No description provided for @openWithDone.
  ///
  /// In en, this message translates to:
  /// **'Opened with installer'**
  String get openWithDone;

  /// No description provided for @openWithNoApp.
  ///
  /// In en, this message translates to:
  /// **'No app found to open package'**
  String get openWithNoApp;

  /// No description provided for @openWithFileNotFound.
  ///
  /// In en, this message translates to:
  /// **'File does not exist'**
  String get openWithFileNotFound;

  /// No description provided for @openWithPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'No permission to open file'**
  String get openWithPermissionDenied;

  /// No description provided for @openWithError.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String openWithError(String message);

  /// No description provided for @operationCancelled.
  ///
  /// In en, this message translates to:
  /// **'Operation cancelled'**
  String get operationCancelled;

  /// No description provided for @storageFreeSlash.
  ///
  /// In en, this message translates to:
  /// **'{free}/{total} free'**
  String storageFreeSlash(String free, String total);

  /// No description provided for @treeLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading folder tree...'**
  String get treeLoading;

  /// No description provided for @webServerRunningNotification.
  ///
  /// In en, this message translates to:
  /// **'Web Server is running'**
  String get webServerRunningNotification;

  /// No description provided for @webServerNotificationChannel.
  ///
  /// In en, this message translates to:
  /// **'Notifications when Web Server is running'**
  String get webServerNotificationChannel;

  /// No description provided for @untitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get untitled;

  /// No description provided for @video.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get video;

  /// No description provided for @pdf.
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get pdf;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @output.
  ///
  /// In en, this message translates to:
  /// **'OUTPUT'**
  String get output;

  /// No description provided for @unzipping.
  ///
  /// In en, this message translates to:
  /// **'Extracting...'**
  String get unzipping;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a password'**
  String get passwordRequired;

  /// No description provided for @wrongPasswordOrCorrupt.
  ///
  /// In en, this message translates to:
  /// **'Wrong password or corrupt file'**
  String get wrongPasswordOrCorrupt;

  /// No description provided for @webDisk.
  ///
  /// In en, this message translates to:
  /// **'Disk'**
  String get webDisk;

  /// No description provided for @webGoUp.
  ///
  /// In en, this message translates to:
  /// **'Up'**
  String get webGoUp;

  /// No description provided for @webUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get webUpload;

  /// No description provided for @webDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get webDownload;

  /// No description provided for @webActions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get webActions;

  /// No description provided for @webRoot.
  ///
  /// In en, this message translates to:
  /// **'Root'**
  String get webRoot;

  /// No description provided for @webReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get webReady;

  /// No description provided for @webEditFile.
  ///
  /// In en, this message translates to:
  /// **'Edit file'**
  String get webEditFile;

  /// No description provided for @webViewFile.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get webViewFile;

  /// No description provided for @webNewFolderName.
  ///
  /// In en, this message translates to:
  /// **'New folder name'**
  String get webNewFolderName;

  /// No description provided for @webNewFileName.
  ///
  /// In en, this message translates to:
  /// **'New file name'**
  String get webNewFileName;

  /// No description provided for @webCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get webCreate;

  /// No description provided for @webEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get webEdit;

  /// No description provided for @webClearLogs.
  ///
  /// In en, this message translates to:
  /// **'Clear logs'**
  String get webClearLogs;

  /// No description provided for @webClosePanel.
  ///
  /// In en, this message translates to:
  /// **'Close panel'**
  String get webClosePanel;

  /// No description provided for @webItems.
  ///
  /// In en, this message translates to:
  /// **'items'**
  String get webItems;

  /// No description provided for @webLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get webLoading;

  /// No description provided for @webError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get webError;

  /// No description provided for @webUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get webUploading;

  /// No description provided for @webUploadSuccess.
  ///
  /// In en, this message translates to:
  /// **'Uploaded successfully'**
  String get webUploadSuccess;

  /// No description provided for @webUploadSuccessCount.
  ///
  /// In en, this message translates to:
  /// **'Uploaded {count} files successfully'**
  String webUploadSuccessCount(int count);

  /// No description provided for @webUploadError.
  ///
  /// In en, this message translates to:
  /// **'Upload error'**
  String get webUploadError;

  /// No description provided for @webNoSelectionDownload.
  ///
  /// In en, this message translates to:
  /// **'No items selected to download'**
  String get webNoSelectionDownload;

  /// No description provided for @webNoFilesDownload.
  ///
  /// In en, this message translates to:
  /// **'No files selected to download'**
  String get webNoFilesDownload;

  /// No description provided for @webDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get webDownloading;

  /// No description provided for @webZipAndDownload.
  ///
  /// In en, this message translates to:
  /// **'Zipping for download...'**
  String get webZipAndDownload;

  /// No description provided for @webZipSuccessDownload.
  ///
  /// In en, this message translates to:
  /// **'Zipped successfully. Downloading...'**
  String get webZipSuccessDownload;

  /// No description provided for @webZipError.
  ///
  /// In en, this message translates to:
  /// **'Zip error'**
  String get webZipError;

  /// No description provided for @webSelectedAll.
  ///
  /// In en, this message translates to:
  /// **'Selected all'**
  String get webSelectedAll;

  /// No description provided for @webSelectedAllCount.
  ///
  /// In en, this message translates to:
  /// **'Selected all {count} items'**
  String webSelectedAllCount(int count);

  /// No description provided for @webDeselectedAll.
  ///
  /// In en, this message translates to:
  /// **'Deselected all'**
  String get webDeselectedAll;

  /// No description provided for @webSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Saved successfully'**
  String get webSavedSuccess;

  /// No description provided for @webSelectOneRename.
  ///
  /// In en, this message translates to:
  /// **'Select 1 item to rename'**
  String get webSelectOneRename;

  /// No description provided for @webNoSelection.
  ///
  /// In en, this message translates to:
  /// **'No items selected'**
  String get webNoSelection;

  /// No description provided for @webDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} items?'**
  String webDeleteConfirm(int count);

  /// No description provided for @webZipSuccess.
  ///
  /// In en, this message translates to:
  /// **'Zipped successfully'**
  String get webZipSuccess;

  /// No description provided for @webZipSuccessDownloading.
  ///
  /// In en, this message translates to:
  /// **'Zipped successfully: {name}. Downloading...'**
  String webZipSuccessDownloading(String name);

  /// No description provided for @webUnzipSuccess.
  ///
  /// In en, this message translates to:
  /// **'Extracted successfully'**
  String get webUnzipSuccess;

  /// No description provided for @webGridView.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get webGridView;

  /// No description provided for @webListView.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get webListView;

  /// No description provided for @logUnlockZip.
  ///
  /// In en, this message translates to:
  /// **'Unlocked ZIP: {name}'**
  String logUnlockZip(String name);

  /// No description provided for @logUnlockError.
  ///
  /// In en, this message translates to:
  /// **'Unlock error: {error}'**
  String logUnlockError(String error);

  /// No description provided for @logEnableManageStorage.
  ///
  /// In en, this message translates to:
  /// **'Enable All files access in Settings'**
  String get logEnableManageStorage;

  /// No description provided for @logGrantedAllFilesAccess.
  ///
  /// In en, this message translates to:
  /// **'All-files access granted'**
  String get logGrantedAllFilesAccess;

  /// No description provided for @logEnableManageAllFiles.
  ///
  /// In en, this message translates to:
  /// **'Enable manage all files access in Settings'**
  String get logEnableManageAllFiles;

  /// No description provided for @logNewTab.
  ///
  /// In en, this message translates to:
  /// **'New tab: {name}'**
  String logNewTab(String name);

  /// No description provided for @logFileLocation.
  ///
  /// In en, this message translates to:
  /// **'Location: {path}'**
  String logFileLocation(String path);

  /// No description provided for @logViewZip.
  ///
  /// In en, this message translates to:
  /// **'View ZIP: {name}'**
  String logViewZip(String name);

  /// No description provided for @logRecentAdded.
  ///
  /// In en, this message translates to:
  /// **'Added {count} recent files'**
  String logRecentAdded(int count);

  /// No description provided for @logRecentScanned.
  ///
  /// In en, this message translates to:
  /// **'Scanned {count} recent files'**
  String logRecentScanned(int count);

  /// No description provided for @logRecentScanError.
  ///
  /// In en, this message translates to:
  /// **'Recent scan error: {error}'**
  String logRecentScanError(String error);

  /// No description provided for @logAppsAdded.
  ///
  /// In en, this message translates to:
  /// **'Added {count} apps ({type})'**
  String logAppsAdded(int count, String type);

  /// No description provided for @logAppsLoaded.
  ///
  /// In en, this message translates to:
  /// **'Loaded {count} apps'**
  String logAppsLoaded(int count);

  /// No description provided for @logAppsLoadError.
  ///
  /// In en, this message translates to:
  /// **'App load error: {error}'**
  String logAppsLoadError(String error);

  /// No description provided for @logAppsTypeSystem.
  ///
  /// In en, this message translates to:
  /// **'system'**
  String get logAppsTypeSystem;

  /// No description provided for @logAppsTypeUser.
  ///
  /// In en, this message translates to:
  /// **'user'**
  String get logAppsTypeUser;

  /// No description provided for @logReadItemsRoot.
  ///
  /// In en, this message translates to:
  /// **'Read {count} items at Root'**
  String logReadItemsRoot(int count);

  /// No description provided for @logReadItemsAt.
  ///
  /// In en, this message translates to:
  /// **'Read {count} items at {location}'**
  String logReadItemsAt(int count, String location);

  /// No description provided for @logReadError.
  ///
  /// In en, this message translates to:
  /// **'Read error {location}: {error}'**
  String logReadError(String location, String error);

  /// No description provided for @logOpenAppInfo.
  ///
  /// In en, this message translates to:
  /// **'Opening app info'**
  String get logOpenAppInfo;

  /// No description provided for @logOpenAppInfoError.
  ///
  /// In en, this message translates to:
  /// **'App info error: {error}'**
  String logOpenAppInfoError(String error);

  /// No description provided for @logApkCopied.
  ///
  /// In en, this message translates to:
  /// **'APK copied: {name}'**
  String logApkCopied(String name);

  /// No description provided for @logApkCopyError.
  ///
  /// In en, this message translates to:
  /// **'APK copy error: {error}'**
  String logApkCopyError(String error);

  /// No description provided for @logApkShared.
  ///
  /// In en, this message translates to:
  /// **'APK shared: {name}'**
  String logApkShared(String name);

  /// No description provided for @logApkShareError.
  ///
  /// In en, this message translates to:
  /// **'APK share error: {error}'**
  String logApkShareError(String error);

  /// No description provided for @logPlayStoreError.
  ///
  /// In en, this message translates to:
  /// **'Play Store error: {error}'**
  String logPlayStoreError(String error);

  /// No description provided for @logApkBackup.
  ///
  /// In en, this message translates to:
  /// **'APK backed up → {path}'**
  String logApkBackup(String path);

  /// No description provided for @logApkBackupError.
  ///
  /// In en, this message translates to:
  /// **'APK backup error: {error}'**
  String logApkBackupError(String error);

  /// No description provided for @logUninstall.
  ///
  /// In en, this message translates to:
  /// **'Uninstall: {name}'**
  String logUninstall(String name);

  /// No description provided for @logUninstallError.
  ///
  /// In en, this message translates to:
  /// **'Uninstall error: {error}'**
  String logUninstallError(String error);

  /// No description provided for @logLaunchApp.
  ///
  /// In en, this message translates to:
  /// **'Launch app: {package}'**
  String logLaunchApp(String package);

  /// No description provided for @logOpenAppError.
  ///
  /// In en, this message translates to:
  /// **'Open app error: {error}'**
  String logOpenAppError(String error);

  /// No description provided for @logHomeLoadError.
  ///
  /// In en, this message translates to:
  /// **'Home load error: {error}'**
  String logHomeLoadError(String error);

  /// No description provided for @logFtpError.
  ///
  /// In en, this message translates to:
  /// **'FTP error: {error}'**
  String logFtpError(String error);

  /// No description provided for @logZipReadError.
  ///
  /// In en, this message translates to:
  /// **'ZIP read error: {error}'**
  String logZipReadError(String error);

  /// No description provided for @logFileOpened.
  ///
  /// In en, this message translates to:
  /// **'Opened {name}'**
  String logFileOpened(String name);

  /// No description provided for @logFormatNotSupportedOpen.
  ///
  /// In en, this message translates to:
  /// **'Format {format} is not supported.'**
  String logFormatNotSupportedOpen(String format);

  /// No description provided for @logFtpFileLoadError.
  ///
  /// In en, this message translates to:
  /// **'FTP file load error: {error}'**
  String logFtpFileLoadError(String error);

  /// No description provided for @logCreateFile.
  ///
  /// In en, this message translates to:
  /// **'Created file: {name}'**
  String logCreateFile(String name);

  /// No description provided for @logCreateFolder.
  ///
  /// In en, this message translates to:
  /// **'Created folder: {name}'**
  String logCreateFolder(String name);

  /// No description provided for @logCopiedItems.
  ///
  /// In en, this message translates to:
  /// **'Copied {count} items'**
  String logCopiedItems(int count);

  /// No description provided for @logCutItems.
  ///
  /// In en, this message translates to:
  /// **'Cut {count} items'**
  String logCutItems(int count);

  /// No description provided for @logCannotPasteInZip.
  ///
  /// In en, this message translates to:
  /// **'Cannot paste inside ZIP'**
  String get logCannotPasteInZip;

  /// No description provided for @logPasteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Paste successful'**
  String get logPasteSuccess;

  /// No description provided for @logPasteError.
  ///
  /// In en, this message translates to:
  /// **'Paste error: {error}'**
  String logPasteError(String error);

  /// No description provided for @logDuplicateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Duplicated {count} items'**
  String logDuplicateSuccess(int count);

  /// No description provided for @logDuplicateError.
  ///
  /// In en, this message translates to:
  /// **'Duplicate error: {error}'**
  String logDuplicateError(String error);

  /// No description provided for @logDeletePartialNotice.
  ///
  /// In en, this message translates to:
  /// **'Deleted items cannot be restored. Remaining items were not deleted.'**
  String get logDeletePartialNotice;

  /// No description provided for @logMovedToTrash.
  ///
  /// In en, this message translates to:
  /// **'Moved {count} items to trash'**
  String logMovedToTrash(int count);

  /// No description provided for @logDeletedItems.
  ///
  /// In en, this message translates to:
  /// **'Deleted {count} items'**
  String logDeletedItems(int count);

  /// No description provided for @logDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Delete error: {error}'**
  String logDeleteError(String error);

  /// No description provided for @logRenamedTo.
  ///
  /// In en, this message translates to:
  /// **'Renamed to {name}'**
  String logRenamedTo(String name);

  /// No description provided for @logZippedTo.
  ///
  /// In en, this message translates to:
  /// **'Compressed to {name}'**
  String logZippedTo(String name);

  /// No description provided for @logUnzipTo.
  ///
  /// In en, this message translates to:
  /// **'Extracted to {folder}'**
  String logUnzipTo(String folder);

  /// No description provided for @logUnzipError.
  ///
  /// In en, this message translates to:
  /// **'Extract error: {error}'**
  String logUnzipError(String error);

  /// No description provided for @logApkNotFound.
  ///
  /// In en, this message translates to:
  /// **'APK file not found'**
  String get logApkNotFound;

  /// No description provided for @logInstallApkError.
  ///
  /// In en, this message translates to:
  /// **'APK install error: {error}'**
  String logInstallApkError(String error);

  /// No description provided for @logOpeningFromZip.
  ///
  /// In en, this message translates to:
  /// **'Opening file from ZIP...'**
  String get logOpeningFromZip;

  /// No description provided for @logPrepareShareFromZip.
  ///
  /// In en, this message translates to:
  /// **'Preparing to share file from ZIP...'**
  String get logPrepareShareFromZip;

  /// No description provided for @logShareFileError.
  ///
  /// In en, this message translates to:
  /// **'Share file error: {error}'**
  String logShareFileError(String error);

  /// No description provided for @logFormatNotSupportedDirect.
  ///
  /// In en, this message translates to:
  /// **'Format {format} is not supported for direct extraction.'**
  String logFormatNotSupportedDirect(String format);

  /// No description provided for @logFileSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved {name}'**
  String logFileSaved(String name);

  /// No description provided for @logSaveError.
  ///
  /// In en, this message translates to:
  /// **'Save error: {error}'**
  String logSaveError(String error);

  /// No description provided for @logWebServerStarted.
  ///
  /// In en, this message translates to:
  /// **'Web server{auth}: {url}{scope}'**
  String logWebServerStarted(String auth, String url, String scope);

  /// No description provided for @logWebServerAuthWith.
  ///
  /// In en, this message translates to:
  /// **' (password)'**
  String get logWebServerAuthWith;

  /// No description provided for @logWebServerScopeFolder.
  ///
  /// In en, this message translates to:
  /// **' — folder: {path}'**
  String logWebServerScopeFolder(String path);

  /// No description provided for @logWebServerScopeAll.
  ///
  /// In en, this message translates to:
  /// **' — entire storage'**
  String get logWebServerScopeAll;

  /// No description provided for @logWebServerStartError.
  ///
  /// In en, this message translates to:
  /// **'Web server start error: {error}'**
  String logWebServerStartError(String error);

  /// No description provided for @logWebServerStopped.
  ///
  /// In en, this message translates to:
  /// **'Web server stopped'**
  String get logWebServerStopped;

  /// No description provided for @logZipError.
  ///
  /// In en, this message translates to:
  /// **'ZIP error: {error}'**
  String logZipError(String error);

  /// No description provided for @errCannotReadZipList.
  ///
  /// In en, this message translates to:
  /// **'Cannot read file list in ZIP'**
  String get errCannotReadZipList;

  /// No description provided for @errZipTooLargeVerifyPassword.
  ///
  /// In en, this message translates to:
  /// **'ZIP too large ({sizeMb} MB). Cannot verify password in memory.'**
  String errZipTooLargeVerifyPassword(String sizeMb);

  /// No description provided for @errZipAesTooLarge.
  ///
  /// In en, this message translates to:
  /// **'AES-encrypted ZIP too large ({sizeMb} MB). Limit {limitMb} MB.'**
  String errZipAesTooLarge(String sizeMb, String limitMb);

  /// No description provided for @errZipTooLargeNeedUnzip.
  ///
  /// In en, this message translates to:
  /// **'ZIP too large ({sizeMb} MB). unzip/7z command required on device.'**
  String errZipTooLargeNeedUnzip(String sizeMb);

  /// No description provided for @errFlutterArchiveUnavailable.
  ///
  /// In en, this message translates to:
  /// **'flutter_archive is not available on this platform'**
  String get errFlutterArchiveUnavailable;

  /// No description provided for @errCannotExtractZipEntry.
  ///
  /// In en, this message translates to:
  /// **'Cannot extract ZIP entry'**
  String get errCannotExtractZipEntry;

  /// No description provided for @errCannotExtractTar.
  ///
  /// In en, this message translates to:
  /// **'Cannot extract TAR'**
  String get errCannotExtractTar;

  /// No description provided for @errDataTooLargeCompress.
  ///
  /// In en, this message translates to:
  /// **'Data too large ({sizeMb} MB). Cannot compress in memory.'**
  String errDataTooLargeCompress(String sizeMb);

  /// No description provided for @errMultiFolderZipNoCommand.
  ///
  /// In en, this message translates to:
  /// **'Cannot compress multiple folders — zip command missing on device'**
  String get errMultiFolderZipNoCommand;

  /// No description provided for @errCannotCreateZip.
  ///
  /// In en, this message translates to:
  /// **'Cannot create ZIP file'**
  String get errCannotCreateZip;

  /// No description provided for @errParentDirNotFound.
  ///
  /// In en, this message translates to:
  /// **'Parent directory does not exist'**
  String get errParentDirNotFound;

  /// No description provided for @errCannotWriteDestDir.
  ///
  /// In en, this message translates to:
  /// **'Cannot write to destination directory'**
  String get errCannotWriteDestDir;

  /// No description provided for @errZipTooLargeExtract.
  ///
  /// In en, this message translates to:
  /// **'ZIP too large ({sizeMb} MB). Native extraction or unzip required.'**
  String errZipTooLargeExtract(String sizeMb);

  /// No description provided for @errZipTooLargeSingleEntry.
  ///
  /// In en, this message translates to:
  /// **'ZIP too large to extract a single entry in RAM'**
  String get errZipTooLargeSingleEntry;

  /// No description provided for @errZipEntryNotFound.
  ///
  /// In en, this message translates to:
  /// **'Entry not found in ZIP'**
  String get errZipEntryNotFound;

  /// No description provided for @errFileNotExists.
  ///
  /// In en, this message translates to:
  /// **'File does not exist'**
  String get errFileNotExists;

  /// No description provided for @errInvalidZip.
  ///
  /// In en, this message translates to:
  /// **'Invalid ZIP file'**
  String get errInvalidZip;

  /// No description provided for @errZipEocdNotFound.
  ///
  /// In en, this message translates to:
  /// **'End of Central Directory not found'**
  String get errZipEocdNotFound;

  /// No description provided for @errZipCdCorrupt.
  ///
  /// In en, this message translates to:
  /// **'ZIP Central Directory is corrupt'**
  String get errZipCdCorrupt;

  /// No description provided for @errZipCdTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Central Directory too large ({sizeMb} MB)'**
  String errZipCdTooLarge(String sizeMb);

  /// No description provided for @errZipCdIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Could not read full Central Directory'**
  String get errZipCdIncomplete;

  /// No description provided for @errZip64LocatorInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid ZIP64 locator'**
  String get errZip64LocatorInvalid;

  /// No description provided for @errZip64EocdInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid ZIP64 EOCD signature'**
  String get errZip64EocdInvalid;

  /// No description provided for @errZip64EocdOutOfFile.
  ///
  /// In en, this message translates to:
  /// **'ZIP64 EOCD is outside the file'**
  String get errZip64EocdOutOfFile;

  /// No description provided for @errDirectoryNotExists.
  ///
  /// In en, this message translates to:
  /// **'Directory does not exist'**
  String get errDirectoryNotExists;

  /// No description provided for @errCannotAccessPath.
  ///
  /// In en, this message translates to:
  /// **'Cannot access {path}: {message}'**
  String errCannotAccessPath(String path, String message);

  /// No description provided for @errAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'Already exists'**
  String get errAlreadyExists;

  /// No description provided for @errShellListingAndroidOnly.
  ///
  /// In en, this message translates to:
  /// **'Shell listing is only supported on Android'**
  String get errShellListingAndroidOnly;

  /// No description provided for @errSuperuserAndroidOnly.
  ///
  /// In en, this message translates to:
  /// **'Superuser mode is only supported on Android'**
  String get errSuperuserAndroidOnly;

  /// No description provided for @errCannotCheckSuperuser.
  ///
  /// In en, this message translates to:
  /// **'Cannot check superuser access'**
  String get errCannotCheckSuperuser;

  /// No description provided for @errSuperuserCheckTimeout.
  ///
  /// In en, this message translates to:
  /// **'Superuser check timed out. Device may not be rooted or access not granted.'**
  String get errSuperuserCheckTimeout;

  /// No description provided for @errInstallApkAndroidOnly.
  ///
  /// In en, this message translates to:
  /// **'APK install is only supported on Android'**
  String get errInstallApkAndroidOnly;

  /// No description provided for @errApkNotFound.
  ///
  /// In en, this message translates to:
  /// **'APK not found'**
  String get errApkNotFound;

  /// No description provided for @errApkBackupFailed.
  ///
  /// In en, this message translates to:
  /// **'Backup failed'**
  String get errApkBackupFailed;

  /// No description provided for @errNoWebServerPassword.
  ///
  /// In en, this message translates to:
  /// **'No Web Server password set'**
  String get errNoWebServerPassword;

  /// No description provided for @errNoPassword.
  ///
  /// In en, this message translates to:
  /// **'No password set'**
  String get errNoPassword;

  /// No description provided for @errCurrentPasswordWrong.
  ///
  /// In en, this message translates to:
  /// **'Current password is incorrect'**
  String get errCurrentPasswordWrong;

  /// No description provided for @errBiometricUnlockReason.
  ///
  /// In en, this message translates to:
  /// **'Unlock Cope X Studio'**
  String get errBiometricUnlockReason;

  /// No description provided for @errCannotTestPasswordOnPlatform.
  ///
  /// In en, this message translates to:
  /// **'Cannot verify password on this platform'**
  String get errCannotTestPasswordOnPlatform;

  /// No description provided for @errShellUnsupportedZipEncryption.
  ///
  /// In en, this message translates to:
  /// **'Shell does not support this ZIP encryption format'**
  String get errShellUnsupportedZipEncryption;

  /// No description provided for @errCannotRunUnzip.
  ///
  /// In en, this message translates to:
  /// **'Cannot run unzip command'**
  String get errCannotRunUnzip;

  /// No description provided for @err7zNotFound.
  ///
  /// In en, this message translates to:
  /// **'7z command not found'**
  String get err7zNotFound;

  /// No description provided for @errEmptyZipSources.
  ///
  /// In en, this message translates to:
  /// **'Empty source list for compression'**
  String get errEmptyZipSources;

  /// No description provided for @errCannotRunZip.
  ///
  /// In en, this message translates to:
  /// **'Cannot run zip command'**
  String get errCannotRunZip;

  /// No description provided for @errPasswordNeeded.
  ///
  /// In en, this message translates to:
  /// **'Password required'**
  String get errPasswordNeeded;

  /// No description provided for @apiPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password required'**
  String get apiPasswordRequired;

  /// No description provided for @apiWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Wrong password'**
  String get apiWrongPassword;

  /// No description provided for @apiCannotListFolder.
  ///
  /// In en, this message translates to:
  /// **'Cannot list folder'**
  String get apiCannotListFolder;

  /// No description provided for @apiFileNotFound.
  ///
  /// In en, this message translates to:
  /// **'File not found'**
  String get apiFileNotFound;

  /// No description provided for @apiCannotFolderThumbnail.
  ///
  /// In en, this message translates to:
  /// **'Cannot get folder thumbnail'**
  String get apiCannotFolderThumbnail;

  /// No description provided for @apiCannotReadFolder.
  ///
  /// In en, this message translates to:
  /// **'Cannot read folder'**
  String get apiCannotReadFolder;

  /// No description provided for @apiFileTooLargeEdit.
  ///
  /// In en, this message translates to:
  /// **'File too large to edit (>2MB)'**
  String get apiFileTooLargeEdit;

  /// No description provided for @apiMissingFolderName.
  ///
  /// In en, this message translates to:
  /// **'Missing folder name'**
  String get apiMissingFolderName;

  /// No description provided for @apiMissingFileName.
  ///
  /// In en, this message translates to:
  /// **'Missing file name'**
  String get apiMissingFileName;

  /// No description provided for @apiMissingNewName.
  ///
  /// In en, this message translates to:
  /// **'Missing new name'**
  String get apiMissingNewName;

  /// No description provided for @apiNothingToDelete.
  ///
  /// In en, this message translates to:
  /// **'Nothing to delete'**
  String get apiNothingToDelete;

  /// No description provided for @apiCannotWriteFolder.
  ///
  /// In en, this message translates to:
  /// **'Cannot write folder'**
  String get apiCannotWriteFolder;

  /// No description provided for @apiNothingToZip.
  ///
  /// In en, this message translates to:
  /// **'Nothing to compress'**
  String get apiNothingToZip;

  /// No description provided for @apiNotZipFile.
  ///
  /// In en, this message translates to:
  /// **'Not a ZIP file'**
  String get apiNotZipFile;

  /// No description provided for @apiInvalidDestFolder.
  ///
  /// In en, this message translates to:
  /// **'Invalid destination folder'**
  String get apiInvalidDestFolder;

  /// No description provided for @apiMissingFileNameParam.
  ///
  /// In en, this message translates to:
  /// **'Missing file name (name parameter)'**
  String get apiMissingFileNameParam;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Cope X Studio'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Browse files, edit code, and manage archives — all in one place.'**
  String get welcomeSubtitle;

  /// No description provided for @welcomeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get welcomeLanguage;

  /// No description provided for @welcomeTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get welcomeTheme;

  /// No description provided for @welcomeNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get welcomeNext;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get welcomeBack;

  /// No description provided for @welcomeGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get welcomeGetStarted;

  /// No description provided for @welcomePermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Storage access'**
  String get welcomePermissionTitle;

  /// No description provided for @welcomePermissionBody.
  ///
  /// In en, this message translates to:
  /// **'Allow all-files access so Cope X Studio can browse and manage files across your device.'**
  String get welcomePermissionBody;

  /// No description provided for @welcomeGrantPermission.
  ///
  /// In en, this message translates to:
  /// **'Grant access'**
  String get welcomeGrantPermission;

  /// No description provided for @welcomeSkipPermission.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get welcomeSkipPermission;

  /// No description provided for @welcomePermissionGranted.
  ///
  /// In en, this message translates to:
  /// **'Access granted'**
  String get welcomePermissionGranted;

  /// No description provided for @welcomePermissionNotNeeded.
  ///
  /// In en, this message translates to:
  /// **'No extra permission is required on this device.'**
  String get welcomePermissionNotNeeded;

  /// No description provided for @welcomePermissionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get welcomePermissionsTitle;

  /// No description provided for @welcomePermissionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Cope X Studio needs a few permissions to work properly.'**
  String get welcomePermissionsSubtitle;

  /// No description provided for @welcomeNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get welcomeNotificationTitle;

  /// No description provided for @welcomeNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'Show status for Web Server, media playback, and background tasks.'**
  String get welcomeNotificationBody;

  /// No description provided for @welcomeGrantNotification.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications'**
  String get welcomeGrantNotification;

  /// No description provided for @welcomeNotificationGranted.
  ///
  /// In en, this message translates to:
  /// **'Notifications allowed'**
  String get welcomeNotificationGranted;

  /// No description provided for @welcomeStorageRequiredHint.
  ///
  /// In en, this message translates to:
  /// **'Grant storage access to continue.'**
  String get welcomeStorageRequiredHint;

  /// No description provided for @welcomeStep.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String welcomeStep(int current, int total);

  /// No description provided for @welcomeDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re all set!'**
  String get welcomeDoneTitle;

  /// No description provided for @welcomeDoneBody.
  ///
  /// In en, this message translates to:
  /// **'Everything is ready. Start exploring your files.'**
  String get welcomeDoneBody;
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
