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

  @override
  String get add => 'Add';

  @override
  String get copy => 'Copy';

  @override
  String get cut => 'Cut';

  @override
  String get paste => 'Paste';

  @override
  String get share => 'Share';

  @override
  String get refresh => 'Refresh';

  @override
  String get parentFolder => 'Parent folder';

  @override
  String get extract => 'Extract';

  @override
  String get searchInFolder => 'Search in folder...';

  @override
  String get hideHiddenFilesToggle => 'Hide hidden files';

  @override
  String get showHiddenFilesToggle => 'Show hidden files';

  @override
  String get pleaseWait => 'Please wait...';

  @override
  String get understood => 'Got it';

  @override
  String get grantPermission => 'Grant permission';

  @override
  String get storagePermissionTitle => 'All-files access required';

  @override
  String get storagePermissionBody => 'Enable MANAGE_EXTERNAL_STORAGE to browse all storage.';

  @override
  String get newFile => 'New file';

  @override
  String get newFolder => 'New folder';

  @override
  String selectedCount(int count) {
    return '$count selected';
  }

  @override
  String get duplicate => 'Duplicate';

  @override
  String get installApk => 'Install APK';

  @override
  String get openAs => 'Open as';

  @override
  String get openWithSystem => 'Open with another app';

  @override
  String get openInNewTab => 'Open in new tab';

  @override
  String get revealLocation => 'Show file location';

  @override
  String get details => 'Details';

  @override
  String get openApp => 'Open app';

  @override
  String get appInfo => 'App info';

  @override
  String get copyApk => 'Copy APK';

  @override
  String get shareApk => 'Share APK';

  @override
  String get viewPlayStore => 'View on Play Store';

  @override
  String get backupApk => 'Backup APK (Extract)';

  @override
  String get uninstall => 'Uninstall';

  @override
  String get openAsText => 'Text';

  @override
  String get openAsImage => 'Image';

  @override
  String get openAsAudio => 'Audio';

  @override
  String get openAsVideo => 'Video';

  @override
  String get openAsArchive => 'Archive';

  @override
  String get viewModeList => 'List';

  @override
  String get viewModeGrid => 'Grid';

  @override
  String get viewModeTree => 'Folder tree';

  @override
  String get emptyFolder => 'Folder is empty';

  @override
  String get emptyZip => 'ZIP is empty';

  @override
  String get noApps => 'No apps';

  @override
  String get noRecentFiles => 'No recent files';

  @override
  String get noSearchResults => 'No results found';

  @override
  String get loadingFtp => 'Loading FTP folder...';

  @override
  String get loadingZip => 'Reading ZIP contents...';

  @override
  String get loadingDirectory => 'Reading folder...';

  @override
  String get loadingApps => 'Loading app list...';

  @override
  String get scanningStorage => 'Scanning storage...';

  @override
  String get scanningRecent => 'Scanning recent files...';

  @override
  String get extractingAndOpening => 'Extracting and opening file...';

  @override
  String get ftpConnectionError => 'FTP connection error';

  @override
  String get cannotReadDirectory => 'Cannot read folder';

  @override
  String cannotReadPath(String name) {
    return 'Cannot read $name';
  }

  @override
  String get cannotLoadApps => 'Cannot load apps';

  @override
  String pathCopied(String path) {
    return 'Path copied: $path';
  }

  @override
  String get noFilesToZip => 'No files to compress';

  @override
  String formatNotSupportedExtract(String format) {
    return 'Format $format is not supported for extraction.';
  }

  @override
  String get zipPasswordExtractTitle => 'Extract password-protected ZIP';

  @override
  String get zipFileTitle => 'Compress to ZIP';

  @override
  String get fileName => 'File name';

  @override
  String get passwordProtect => 'Password protect';

  @override
  String get compress => 'Compress';

  @override
  String get passwordOptional => 'Password (optional)';

  @override
  String get wrongPasswordRetry => 'Wrong password. Please try again.';

  @override
  String get zipPasswordProtected => 'Archive is password protected.';

  @override
  String get unlock => 'Unlock';

  @override
  String get editFtpConfig => 'Edit configuration';

  @override
  String get deleteFtpServer => 'Delete server configuration';

  @override
  String get editFtpServer => 'Edit FTP server';

  @override
  String get addFtpServer => 'Add FTP server';

  @override
  String get displayName => 'Display name';

  @override
  String get hostAddress => 'IP address / Host';

  @override
  String get port => 'Port (Port)';

  @override
  String get username => 'Username';

  @override
  String itemCount(int count) {
    return '$count items';
  }

  @override
  String get zipCurrentFolder => 'Compress current folder';

  @override
  String get zipRecentFiles => 'Compress recent files';

  @override
  String get zipCopiedItems => 'Compress copied items';

  @override
  String get deselectAll => 'Deselect all';

  @override
  String get select => 'Select';

  @override
  String get selectAll => 'Select all';

  @override
  String get move => 'Move';

  @override
  String get shortcutHome => 'Home';

  @override
  String get shortcutRecent => 'Recent files';

  @override
  String get shortcutAllImages => 'All images';

  @override
  String get shortcutAllImagesSubtitle => 'Browse all images on device';

  @override
  String get shortcutFtp => 'FTP';

  @override
  String get shortcutPhotos => 'Photos';

  @override
  String get shortcutAddFtp => '+ Add server';

  @override
  String get deviceStorage => 'Device storage';

  @override
  String get systemApps => 'System';

  @override
  String get userApps => 'Settings';

  @override
  String get systemApp => 'System app';

  @override
  String get userApp => 'User-installed app';

  @override
  String get accessDenied => 'Access denied';

  @override
  String get superuserNotGranted => 'Superuser access not granted';

  @override
  String get superuserRevertedNormal => 'Superuser access not granted — reverted to Normal';

  @override
  String get wrongPassword => 'Wrong password';

  @override
  String get cancelUnzip => 'Extraction cancelled';

  @override
  String get cancelZip => 'Compression cancelled';

  @override
  String get cancelPaste => 'Paste cancelled';

  @override
  String get cancelDuplicate => 'Duplicate cancelled';

  @override
  String get cancelOperation => 'Operation cancelled';

  @override
  String get rollingBack => 'Rolling back...';

  @override
  String get zipping => 'Compressing...';

  @override
  String get deleting => 'Deleting...';

  @override
  String get pasting => 'Pasting...';

  @override
  String get duplicating => 'Duplicating...';

  @override
  String get moving => 'Moving...';

  @override
  String moveProgress(String name, int percent) {
    return 'Move: $name ($percent%)';
  }

  @override
  String pasteProgress(String name, int percent) {
    return 'Paste: $name ($percent%)';
  }

  @override
  String duplicateProgress(String name, int percent) {
    return 'Duplicate: $name ($percent%)';
  }

  @override
  String deleteProgress(String name, int percent) {
    return 'Delete: $name ($percent%)';
  }

  @override
  String zipProgress(String name, int percent) {
    return 'Compress: $name ($percent%)';
  }

  @override
  String unzipProgress(String name, int percent) {
    return 'Extract: $name ($percent%)';
  }

  @override
  String openFileProgress(String name) {
    return 'Opening $name...';
  }

  @override
  String get ready => 'Ready';

  @override
  String get notSaved => 'Unsaved';

  @override
  String get saved => 'Saved';

  @override
  String get deleteStopped => 'Delete stopped';

  @override
  String get exitAppTitle => 'Exit app';

  @override
  String get exitAppBody => 'Are you sure you want to exit Cope X Studio?';

  @override
  String get exit => 'Exit';

  @override
  String get webServer => 'Web Server';

  @override
  String get shareViaWifi => 'Share files over Wi‑Fi. Other devices can open the address or scan the QR code.';

  @override
  String get sharedFolder => 'Shared folder';

  @override
  String get pickFolder => 'Choose folder';

  @override
  String get entireStorage => 'Entire device storage';

  @override
  String get useAppLockPassword => 'Use app lock password';

  @override
  String get httpBasicAuthHint => 'HTTP Basic Auth — any username';

  @override
  String get webServerPassword => 'Web Server password';

  @override
  String get webServerPasswordSet => 'Set — tap to change';

  @override
  String get webServerPasswordUnset => 'Not set — anyone on the network can access';

  @override
  String serverRunning(int port) {
    return 'Running — port $port';
  }

  @override
  String get startServer => 'Start server';

  @override
  String onlyFolder(String path) {
    return 'Only: $path';
  }

  @override
  String get addressCopied => 'Address copied';

  @override
  String get changeWebServerPassword => 'Change Web Server password';

  @override
  String get setWebServerPassword => 'Set Web Server password';

  @override
  String get removeWebServerPassword => 'Remove password';

  @override
  String get consoleLog => 'Console Log';

  @override
  String get clearLog => 'Clear log';

  @override
  String get noLogsYet => 'No logs yet';

  @override
  String get newBrowserTab => 'New file browser tab';

  @override
  String get pickSharedFolder => 'Choose shared folder';

  @override
  String get cannotReadFolder => 'Cannot read folder';

  @override
  String get noSubfolders => 'No subfolders';

  @override
  String get selectThisFolder => 'Select this folder';

  @override
  String get enterPasswordUnlock => 'Enter password to unlock';

  @override
  String get wrongPasswordLock => 'Incorrect password';

  @override
  String get biometrics => 'Biometrics';

  @override
  String get loading => 'Loading...';

  @override
  String get loadingFile => 'Loading file...';

  @override
  String get cannotLoadFile => 'Cannot load file';

  @override
  String get formatNotSupported => 'Format not supported';

  @override
  String get previous => 'Previous';

  @override
  String get next => 'Next';

  @override
  String get rewind10s => 'Rewind 10s';

  @override
  String get forward10s => 'Forward 10s';

  @override
  String get playlist => 'Playlist';

  @override
  String get nowPlaying => 'Now playing';

  @override
  String get exitFullscreen => 'Exit fullscreen';

  @override
  String get rotatePortrait => 'Rotate portrait';

  @override
  String get rotateLandscape => 'Rotate landscape';

  @override
  String get undo => 'Undo';

  @override
  String get redo => 'Redo';

  @override
  String get findReplace => 'Find & Replace';

  @override
  String get hideLineNumbers => 'Hide line numbers';

  @override
  String get showLineNumbersToggle => 'Show line numbers';

  @override
  String get disableWordWrap => 'Disable word wrap';

  @override
  String get enableWordWrap => 'Enable word wrap';

  @override
  String get decreaseFontSize => 'Decrease font size';

  @override
  String get increaseFontSize => 'Increase font size';

  @override
  String get notFound => 'Not found';

  @override
  String get findHint => 'Find...';

  @override
  String get replaceHint => 'Replace...';

  @override
  String get replace => 'Replace';

  @override
  String get replaceAll => 'All';

  @override
  String get backToBrowser => 'Back to file browser';

  @override
  String get createBrowserTab => 'New file browser tab';

  @override
  String get propertyDetails => 'Details';

  @override
  String get loadingProperties => 'Loading info...';

  @override
  String cannotReadProperties(String error) {
    return 'Cannot read info: $error';
  }

  @override
  String get propertyName => 'Name';

  @override
  String get propertyType => 'Type';

  @override
  String get propertyLocation => 'Location';

  @override
  String get propertyItemCount => 'Item count';

  @override
  String get propertySize => 'Size';

  @override
  String get propertyFiles => 'Files';

  @override
  String get propertySubfolders => 'Subfolders';

  @override
  String get propertyModified => 'Modified';

  @override
  String get propertyAccessed => 'Accessed';

  @override
  String get propertyNotes => 'Notes';

  @override
  String get propertyResolution => 'Resolution';

  @override
  String get propertyDuration => 'Duration';

  @override
  String get propertyCamera => 'Camera';

  @override
  String get propertyCapturedAt => 'Captured at';

  @override
  String get propertyDateModified => 'Date modified';

  @override
  String get propertyOrientation => 'Orientation';

  @override
  String get propertyTitle => 'Title';

  @override
  String get propertyArtist => 'Artist';

  @override
  String get propertyGenre => 'Genre';

  @override
  String get propertyYear => 'Year';

  @override
  String get folderType => 'Folder';

  @override
  String get fileType => 'File';

  @override
  String fileTypeExt(String ext) {
    return 'File $ext';
  }

  @override
  String get themeDark => 'Dark';

  @override
  String get themeLight => 'Light';

  @override
  String get themeSystem => 'System';

  @override
  String get rootAccessDisabled => 'Disabled';

  @override
  String get rootAccessNormal => 'Normal';

  @override
  String get rootAccessSuperuser => 'Superuser';

  @override
  String get rootAccessSuperuserWritable => 'Superuser + mount writable';

  @override
  String get rootAccessDisabledDesc => 'Root directories are not shown';

  @override
  String get rootAccessNormalDesc => 'Show root directories normally, works on all devices';

  @override
  String get rootAccessSuperuserDesc => 'Access via superuser, works on rooted devices';

  @override
  String get rootAccessSuperuserWritableDesc => 'Superuser mode allowing writes to read-only directories';

  @override
  String get openWithDone => 'Opened with installer';

  @override
  String get openWithNoApp => 'No app found to open package';

  @override
  String get openWithFileNotFound => 'File does not exist';

  @override
  String get openWithPermissionDenied => 'No permission to open file';

  @override
  String openWithError(String message) {
    return 'Error: $message';
  }

  @override
  String get operationCancelled => 'Operation cancelled';

  @override
  String storageFreeSlash(String free, String total) {
    return '$free/$total free';
  }

  @override
  String get treeLoading => 'Loading folder tree...';

  @override
  String get webServerRunningNotification => 'Web Server is running';

  @override
  String get webServerNotificationChannel => 'Notifications when Web Server is running';

  @override
  String get untitled => 'Untitled';

  @override
  String get video => 'Video';

  @override
  String get pdf => 'PDF';

  @override
  String get online => 'Online';

  @override
  String get output => 'OUTPUT';

  @override
  String get unzipping => 'Extracting...';

  @override
  String get passwordRequired => 'Please enter a password';

  @override
  String get wrongPasswordOrCorrupt => 'Wrong password or corrupt file';

  @override
  String get webDisk => 'Disk';

  @override
  String get webGoUp => 'Up';

  @override
  String get webUpload => 'Upload';

  @override
  String get webDownload => 'Download';

  @override
  String get webActions => 'Actions';

  @override
  String get webRoot => 'Root';

  @override
  String get webReady => 'Ready';

  @override
  String get webEditFile => 'Edit file';

  @override
  String get webViewFile => 'View';

  @override
  String get webNewFolderName => 'New folder name';

  @override
  String get webNewFileName => 'New file name';

  @override
  String get webCreate => 'Create';

  @override
  String get webEdit => 'Edit';

  @override
  String get webClearLogs => 'Clear logs';

  @override
  String get webClosePanel => 'Close panel';

  @override
  String get webItems => 'items';

  @override
  String get webLoading => 'Loading...';

  @override
  String get webError => 'Error';

  @override
  String get webUploading => 'Uploading...';

  @override
  String get webUploadSuccess => 'Uploaded successfully';

  @override
  String webUploadSuccessCount(int count) {
    return 'Uploaded $count files successfully';
  }

  @override
  String get webUploadError => 'Upload error';

  @override
  String get webNoSelectionDownload => 'No items selected to download';

  @override
  String get webNoFilesDownload => 'No files selected to download';

  @override
  String get webDownloading => 'Downloading';

  @override
  String get webZipAndDownload => 'Zipping for download...';

  @override
  String get webZipSuccessDownload => 'Zipped successfully. Downloading...';

  @override
  String get webZipError => 'Zip error';

  @override
  String get webSelectedAll => 'Selected all';

  @override
  String webSelectedAllCount(int count) {
    return 'Selected all $count items';
  }

  @override
  String get webDeselectedAll => 'Deselected all';

  @override
  String get webSavedSuccess => 'Saved successfully';

  @override
  String get webSelectOneRename => 'Select 1 item to rename';

  @override
  String get webNoSelection => 'No items selected';

  @override
  String webDeleteConfirm(int count) {
    return 'Delete $count items?';
  }

  @override
  String get webZipSuccess => 'Zipped successfully';

  @override
  String webZipSuccessDownloading(String name) {
    return 'Zipped successfully: $name. Downloading...';
  }

  @override
  String get webUnzipSuccess => 'Extracted successfully';

  @override
  String get webGridView => 'Grid';

  @override
  String get webListView => 'List';

  @override
  String logUnlockZip(String name) {
    return 'Unlocked ZIP: $name';
  }

  @override
  String logUnlockError(String error) {
    return 'Unlock error: $error';
  }

  @override
  String get logEnableManageStorage => 'Enable All files access in Settings';

  @override
  String get logGrantedAllFilesAccess => 'All-files access granted';

  @override
  String get logEnableManageAllFiles => 'Enable manage all files access in Settings';

  @override
  String logNewTab(String name) {
    return 'New tab: $name';
  }

  @override
  String logFileLocation(String path) {
    return 'Location: $path';
  }

  @override
  String logViewZip(String name) {
    return 'View ZIP: $name';
  }

  @override
  String logRecentAdded(int count) {
    return 'Added $count recent files';
  }

  @override
  String logRecentScanned(int count) {
    return 'Scanned $count recent files';
  }

  @override
  String logRecentScanError(String error) {
    return 'Recent scan error: $error';
  }

  @override
  String logAppsAdded(int count, String type) {
    return 'Added $count apps ($type)';
  }

  @override
  String logAppsLoaded(int count) {
    return 'Loaded $count apps';
  }

  @override
  String logAppsLoadError(String error) {
    return 'App load error: $error';
  }

  @override
  String get logAppsTypeSystem => 'system';

  @override
  String get logAppsTypeUser => 'user';

  @override
  String logReadItemsRoot(int count) {
    return 'Read $count items at Root';
  }

  @override
  String logReadItemsAt(int count, String location) {
    return 'Read $count items at $location';
  }

  @override
  String logReadError(String location, String error) {
    return 'Read error $location: $error';
  }

  @override
  String get logOpenAppInfo => 'Opening app info';

  @override
  String logOpenAppInfoError(String error) {
    return 'App info error: $error';
  }

  @override
  String logApkCopied(String name) {
    return 'APK copied: $name';
  }

  @override
  String logApkCopyError(String error) {
    return 'APK copy error: $error';
  }

  @override
  String logApkShared(String name) {
    return 'APK shared: $name';
  }

  @override
  String logApkShareError(String error) {
    return 'APK share error: $error';
  }

  @override
  String logPlayStoreError(String error) {
    return 'Play Store error: $error';
  }

  @override
  String logApkBackup(String path) {
    return 'APK backed up → $path';
  }

  @override
  String logApkBackupError(String error) {
    return 'APK backup error: $error';
  }

  @override
  String logUninstall(String name) {
    return 'Uninstall: $name';
  }

  @override
  String logUninstallError(String error) {
    return 'Uninstall error: $error';
  }

  @override
  String logLaunchApp(String package) {
    return 'Launch app: $package';
  }

  @override
  String logOpenAppError(String error) {
    return 'Open app error: $error';
  }

  @override
  String logHomeLoadError(String error) {
    return 'Home load error: $error';
  }

  @override
  String logFtpError(String error) {
    return 'FTP error: $error';
  }

  @override
  String logZipReadError(String error) {
    return 'ZIP read error: $error';
  }

  @override
  String logFileOpened(String name) {
    return 'Opened $name';
  }

  @override
  String logFormatNotSupportedOpen(String format) {
    return 'Format $format is not supported.';
  }

  @override
  String logFtpFileLoadError(String error) {
    return 'FTP file load error: $error';
  }

  @override
  String logCreateFile(String name) {
    return 'Created file: $name';
  }

  @override
  String logCreateFolder(String name) {
    return 'Created folder: $name';
  }

  @override
  String logCopiedItems(int count) {
    return 'Copied $count items';
  }

  @override
  String logCutItems(int count) {
    return 'Cut $count items';
  }

  @override
  String get logCannotPasteInZip => 'Cannot paste inside ZIP';

  @override
  String get logPasteSuccess => 'Paste successful';

  @override
  String logPasteError(String error) {
    return 'Paste error: $error';
  }

  @override
  String logDuplicateSuccess(int count) {
    return 'Duplicated $count items';
  }

  @override
  String logDuplicateError(String error) {
    return 'Duplicate error: $error';
  }

  @override
  String get logDeletePartialNotice => 'Deleted items cannot be restored. Remaining items were not deleted.';

  @override
  String logMovedToTrash(int count) {
    return 'Moved $count items to trash';
  }

  @override
  String logDeletedItems(int count) {
    return 'Deleted $count items';
  }

  @override
  String logDeleteError(String error) {
    return 'Delete error: $error';
  }

  @override
  String logRenamedTo(String name) {
    return 'Renamed to $name';
  }

  @override
  String logZippedTo(String name) {
    return 'Compressed to $name';
  }

  @override
  String logUnzipTo(String folder) {
    return 'Extracted to $folder';
  }

  @override
  String logUnzipError(String error) {
    return 'Extract error: $error';
  }

  @override
  String get logApkNotFound => 'APK file not found';

  @override
  String logInstallApkError(String error) {
    return 'APK install error: $error';
  }

  @override
  String get logOpeningFromZip => 'Opening file from ZIP...';

  @override
  String get logPrepareShareFromZip => 'Preparing to share file from ZIP...';

  @override
  String logShareFileError(String error) {
    return 'Share file error: $error';
  }

  @override
  String logFormatNotSupportedDirect(String format) {
    return 'Format $format is not supported for direct extraction.';
  }

  @override
  String logFileSaved(String name) {
    return 'Saved $name';
  }

  @override
  String logSaveError(String error) {
    return 'Save error: $error';
  }

  @override
  String logWebServerStarted(String auth, String url, String scope) {
    return 'Web server$auth: $url$scope';
  }

  @override
  String get logWebServerAuthWith => ' (password)';

  @override
  String logWebServerScopeFolder(String path) {
    return ' — folder: $path';
  }

  @override
  String get logWebServerScopeAll => ' — entire storage';

  @override
  String logWebServerStartError(String error) {
    return 'Web server start error: $error';
  }

  @override
  String get logWebServerStopped => 'Web server stopped';

  @override
  String logZipError(String error) {
    return 'ZIP error: $error';
  }

  @override
  String get errCannotReadZipList => 'Cannot read file list in ZIP';

  @override
  String errZipTooLargeVerifyPassword(String sizeMb) {
    return 'ZIP too large ($sizeMb MB). Cannot verify password in memory.';
  }

  @override
  String errZipAesTooLarge(String sizeMb, String limitMb) {
    return 'AES-encrypted ZIP too large ($sizeMb MB). Limit $limitMb MB.';
  }

  @override
  String errZipTooLargeNeedUnzip(String sizeMb) {
    return 'ZIP too large ($sizeMb MB). unzip/7z command required on device.';
  }

  @override
  String get errFlutterArchiveUnavailable => 'flutter_archive is not available on this platform';

  @override
  String get errCannotExtractZipEntry => 'Cannot extract ZIP entry';

  @override
  String get errCannotExtractTar => 'Cannot extract TAR';

  @override
  String errDataTooLargeCompress(String sizeMb) {
    return 'Data too large ($sizeMb MB). Cannot compress in memory.';
  }

  @override
  String get errMultiFolderZipNoCommand => 'Cannot compress multiple folders — zip command missing on device';

  @override
  String get errCannotCreateZip => 'Cannot create ZIP file';

  @override
  String get errParentDirNotFound => 'Parent directory does not exist';

  @override
  String get errCannotWriteDestDir => 'Cannot write to destination directory';

  @override
  String errZipTooLargeExtract(String sizeMb) {
    return 'ZIP too large ($sizeMb MB). Native extraction or unzip required.';
  }

  @override
  String get errZipTooLargeSingleEntry => 'ZIP too large to extract a single entry in RAM';

  @override
  String get errZipEntryNotFound => 'Entry not found in ZIP';

  @override
  String get errFileNotExists => 'File does not exist';

  @override
  String get errInvalidZip => 'Invalid ZIP file';

  @override
  String get errZipEocdNotFound => 'End of Central Directory not found';

  @override
  String get errZipCdCorrupt => 'ZIP Central Directory is corrupt';

  @override
  String errZipCdTooLarge(String sizeMb) {
    return 'Central Directory too large ($sizeMb MB)';
  }

  @override
  String get errZipCdIncomplete => 'Could not read full Central Directory';

  @override
  String get errZip64LocatorInvalid => 'Invalid ZIP64 locator';

  @override
  String get errZip64EocdInvalid => 'Invalid ZIP64 EOCD signature';

  @override
  String get errZip64EocdOutOfFile => 'ZIP64 EOCD is outside the file';

  @override
  String get errDirectoryNotExists => 'Directory does not exist';

  @override
  String errCannotAccessPath(String path, String message) {
    return 'Cannot access $path: $message';
  }

  @override
  String get errAlreadyExists => 'Already exists';

  @override
  String get errShellListingAndroidOnly => 'Shell listing is only supported on Android';

  @override
  String get errSuperuserAndroidOnly => 'Superuser mode is only supported on Android';

  @override
  String get errCannotCheckSuperuser => 'Cannot check superuser access';

  @override
  String get errSuperuserCheckTimeout => 'Superuser check timed out. Device may not be rooted or access not granted.';

  @override
  String get errInstallApkAndroidOnly => 'APK install is only supported on Android';

  @override
  String get errApkNotFound => 'APK not found';

  @override
  String get errApkBackupFailed => 'Backup failed';

  @override
  String get errNoWebServerPassword => 'No Web Server password set';

  @override
  String get errNoPassword => 'No password set';

  @override
  String get errCurrentPasswordWrong => 'Current password is incorrect';

  @override
  String get errBiometricUnlockReason => 'Unlock Cope X Studio';

  @override
  String get errCannotTestPasswordOnPlatform => 'Cannot verify password on this platform';

  @override
  String get errShellUnsupportedZipEncryption => 'Shell does not support this ZIP encryption format';

  @override
  String get errCannotRunUnzip => 'Cannot run unzip command';

  @override
  String get err7zNotFound => '7z command not found';

  @override
  String get errEmptyZipSources => 'Empty source list for compression';

  @override
  String get errCannotRunZip => 'Cannot run zip command';

  @override
  String get errPasswordNeeded => 'Password required';

  @override
  String get apiPasswordRequired => 'Password required';

  @override
  String get apiWrongPassword => 'Wrong password';

  @override
  String get apiCannotListFolder => 'Cannot list folder';

  @override
  String get apiFileNotFound => 'File not found';

  @override
  String get apiCannotFolderThumbnail => 'Cannot get folder thumbnail';

  @override
  String get apiCannotReadFolder => 'Cannot read folder';

  @override
  String get apiFileTooLargeEdit => 'File too large to edit (>2MB)';

  @override
  String get apiMissingFolderName => 'Missing folder name';

  @override
  String get apiMissingFileName => 'Missing file name';

  @override
  String get apiMissingNewName => 'Missing new name';

  @override
  String get apiNothingToDelete => 'Nothing to delete';

  @override
  String get apiCannotWriteFolder => 'Cannot write folder';

  @override
  String get apiNothingToZip => 'Nothing to compress';

  @override
  String get apiNotZipFile => 'Not a ZIP file';

  @override
  String get apiInvalidDestFolder => 'Invalid destination folder';

  @override
  String get apiMissingFileNameParam => 'Missing file name (name parameter)';

  @override
  String get welcomeTitle => 'Welcome to Cope X Studio';

  @override
  String get welcomeSubtitle => 'Browse files, edit code, and manage archives — all in one place.';

  @override
  String get welcomeLanguage => 'Language';

  @override
  String get welcomeTheme => 'Theme';

  @override
  String get welcomeNext => 'Next';

  @override
  String get welcomeBack => 'Back';

  @override
  String get welcomeGetStarted => 'Get started';

  @override
  String get welcomePermissionTitle => 'Storage access';

  @override
  String get welcomePermissionBody => 'Allow all-files access so Cope X Studio can browse and manage files across your device.';

  @override
  String get welcomeGrantPermission => 'Grant access';

  @override
  String get welcomeSkipPermission => 'Skip for now';

  @override
  String get welcomePermissionGranted => 'Access granted';

  @override
  String get welcomePermissionNotNeeded => 'No extra permission is required on this device.';

  @override
  String get welcomePermissionsTitle => 'Permissions';

  @override
  String get welcomePermissionsSubtitle => 'Cope X Studio needs a few permissions to work properly.';

  @override
  String get welcomeNotificationTitle => 'Notifications';

  @override
  String get welcomeNotificationBody => 'Show status for Web Server, media playback, and background tasks.';

  @override
  String get welcomeGrantNotification => 'Allow notifications';

  @override
  String get welcomeNotificationGranted => 'Notifications allowed';

  @override
  String get welcomeStorageRequiredHint => 'Grant storage access to continue.';

  @override
  String welcomeStep(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get welcomeDoneTitle => 'You\'re all set!';

  @override
  String get welcomeDoneBody => 'Everything is ready. Start exploring your files.';

  @override
  String get restartAppTitle => 'Restart App';

  @override
  String get restartAppBody => 'Do you want to restart the app now to fully apply the new theme?';

  @override
  String get restartNow => 'Restart now';

  @override
  String get later => 'Later';
}
