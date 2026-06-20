import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'package:cope_x_studio/models/app_tab.dart';
import 'package:cope_x_studio/models/app_theme_mode.dart';
import 'package:cope_x_studio/models/browser_entry.dart';
import 'package:cope_x_studio/models/browser_view_mode.dart';
import 'package:cope_x_studio/models/editor_tab.dart';
import 'package:cope_x_studio/models/file_clipboard.dart';
import 'package:cope_x_studio/models/file_open_as.dart';
import 'package:cope_x_studio/models/file_op_notice.dart';
import 'package:cope_x_studio/models/ftp_server_config.dart';
import 'package:cope_x_studio/models/installed_app_info.dart';
import 'package:cope_x_studio/models/recent_file_entry.dart';
import 'package:cope_x_studio/models/root_access_mode.dart';
import 'package:cope_x_studio/models/text_encoding.dart';
import 'package:cope_x_studio/services/app_manager_service.dart';
import 'package:cope_x_studio/models/tab_file_operation.dart';
import 'package:cope_x_studio/models/tab_file_operation_state.dart';
import 'package:cope_x_studio/models/tree_browser_node.dart';
import 'package:cope_x_studio/services/archive_cancel_token.dart';
import 'package:cope_x_studio/services/archive_password_exception.dart';
import 'package:cope_x_studio/services/archive_service.dart';
import 'package:cope_x_studio/services/file_service.dart';
import 'package:cope_x_studio/services/language_detector.dart';
import 'package:cope_x_studio/services/open_with_service.dart';
import 'package:cope_x_studio/services/permission_service.dart';
import 'package:cope_x_studio/services/recent_files_scanner.dart';
import 'package:cope_x_studio/utils/entry_progress_tracker.dart';
import 'package:cope_x_studio/services/shell_list_service.dart';
import 'package:cope_x_studio/services/thumbnail_service.dart';
import 'package:cope_x_studio/theme/vscode_theme.dart';
import 'package:cope_x_studio/services/web_server/web_server_service.dart';
import 'package:cope_x_studio/services/web_server/web_server_notification_service.dart';
import 'package:cope_x_studio/l10n/l10n_scope.dart';
import 'package:cope_x_studio/providers/locale_provider.dart';
import 'package:cope_x_studio/providers/onboarding_provider.dart';
import 'package:cope_x_studio/providers/security_provider.dart';
import 'package:cope_x_studio/services/storage_roots.dart';
import 'package:cope_x_studio/services/trash_service.dart';
import 'package:cope_x_studio/services/text_encoding_service.dart';
import 'package:cope_x_studio/utils/network_utils.dart';
import 'package:cope_x_studio/utils/app_path_utils.dart';
import 'package:cope_x_studio/utils/file_type_utils.dart';
import 'package:cope_x_studio/utils/path_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pure_ftp/pure_ftp.dart';

class WorkspaceProvider extends ChangeNotifier {
  WorkspaceProvider({
    FileService? fileService,
    PermissionService? permissionService,
    ArchiveService? archiveService,
    OpenWithService? openWithService,
    WebServerService? webServerService,
    ShellListService? shellListService,
    AppManagerService? appManagerService,
  })  : _fileService = fileService ?? FileService(),
        _permissionService = permissionService ?? PermissionService(),
        _archiveService = archiveService ?? ArchiveService(),
        _openWithService = openWithService ?? OpenWithService(),
        _shellListService = shellListService ?? ShellListService(),
        _appManagerService = appManagerService ?? AppManagerService() {
    _webServerService = webServerService ??
        WebServerService(
          fileService: _fileService,
          archiveService: _archiveService,
        );
  }

  final FileService _fileService;
  final PermissionService _permissionService;
  final ArchiveService _archiveService;
  final OpenWithService _openWithService;
  final ShellListService _shellListService;
  final AppManagerService _appManagerService;
  late final WebServerService _webServerService;

  SecurityProvider? _security;
  LocaleProvider? _localeProvider;
  VoidCallback? _localeListener;
  OnboardingProvider? _onboarding;

  void attachSecurity(SecurityProvider security) => _security = security;

  void attachOnboarding(OnboardingProvider onboarding) => _onboarding = onboarding;

  void attachLocale(LocaleProvider localeProvider) {
    if (_localeListener != null) {
      _localeProvider?.removeListener(_localeListener!);
    }
    _localeProvider = localeProvider;
    _localeListener = () {
      _homeEntriesCache = null;
      notifyListeners();
    };
    localeProvider.addListener(_localeListener!);
  }

  final List<AppTab> _tabs = [];
  String? _activeTabId;
  FileClipboardEntry? _clipboard;
  String? _statusMessage;
  final List<String> _logHistory = [];
  bool _storageGranted = false;
  bool _permissionChecked = false;
  bool _showHidden = false;
  BrowserViewMode _browserViewMode = BrowserViewMode.list;
  bool _openApkAsZip = true;
  RootAccessMode _rootAccessMode = RootAccessMode.normal;
  TextEncoding _textEncoding = TextEncoding.utf8;
  bool _hapticEnabled = true;
  double _editorFontSize = 13;
  bool _editorShowLineNumbers = true;
  bool _editorWordWrap = false;
  double _uiScale = 0.8;
  bool _fullscreenEnabled = false;
  bool _rememberLastPath = true;
  bool _requireExitConfirmation = true;
  bool _useTrash = false;
  AppThemeMode _appThemeMode = AppThemeMode.dark;

  final List<RecentFileEntry> _recentFiles = [];
  bool _recentLoading = false;
  bool _recentScanInProgress = false;
  int _recentScanGeneration = 0;

  List<BrowserEntry>? _homeEntriesCache;
  bool _homeEntriesLoading = false;
  int _homeLoadGeneration = 0;
  String? _internalStoragePath;
  bool get isHomeLoading => _homeEntriesLoading;

  // FTP State
  final List<FtpServerConfig> _ftpServers = [];
  List<FtpServerConfig> get ftpServers => List.unmodifiable(_ftpServers);

  final Map<String, List<BrowserEntry>> _ftpCache = {};
  final Map<String, String> _ftpErrors = {};
  final Set<String> _ftpLoadingPaths = {};

  bool isFtpLoading(String path) => _ftpLoadingPaths.contains(path);
  String? getFtpError(String path) => _ftpErrors[path];

  final Map<String, List<BrowserEntry>> _shellDirCache = {};
  final Map<String, String> _shellErrors = {};
  final Map<String, String> _dirAccessNotes = {};
  final Set<String> _shellLoadingPaths = {};
  bool isShellLoading(String path) => _shellLoadingPaths.contains(path);
  String? getShellError(String path) => _shellErrors[path];
  String? getDirectoryAccessNote(String path) => _dirAccessNotes[path];

  final Map<String, List<InstalledAppInfo>> _appsCache = {};
  final Map<String, Uint8List> _appIcons = {};
  final Set<String> _appsLoadingKeys = {};
  final Map<String, int> _appsLoadGenerationByKey = {};
  String? _appsError;
  bool get isAppsLoading => _appsLoadingKeys.isNotEmpty;
  bool isAppsListLoading(String listPath) {
    if (!AppPathUtils.isAppsList(listPath)) return false;
    final cacheKey = AppPathUtils.isSystemList(listPath) ? 'system' : 'user';
    return _appsLoadingKeys.contains(cacheKey);
  }
  String? get appsError => _appsError;
  Uint8List? appIcon(String packageName) => _appIcons[packageName];
  InstalledAppInfo? getAppInfo(String packageName) {
    for (final list in _appsCache.values) {
      for (final app in list) {
        if (app.packageName == packageName) return app;
      }
    }
    return null;
  }

  List<AppTab> get tabs => List.unmodifiable(_tabs);
  String? get activeTabId => _activeTabId;
  AppTab? get activeTab => _tabs.where((t) => t.id == _activeTabId).firstOrNull;
  FileClipboardEntry? get clipboard => _clipboard;
  String? get statusMessage => _statusMessage;
  List<String> get logHistory => List.unmodifiable(_logHistory);
  bool get storageGranted => _storageGranted;
  bool get permissionChecked => _permissionChecked;
  bool get showHidden => _showHidden;
  BrowserViewMode get browserViewMode => _browserViewMode;
  bool get isGridView => _browserViewMode == BrowserViewMode.grid;
  bool get isTreeView => _browserViewMode == BrowserViewMode.tree;
  bool get openApkAsZip => _openApkAsZip;
  RootAccessMode get rootAccessMode => _rootAccessMode;
  TextEncoding get textEncoding => _textEncoding;
  bool get hapticEnabled => _hapticEnabled;
  double get editorFontSize => _editorFontSize;
  bool get editorShowLineNumbers => _editorShowLineNumbers;
  bool get editorWordWrap => _editorWordWrap;
  double get uiScale => _uiScale;
  bool get fullscreenEnabled => _fullscreenEnabled;
  bool get rememberLastPath => _rememberLastPath;
  bool get requireExitConfirmation => _requireExitConfirmation;
  bool get useTrash => _useTrash;
  AppThemeMode get appThemeMode => _appThemeMode;
  ThemeMode get themeMode => _appThemeMode.themeMode;

  Brightness get effectiveBrightness => switch (_appThemeMode) {
        AppThemeMode.dark => Brightness.dark,
        AppThemeMode.light => Brightness.light,
        AppThemeMode.system =>
          WidgetsBinding.instance.platformDispatcher.platformBrightness,
      };

  double scaledSize(double value) => value * _uiScale;

  bool _isBusy = false;
  bool get isBusy => _isBusy;

  final Map<String, String> _zipPasswords = {};
  final Map<String, String> _zipErrors = {};
  final Map<String, List<BrowserEntry>> _zipListCache = {};
  final Set<String> _zipListLoading = {};

  // Tree view state
  final Map<String, Set<String>> _treeExpandedByTab = {};
  final Map<String, List<BrowserEntry>> _treeChildrenCache = {};
  final Set<String> _treeLoadingKeys = {};

  final Map<String, TabFileOperationState> _tabFileOperations = {};

  FileOpNotice? _pendingFileOpNotice;
  FileOpNotice? get pendingFileOpNotice => _pendingFileOpNotice;

  void clearPendingFileOpNotice() {
    if (_pendingFileOpNotice == null) return;
    _pendingFileOpNotice = null;
    notifyListeners();
  }

  void _queueFileOpNotice(String title, String message) {
    _pendingFileOpNotice = FileOpNotice(title: title, message: message);
    notifyListeners();
  }

  bool isFileOperationOverlayForTab(String tabId) => _tabFileOperations.containsKey(tabId);

  TabFileOperationState? fileOperationForTab(String tabId) => _tabFileOperations[tabId];

  double archiveProgressForTab(String tabId) =>
      _tabFileOperations[tabId]?.progress ?? 0;

  String? archiveProgressLabelForTab(String tabId) =>
      _tabFileOperations[tabId]?.label;

  bool fileOperationCanCancelForTab(String tabId) =>
      _tabFileOperations[tabId]?.canCancel ?? false;

  bool fileOperationIsRollingBackForTab(String tabId) =>
      _tabFileOperations[tabId]?.isRollingBack ?? false;

  String fileOperationOverlayTitleForTab(String tabId) =>
      _tabFileOperations[tabId]?.overlayTitle ?? '';

  bool get isArchiveExtracting =>
      _tabFileOperations.values.any((o) => o.type == TabFileOperation.unzip);

  bool isArchiveExtractingForTab(String tabId) =>
      _tabFileOperations[tabId]?.type == TabFileOperation.unzip;
  bool get isZipListing => _zipListLoading.isNotEmpty;

  String? _zipOpeningKey;
  String? _zipOpeningLabel;

  bool isZipOpening(String zipPath) =>
      _zipOpeningKey != null && _zipOpeningKey!.startsWith('$zipPath|');
  String? get zipOpeningLabel => _zipOpeningLabel;

  void _setZipOpening(String? zipPath, String? innerPath) {
    if (zipPath == null || innerPath == null) {
      _zipOpeningKey = null;
      _zipOpeningLabel = null;
    } else {
      _zipOpeningKey = '$zipPath|${innerPath.replaceAll('\\', '/')}';
      _zipOpeningLabel = p.basename(innerPath);
    }
    notifyListeners();
  }

  String _zipListKey(String zipPath, String innerPath, [String? password]) =>
      '$zipPath|${innerPath.replaceAll('\\', '/')}|${password ?? ''}';

  void _setTabOperationProgress(String tabId, double progress, [String? label]) {
    final op = _tabFileOperations[tabId];
    if (op == null) return;
    op.progress = progress.clamp(0.0, 1.0);
    if (label != null) {
      op.label = label;
    }
    notifyListeners();
  }

  void _endFileOperation(String tabId) {
    _tabFileOperations.remove(tabId);
    notifyListeners();
  }

  void _startFileOperation(
    TabFileOperation type,
    String tabId, {
    String? label,
    ArchiveCancelToken? cancelToken,
    String? destDir,
  }) {
    _tabFileOperations[tabId] = TabFileOperationState(
      type: type,
      label: label,
      cancelToken: cancelToken,
      destDir: destDir,
    );
    notifyListeners();
  }

  Future<void> cancelFileOperation([String? tabId]) async {
    final targetTabId = tabId ?? _activeTabId;
    if (targetTabId == null) return;

    final op = _tabFileOperations[targetTabId];
    if (op == null || !op.canCancel) return;

    if (op.type == TabFileOperation.delete) {
      op.cancelToken?.cancel();
      return;
    }

    op.cancelToken?.cancel();
    if (op.type == TabFileOperation.unzip) {
      await _archiveService.abortExtraction();
    }

    await _performOperationRollback(targetTabId);

    final l10n = L10nScope.current;
    _log(switch (op.type) {
      TabFileOperation.unzip => l10n.cancelUnzip,
      TabFileOperation.zip => l10n.cancelZip,
      TabFileOperation.paste => l10n.cancelPaste,
      TabFileOperation.duplicate => l10n.cancelDuplicate,
      _ => l10n.cancelOperation,
    });
    _statusMessage = switch (op.type) {
      TabFileOperation.unzip => l10n.cancelUnzip,
      TabFileOperation.zip => l10n.cancelZip,
      TabFileOperation.paste => l10n.cancelPaste,
      TabFileOperation.duplicate => l10n.cancelDuplicate,
      _ => l10n.cancelOperation,
    };
    _endFileOperation(targetTabId);
    if (_tabFileOperations.isEmpty) {
      _setBusy(false);
    }
    notifyListeners();
  }

  Future<void> _performOperationRollback(String tabId) async {
    final op = _tabFileOperations[tabId];
    if (op == null || op.isRollingBack) return;

    op.isRollingBack = true;
    op.progress = 0;
    op.label = null;
    notifyListeners();
    await Future<void>.delayed(Duration.zero);

    switch (op.type) {
      case TabFileOperation.unzip:
      case TabFileOperation.zip:
        await _rollbackOperationPath(op.destDir);
      case TabFileOperation.paste:
        await _rollbackPasteOperation(op);
      case TabFileOperation.duplicate:
        await _rollbackCreatedPaths(op.rollbackPaths);
      default:
        break;
    }
  }

  Future<void> _rollbackCreatedPaths(List<String> paths) async {
    for (var i = paths.length - 1; i >= 0; i--) {
      await _deletePathQuiet(paths[i]);
    }
  }

  Future<void> _deletePathQuiet(String path) async {
    try {
      if (path.startsWith('@ftp/')) {
        final (serverId, remotePath) = _parseFtpPath(path);
        final client = await _connectFtp(serverId);
        try {
          if (_isFtpDirectory(path)) {
            await client.getDirectory(remotePath).delete(recursive: true);
          } else {
            await client.getFile(remotePath).delete();
          }
        } finally {
          await client.disconnect();
        }
      } else {
        await _rollbackOperationPath(path);
      }
    } catch (_) {}
  }

  Future<void> _rollbackPasteOperation(TabFileOperationState op) async {
    for (final pair in op.movedPairs.reversed) {
      try {
        if (await FileSystemEntity.type(pair.dest) != FileSystemEntityType.notFound &&
            await FileSystemEntity.type(pair.src) == FileSystemEntityType.notFound) {
          await _fileService.renameEntity(pair.dest, pair.src);
        }
      } catch (_) {}
    }
    await _rollbackCreatedPaths(op.rollbackPaths);
  }

  /// Giữ tên cũ cho tương thích UI.
  Future<void> cancelArchiveExtraction([String? tabId]) => cancelFileOperation(tabId);

  Future<void> _rollbackOperationPath(String? path) async {
    if (path == null) return;
    try {
      final type = FileSystemEntity.typeSync(path);
      if (type == FileSystemEntityType.directory) {
        final dir = Directory(path);
        if (await dir.exists()) await dir.delete(recursive: true);
      } else if (type == FileSystemEntityType.file) {
        final file = File(path);
        if (await file.exists()) await file.delete();
      } else {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        } else {
          final dir = Directory(path);
          if (await dir.exists()) await dir.delete(recursive: true);
        }
      }
    } catch (_) {}
  }

  void _cancelFileOperationIfActive(String tabId) {
    if (_tabFileOperations.containsKey(tabId)) {
      unawaited(cancelFileOperation(tabId));
    }
  }

  String? getZipError(String zipPath) => _zipErrors[zipPath];
  String? getZipPassword(String zipPath) => _zipPasswords[zipPath];

  void clearZipError(String zipPath) {
    _zipErrors.remove(zipPath);
    notifyListeners();
  }

  void _setBusy(bool val) {
    _isBusy = val;
    notifyListeners();
  }

  void _hapticOnFileOpComplete() {
    if (_hapticEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  static void applyFullscreenMode(bool enabled, {Brightness brightness = Brightness.dark}) {
    applyVsCodeSystemOverlay(brightness, fullscreen: enabled);
  }

  void _applySystemChrome() {
    applyVsCodeSystemOverlay(effectiveBrightness, fullscreen: _fullscreenEnabled);
  }

  Brightness? _lastAppliedThemeBrightness;

  void applySystemChromeForTheme(Brightness brightness) {
    if (_lastAppliedThemeBrightness == brightness) return;
    _lastAppliedThemeBrightness = brightness;
    if (!_fullscreenEnabled) {
      applyVsCodeSystemOverlay(brightness, fullscreen: false);
    }
  }

  Future<void> _persistSetting(String key, String value) async {
    try {
      const storage = FlutterSecureStorage();
      await storage.write(key: key, value: value);
    } catch (_) {}
  }

  Future<void> setTextEncoding(TextEncoding encoding) async {
    if (_textEncoding.id == encoding.id) return;
    _textEncoding = encoding;
    await _persistSetting('text_encoding', encoding.id);
    notifyListeners();
  }

  Future<void> setHapticEnabled(bool value) async {
    if (_hapticEnabled == value) return;
    _hapticEnabled = value;
    await _persistSetting('haptic_enabled', value ? 'true' : 'false');
    notifyListeners();
  }

  Future<void> setEditorFontSize(double value) async {
    final clamped = value.clamp(10.0, 28.0);
    if (_editorFontSize == clamped) return;
    _editorFontSize = clamped;
    await _persistSetting('editor_font_size', clamped.toStringAsFixed(0));
    notifyListeners();
  }

  Future<void> setEditorShowLineNumbers(bool value) async {
    if (_editorShowLineNumbers == value) return;
    _editorShowLineNumbers = value;
    await _persistSetting('editor_show_line_numbers', value ? 'true' : 'false');
    notifyListeners();
  }

  Future<void> setEditorWordWrap(bool value) async {
    if (_editorWordWrap == value) return;
    _editorWordWrap = value;
    await _persistSetting('editor_word_wrap', value ? 'true' : 'false');
    notifyListeners();
  }

  void adjustEditorFontSize(int delta) {
    unawaited(setEditorFontSize(_editorFontSize + delta));
  }

  Future<void> setUiScale(double value) async {
    final clamped = value.clamp(0.8, 1.4);
    if (_uiScale == clamped) return;
    _uiScale = clamped;
    await _persistSetting('ui_scale', clamped.toStringAsFixed(2));
    notifyListeners();
  }

  Future<void> setAppThemeMode(AppThemeMode mode) async {
    if (_appThemeMode == mode) return;
    _appThemeMode = mode;
    await _persistSetting('app_theme_mode', mode.storageValue);
    _applySystemChrome();
    notifyListeners();
  }

  Future<void> setFullscreenEnabled(bool value) async {
    if (_fullscreenEnabled == value) return;
    _fullscreenEnabled = value;
    _applySystemChrome();
    await _persistSetting('fullscreen_enabled', value ? 'true' : 'false');
    notifyListeners();
  }

  Future<void> setRememberLastPath(bool value) async {
    if (_rememberLastPath == value) return;
    _rememberLastPath = value;
    await _persistSetting('remember_last_path', value ? 'true' : 'false');
    if (!value) {
      await _persistSetting('session_state', '');
    }
    notifyListeners();
  }

  Future<void> setRequireExitConfirmation(bool value) async {
    if (_requireExitConfirmation == value) return;
    _requireExitConfirmation = value;
    await _persistSetting('require_exit_confirmation', value ? 'true' : 'false');
    notifyListeners();
  }

  Future<void> setUseTrash(bool value) async {
    if (_useTrash == value) return;
    _useTrash = value;
    await _persistSetting('use_trash', value ? 'true' : 'false');
    if (value) {
      unawaited(TrashService.instance.purgeExpired());
    }
    notifyListeners();
  }

  Future<void> saveSessionState() async {
    if (!_rememberLastPath || _tabs.isEmpty) return;
    try {
      const storage = FlutterSecureStorage();
      final data = {
        'activeTabId': _activeTabId,
        'tabs': _tabs
            .map(
              (t) => {
                'path': t.currentPath,
                'mode': t.mode.name,
                if (t.zipArchivePath != null) 'zipArchivePath': t.zipArchivePath,
                if (t.zipInnerPath.isNotEmpty) 'zipInnerPath': t.zipInnerPath,
              },
            )
            .toList(),
      };
      await storage.write(key: 'session_state', value: jsonEncode(data));
    } catch (_) {}
  }

  Future<void> _tryRestoreSession() async {
    if (!_rememberLastPath) return;
    try {
      const storage = FlutterSecureStorage();
      final raw = await storage.read(key: 'session_state');
      if (raw == null || raw.isEmpty) return;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final items = map['tabs'] as List<dynamic>?;
      if (items == null || items.isEmpty) return;

      _tabs.clear();
      for (final item in items) {
        final entry = Map<String, dynamic>.from(item as Map);
        final path = entry['path'] as String? ?? '@home';
        final modeName = entry['mode'] as String? ?? TabMode.browser.name;
        final mode = TabMode.values.firstWhere(
          (m) => m.name == modeName,
          orElse: () => TabMode.browser,
        );
        final zipPath = entry['zipArchivePath'] as String?;
        final zipInner = entry['zipInnerPath'] as String? ?? '';
        _tabs.add(
          AppTab(
            currentPath: path,
            mode: zipPath != null ? TabMode.zipViewer : mode,
            zipArchivePath: zipPath,
            zipInnerPath: zipInner,
          ),
        );
      }
      final savedActive = map['activeTabId'] as String?;
      if (savedActive != null && _tabs.any((t) => t.id == savedActive)) {
        _activeTabId = savedActive;
      } else {
        _activeTabId = _tabs.first.id;
      }
    } catch (_) {}
  }

  Future<void> _loadAppSettings(FlutterSecureStorage storage) async {
    _textEncoding = TextEncoding.fromId(await storage.read(key: 'text_encoding'));
    _hapticEnabled = (await storage.read(key: 'haptic_enabled')) != 'false';
    _editorFontSize = double.tryParse(await storage.read(key: 'editor_font_size') ?? '') ?? 13;
    _editorFontSize = _editorFontSize.clamp(10, 28);
    _editorShowLineNumbers =
        (await storage.read(key: 'editor_show_line_numbers')) != 'false';
    _editorWordWrap = (await storage.read(key: 'editor_word_wrap')) == 'true';
    _uiScale = double.tryParse(await storage.read(key: 'ui_scale') ?? '') ?? 0.8;
    _uiScale = _uiScale.clamp(0.8, 1.4);
    _fullscreenEnabled = (await storage.read(key: 'fullscreen_enabled')) == 'true';
    _rememberLastPath = (await storage.read(key: 'remember_last_path')) != 'false';
    _requireExitConfirmation = (await storage.read(key: 'require_exit_confirmation')) != 'false';
    _useTrash = (await storage.read(key: 'use_trash')) == 'true';
    _appThemeMode = AppThemeMode.fromStorage(await storage.read(key: 'app_theme_mode'));
    _applySystemChrome();
    if (_useTrash) {
      unawaited(TrashService.instance.purgeExpired());
    }
  }

  Future<void> unlockZip(String tabId, String zipPath, String password) async {
    _setBusy(true);
    try {
      await _archiveService.verifyZipPassword(zipPath, password);
      _zipPasswords[zipPath] = password;
      _zipErrors.remove(zipPath);
      _archiveService.clearZipCache(zipPath);
      _zipListCache.removeWhere((k, _) => k.startsWith('$zipPath|'));
      _log(L10nScope.current.logUnlockZip(p.basename(zipPath)));
      refreshTab(tabId);
    } catch (e) {
      final l10n = L10nScope.current;
      _zipErrors[zipPath] = e is ArchivePasswordException ? e.toString() : l10n.wrongPassword;
      _log(L10nScope.current.logUnlockError('$e'));
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }
  bool get isRecentLoading => _recentLoading;
  List<String> get recentFilePaths =>
      _recentFiles.map((e) => e.path).toList(growable: false);
  bool get isWebServerRunning => _webServerService.isRunning;
  String get defaultBrowsePath => StorageRoots.defaultRoot(_permissionService);
  String? get webServerRoot => _webServerService.rootPath;
  List<String> get webServerUrls {
    if (!_webServerService.isRunning) return [];
    return _webServerService.addresses
        .map((a) => 'http://$a:${WebServerService.port}')
        .toList();
  }

  String? get webServerUrl =>
      NetworkUtils.buildPreferredUrl(_webServerService.addresses, WebServerService.port);

  void clearLogs() {
    _logHistory.clear();
    notifyListeners();
  }

  void _log(String message) {
    final ts = DateFormat('HH:mm:ss').format(DateTime.now());
    _logHistory.insert(0, '[$ts] $message');
    if (_logHistory.length > 200) {
      _logHistory.removeLast();
    }
    _statusMessage = message;
  }

  String _norm(String path) => PathUtils.normalize(path);

  int _tabIndex(String tabId) => _tabs.indexWhere((t) => t.id == tabId);

  AppTab _tab(String tabId) => _tabs[_tabIndex(tabId)];

  void _setTab(String tabId, AppTab tab) {
    final i = _tabIndex(tabId);
    if (i == -1) return;
    _tabs[i] = tab;
  }

  Future<void> setShowHidden(bool value) async {
    if (_showHidden == value) return;
    _showHidden = value;
    try {
      const storage = FlutterSecureStorage();
      await storage.write(key: 'show_hidden', value: value ? 'true' : 'false');
    } catch (_) {}
    _shellDirCache.clear();
    _invalidateTreeCache();
    notifyListeners();
  }

  Future<void> toggleShowHidden() async {
    await setShowHidden(!_showHidden);
  }

  Future<void> setBrowserViewMode(BrowserViewMode mode) async {
    if (_browserViewMode == mode) return;
    _browserViewMode = mode;
    try {
      const storage = FlutterSecureStorage();
      await storage.write(key: 'browser_view_mode', value: mode.storageValue);
    } catch (_) {}
    if (mode == BrowserViewMode.tree && _activeTabId != null) {
      await syncTreeExpansion(_activeTabId!);
    }
    notifyListeners();
  }

  Future<void> toggleViewMode() async {
    final next = switch (_browserViewMode) {
      BrowserViewMode.list => BrowserViewMode.grid,
      BrowserViewMode.grid => BrowserViewMode.tree,
      BrowserViewMode.tree => BrowserViewMode.list,
    };
    await setBrowserViewMode(next);
  }

  bool supportsTreeView(AppTab tab) {
    if (tab.isZipViewer) return tab.zipArchivePath != null;
    if (tab.currentPath.startsWith('@')) return false;
    return true;
  }

  bool isTreeLoading(String tabId) {
    final prefix = '$tabId|';
    return _treeLoadingKeys.any((k) => k.startsWith(prefix));
  }

  bool isTreeExpanded(String tabId, String path) =>
      _treeExpandedByTab[tabId]?.contains(path) ?? false;

  String _treeCacheKey(String tabId, String path) => '$tabId|$path';

  String _treeFilesystemRoot(String path) {
    final normalized = p.normalize(path);
    if (normalized == '/') return '/';
    for (final root in PermissionService.androidStorageRoots) {
      final r = p.normalize(root);
      if (normalized == r || normalized.startsWith('$r/')) return r;
    }
    if (normalized.startsWith('/storage/')) {
      final parts = normalized.split('/').where((s) => s.isNotEmpty).toList();
      if (parts.length >= 2) return '/${parts[0]}/${parts[1]}';
    }
    return normalized;
  }

  String _treeListRoot(AppTab tab) {
    if (tab.isZipViewer) return '';
    return _treeFilesystemRoot(tab.currentPath);
  }

  String _treeCurrentPath(AppTab tab) {
    if (tab.isZipViewer) return tab.zipInnerPath;
    return tab.currentPath;
  }

  void _invalidateTreeCache({String? tabId}) {
    if (tabId == null) {
      _treeChildrenCache.clear();
      _treeLoadingKeys.clear();
      return;
    }
    final prefix = '$tabId|';
    _treeChildrenCache.removeWhere((k, _) => k.startsWith(prefix));
    _treeLoadingKeys.removeWhere((k) => k.startsWith(prefix));
  }

  Future<void> syncTreeExpansion(String tabId) async {
    final tab = _tab(tabId);
    if (!supportsTreeView(tab)) return;

    final expanded = _treeExpandedByTab.putIfAbsent(tabId, () => {});
    if (tab.isZipViewer) {
      const root = '';
      expanded.add(root);
      await _ensureTreeChildrenLoaded(tabId, root);
      var current = '';
      for (final part in tab.zipInnerPath.split('/').where((s) => s.isNotEmpty)) {
        current = current.isEmpty ? part : '$current/$part';
        expanded.add(current);
        await _ensureTreeChildrenLoaded(tabId, current);
      }
      notifyListeners();
      return;
    }

    final root = _treeFilesystemRoot(tab.currentPath);
    expanded.add(root);
    await _ensureTreeChildrenLoaded(tabId, root);

    if (tab.currentPath != root) {
      final rel = p.relative(tab.currentPath, from: root);
      var walk = root;
      for (final part in p.split(rel)) {
        if (part.isEmpty || part == '.') continue;
        walk = p.normalize(p.join(walk, part));
        expanded.add(walk);
        await _ensureTreeChildrenLoaded(tabId, walk);
      }
    }
    notifyListeners();
  }

  Future<void> toggleTreeNode(String tabId, String path, bool isDirectory) async {
    if (!isDirectory) return;
    final expanded = _treeExpandedByTab.putIfAbsent(tabId, () => {});
    if (expanded.contains(path)) {
      expanded.remove(path);
      notifyListeners();
      return;
    }
    expanded.add(path);
    await _ensureTreeChildrenLoaded(tabId, path);
    notifyListeners();
  }

  Future<void> _ensureTreeChildrenLoaded(String tabId, String dirPath) async {
    final key = _treeCacheKey(tabId, dirPath);
    if (_treeChildrenCache.containsKey(key) || _treeLoadingKeys.contains(key)) return;

    _treeLoadingKeys.add(key);
    notifyListeners();
    try {
      final children = await _fetchTreeChildren(tabId, dirPath);
      _treeChildrenCache[key] = children;
    } catch (_) {
      _treeChildrenCache[key] = [];
    } finally {
      _treeLoadingKeys.remove(key);
      notifyListeners();
    }
  }

  Future<List<BrowserEntry>> _fetchTreeChildren(String tabId, String dirPath) async {
    final tab = _tab(tabId);
    if (tab.isZipViewer && tab.zipArchivePath != null) {
      final zipPath = tab.zipArchivePath!;
      final pwd = _zipPasswords[zipPath];
      final cacheKey = _zipListKey(zipPath, dirPath, pwd);
      if (!_zipListCache.containsKey(cacheKey)) {
        await _loadZipListing(tabId, zipPath, dirPath);
      }
      return List<BrowserEntry>.from(_zipListCache[cacheKey] ?? []);
    }

    if (ShellListService.shouldUseShell(dirPath, mode: _rootAccessMode)) {
      if (!_shellDirCache.containsKey(dirPath)) {
        await _loadShellDirectory(tabId, dirPath);
      }
      return List<BrowserEntry>.from(_shellDirCache[dirPath] ?? []);
    }

    if (_dirAccessNotes.containsKey(dirPath)) return [];

    final probeAccess = ShellListService.isRootFilesystemPath(dirPath) &&
        !_rootAccessMode.usesSuperuser;
    return listDirectory(dirPath)
        .map((entity) => _mapFileSystemEntity(entity, probeAccess: probeAccess))
        .toList();
  }

  List<TreeBrowserNode> listTreeNodes(String tabId) {
    final tab = _tab(tabId);
    if (!supportsTreeView(tab)) return [];

    final expanded = _treeExpandedByTab.putIfAbsent(tabId, () => {});
    if (expanded.isEmpty) {
      unawaited(syncTreeExpansion(tabId));
      return [];
    }

    final current = _treeCurrentPath(tab);
    final result = <TreeBrowserNode>[];

    void walk(String parentPath, int depth) {
      final key = _treeCacheKey(tabId, parentPath);
      final children = _treeChildrenCache[key];
      final loading = _treeLoadingKeys.contains(key);

      if (children == null && !loading) {
        unawaited(_ensureTreeChildrenLoaded(tabId, parentPath));
        return;
      }
      if (children == null) return;

      for (final child in children) {
        final childPath = child.path;
        final isExp = expanded.contains(childPath);
        final childKey = _treeCacheKey(tabId, childPath);
        result.add(
          TreeBrowserNode(
            entry: child,
            depth: depth,
            isExpanded: isExp,
            hasChildren: child.isDirectory,
            isLoading: _treeLoadingKeys.contains(childKey),
            isCurrent: childPath == current,
          ),
        );
        if (child.isDirectory && isExp) {
          walk(childPath, depth + 1);
        }
      }
    }

    final root = _treeListRoot(tab);
    walk(root, 0);
    return result;
  }

  @Deprecated('Use setBrowserViewMode')
  Future<void> setGridView(bool value) async {
    await setBrowserViewMode(value ? BrowserViewMode.grid : BrowserViewMode.list);
  }

  Future<void> setOpenApkAsZip(bool value) async {
    if (_openApkAsZip == value) return;
    _openApkAsZip = value;
    try {
      const storage = FlutterSecureStorage();
      await storage.write(key: 'open_apk_as_zip', value: value ? 'true' : 'false');
    } catch (_) {}
    notifyListeners();
  }

  Future<String?> setRootAccessMode(RootAccessMode mode) async {
    if (_rootAccessMode == mode) return null;

    if (mode.usesSuperuser) {
      final check = await _shellListService.checkRootAccess(mode);
      if (!check.granted) {
        return check.message.isNotEmpty
            ? check.message
            : L10nScope.current.superuserNotGranted;
      }
    }

    _rootAccessMode = mode;
    _shellDirCache.clear();
    _shellErrors.clear();
    _dirAccessNotes.clear();
    try {
      const storage = FlutterSecureStorage();
      await storage.write(key: 'root_access_mode', value: mode.storageValue);
    } catch (_) {}
    if (mode == RootAccessMode.disabled) {
      for (final tab in _tabs) {
        if (tab.currentPath == '/' || ShellListService.isRootFilesystemPath(tab.currentPath)) {
          _setTab(
            tab.id,
            tab.copyWith(currentPath: '@home', clearSelection: true),
          );
        }
      }
    }
    notifyListeners();
    return null;
  }

  bool _isPermissionDenied(Object error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('permission denied') ||
        msg.contains('eacces') ||
        msg.contains('operation not permitted') ||
        msg.contains('truy cập bị từ chối');
  }

  void _setDirectoryAccessDenied(String path) {
    _dirAccessNotes[path] = L10nScope.current.accessDenied;
    _shellErrors.remove(path);
  }

  static String get entryAccessDeniedLabel => L10nScope.current.accessDenied;

  bool _probeEntryAccessDenied(String path, bool isDirectory) {
    if (!ShellListService.isRootFilesystemPath(path)) return false;
    try {
      if (isDirectory) {
        Directory(path).listSync(followLinks: false);
      } else {
        File(path).statSync();
      }
      return false;
    } on FileSystemException catch (e) {
      return _isPermissionDenied(e);
    } catch (_) {
      return true;
    }
  }

  BrowserEntry _mapListedEntry(ListedEntry entity, {bool probeAccess = false}) {
    final accessDenied = probeAccess && _probeEntryAccessDenied(entity.path, entity.isDirectory);
    int? childrenCount;
    if (entity.isDirectory && !accessDenied) {
      try {
        childrenCount = Directory(entity.path).listSync(followLinks: false).length;
      } catch (_) {}
    }
    return BrowserEntry(
      name: p.basename(entity.path),
      path: entity.path,
      isDirectory: entity.isDirectory,
      size: entity.size,
      childrenCount: childrenCount,
      accessDenied: accessDenied,
    );
  }

  BrowserEntry _mapFileSystemEntity(FileSystemEntity entity, {bool probeAccess = false}) {
    final isDir = entity is Directory;
    final accessDenied = probeAccess && _probeEntryAccessDenied(entity.path, isDir);
    int? size;
    if (entity is File && !accessDenied) {
      try {
        size = entity.statSync().size;
      } catch (_) {}
    }
    int? childrenCount;
    if (isDir && !accessDenied) {
      try {
        childrenCount = listDirectory(entity.path).length;
      } catch (_) {
        childrenCount = 0;
      }
    }
    return BrowserEntry(
      name: p.basename(entity.path),
      path: entity.path,
      isDirectory: isDir,
      size: size,
      childrenCount: childrenCount,
      accessDenied: accessDenied,
    );
  }

  // ── Permissions ──────────────────────────────────────────────

  Future<void> initPermissions() async {
    _permissionChecked = true;

    try {
      const storage = FlutterSecureStorage();
      await _loadAppSettings(storage);
      final saved = await storage.read(key: 'show_hidden');
      _showHidden = saved == 'true';
      final savedMode = await storage.read(key: 'browser_view_mode');
      final savedGrid = await storage.read(key: 'is_grid_view');
      _browserViewMode = BrowserViewMode.fromStorage(
        savedMode,
        legacyGrid: savedGrid == 'true',
      );
      final savedOpenApkAsZip = await storage.read(key: 'open_apk_as_zip');
      _openApkAsZip = savedOpenApkAsZip != 'false';
      final savedRootMode = await storage.read(key: 'root_access_mode');
      _rootAccessMode = RootAccessModeLabels.fromStorage(savedRootMode);
      if (_rootAccessMode.usesSuperuser) {
        final check = await _shellListService.checkRootAccess(_rootAccessMode);
        if (!check.granted) {
          _rootAccessMode = RootAccessMode.normal;
          await storage.write(
            key: 'root_access_mode',
            value: RootAccessMode.normal.storageValue,
          );
          _log(
            check.message.isNotEmpty
                ? check.message
                : L10nScope.current.superuserRevertedNormal,
          );
        }
      }
      await _tryRestoreSession();
    } catch (_) {}

    await loadFtpServers();

    if (kIsWeb || Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      _storageGranted = true;
      _ensureInitialTab();
      _scheduleBackgroundDataPrefetch();
      notifyListeners();
      return;
    }

    if (Platform.isAndroid) {
      _storageGranted = await _permissionService.hasManageExternalStorage();
      final prefs = await SharedPreferences.getInstance();
      final onboardingDone = prefs.getBool(OnboardingProvider.storageKey) ?? false;
      if (!_storageGranted && onboardingDone) {
        await _onboarding?.reopenForPermissions();
      } else if (_storageGranted) {
        _ensureInitialTab();
      }
    } else {
      _storageGranted = true;
      _ensureInitialTab();
    }
    if (_storageGranted) {
      _scheduleBackgroundDataPrefetch();
    }
    notifyListeners();
  }

  Future<void> recheckPermissions() async {
    if (!Platform.isAndroid) return;
    final wasGranted = _storageGranted;
    _storageGranted = await _permissionService.hasManageExternalStorage();
    if (wasGranted && !_storageGranted) {
      await _onboarding?.reopenForPermissions();
    } else if (!wasGranted && _storageGranted) {
      _log(L10nScope.current.logGrantedAllFilesAccess);
      invalidateHomeEntries();
      _ensureInitialTab();
      _scheduleBackgroundDataPrefetch();
    }
    notifyListeners();
  }

  Future<PermissionResult> requestManageExternalStorage() async {
    await _permissionService.requestManageExternalStorage();
    _storageGranted = await _permissionService.hasManageExternalStorage();
    _permissionChecked = true;
    if (_storageGranted) {
      _log(L10nScope.current.logGrantedAllFilesAccess);
      invalidateHomeEntries();
      _ensureInitialTab();
      _scheduleBackgroundDataPrefetch();
    } else {
      _log(L10nScope.current.logEnableManageAllFiles);
    }
    notifyListeners();
    return _storageGranted ? PermissionResult.granted : PermissionResult.denied;
  }

  Future<void> openAllFilesAccessSettings() =>
      _permissionService.openAllFilesAccessSettings();

  void onOnboardingComplete() {
    _ensureInitialTab();
    if (_storageGranted) {
      _scheduleBackgroundDataPrefetch();
    }
    notifyListeners();
  }

  void _ensureInitialTab() {
    if (_tabs.isNotEmpty) return;
    final tab = AppTab(currentPath: '@home');
    _tabs.add(tab);
    _activeTabId = tab.id;
  }

  // ── Tabs ───────────────────────────────────────────────────

  void newTab({String? path}) {
    final browsePath = path ?? '@home';
    final tab = AppTab(currentPath: browsePath);
    _tabs.add(tab);
    _activeTabId = tab.id;
    _log(L10nScope.current.logNewTab(PathUtils.displayName(browsePath)));
    notifyListeners();
    unawaited(saveSessionState());
  }

  void openZipInNewTab(String zipPath, {String innerPath = ''}) {
    final tab = AppTab(
      currentPath: zipPath,
      mode: TabMode.zipViewer,
      zipArchivePath: zipPath,
      zipInnerPath: innerPath,
    );
    _tabs.add(tab);
    _activeTabId = tab.id;
    _log(L10nScope.current.logNewTab(tab.displayName));
    notifyListeners();
    unawaited(saveSessionState());
  }

  void closeTab(String tabId) {
    _cancelFileOperationIfActive(tabId);
    final index = _tabIndex(tabId);
    if (index == -1) return;
    _tabs.removeAt(index);
    if (_activeTabId == tabId) {
      _activeTabId = _tabs.isEmpty ? null : _tabs[index.clamp(0, _tabs.length - 1)].id;
    }
    if (_tabs.isEmpty && _storageGranted) {
      _ensureInitialTab();
    }
    _treeExpandedByTab.remove(tabId);
    _invalidateTreeCache(tabId: tabId);
    notifyListeners();
    unawaited(saveSessionState());
  }

  void activateTab(String tabId) {
    if (_tabs.any((t) => t.id == tabId)) {
      _activeTabId = tabId;
      notifyListeners();
    }
  }

  // ── Browser navigation (per tab) ─────────────────────────

  Future<void> navigateTo(String tabId, String path) async {
    _cancelFileOperationIfActive(tabId);
    final virtualPath = path.startsWith('@');
    _setTab(
      tabId,
      _tab(tabId).copyWith(
        currentPath: path,
        mode: TabMode.browser,
        clearEditor: true,
        clearSelection: true,
        clearZip: true,
        searchQuery: virtualPath ? '' : null,
        showSearch: virtualPath ? false : null,
      ),
    );
    if (path == '@recent') {
      if (_recentFiles.isNotEmpty) {
        unawaited(_refreshRecentInBackground(showLoadingIfEmpty: false, tabId: tabId));
      } else {
        await _refreshRecentInBackground(tabId: tabId);
      }
    } else if (path == '@home') {
      if (_homeEntriesCache == null) {
        await _loadHomeEntries(tabId: tabId);
      }
    } else if (AppPathUtils.isAppsList(path)) {
      final cacheKey = AppPathUtils.isSystemList(path) ? 'system' : 'user';
      if ((_appsCache[cacheKey]?.isNotEmpty ?? false)) {
        unawaited(_refreshAppsForView(path, tabId: tabId, showLoadingIfEmpty: false));
      } else {
        await _refreshAppsForView(path, tabId: tabId);
      }
    } else if (ShellListService.shouldUseShell(path, mode: _rootAccessMode)) {
      await _loadShellDirectory(tabId, path);
    } else {
      _dirAccessNotes.remove(path);
      if (ShellListService.isRootFilesystemPath(path)) {
        try {
          listDirectory(path);
        } on FileAccessException catch (e) {
          if (_isPermissionDenied(e)) {
            _setDirectoryAccessDenied(path);
          }
        }
      }
      _log(PathUtils.displayName(path));
    }
    if (path == '@recent' || AppPathUtils.isAppsList(path)) {
      _log(PathUtils.displayName(path));
    }
    notifyListeners();
    if (_browserViewMode == BrowserViewMode.tree) {
      unawaited(syncTreeExpansion(tabId));
    }
    unawaited(saveSessionState());
  }

  Future<void> revealFileLocation(String tabId, String filePath) async {
    final parent = PathUtils.parentPath(filePath);
    if (parent == null) return;
    await navigateTo(tabId, parent);
    _log(L10nScope.current.logFileLocation(PathUtils.shortDisplayDir(filePath)));
  }

  void navigateUp(String tabId) {
    _cancelFileOperationIfActive(tabId);
    final tab = _tab(tabId);
    if (tab.isEditing) {
      closeEditorInTab(tabId);
      return;
    }
    if (tab.isZipViewer) {
      navigateZipUp(tabId);
      return;
    }

    if (tab.currentPath == '@ftp' || tab.currentPath == '@recent' || tab.currentPath == '@apps') {
      navigateTo(tabId, '@home');
      return;
    }

    if (AppPathUtils.isAppsList(tab.currentPath)) {
      navigateTo(tabId, '@apps');
      return;
    }

    if (tab.currentPath.startsWith('@ftp/')) {
      final inner = tab.currentPath.substring(5);
      final parts = inner.split('/');
      if (parts.length <= 1) {
        navigateTo(tabId, '@ftp');
      } else {
        parts.removeLast();
        navigateTo(tabId, '@ftp/${parts.join('/')}');
      }
      return;
    }

    if (tab.currentPath == '/storage/emulated/0' || tab.currentPath == '/' || tab.currentPath == '@home' || PathUtils.parentPath(tab.currentPath) == null) {
      navigateTo(tabId, '@home');
      return;
    }

    final parent = PathUtils.parentPath(tab.currentPath);
    if (parent != null) navigateTo(tabId, parent);
  }

  Future<void> openZipView(String tabId, String zipPath) async {
    _zipErrors.remove(zipPath);
    _archiveService.clearZipCache(zipPath);
    _zipListCache.removeWhere((k, _) => k.startsWith('$zipPath|'));
    _setTab(
      tabId,
      _tab(tabId).copyWith(
        mode: TabMode.zipViewer,
        zipArchivePath: zipPath,
        zipInnerPath: '',
        clearEditor: true,
        clearSelection: true,
      ),
    );
    _log(L10nScope.current.logViewZip(p.basename(zipPath)));
    notifyListeners();

    final l10n = L10nScope.current;
    try {
      final protected = await _archiveService.isPasswordProtected(zipPath);
      if (protected && !_zipPasswords.containsKey(zipPath)) {
        _zipErrors[zipPath] = l10n.zipPasswordProtected;
        notifyListeners();
      }
    } catch (e) {
      _zipErrors[zipPath] = l10n.cannotReadPath(p.basename(zipPath));
      notifyListeners();
    }
  }

  void navigateZipInner(String tabId, String innerPath) {
    _setTab(
      tabId,
      _tab(tabId).copyWith(zipInnerPath: innerPath, clearSelection: true),
    );
    notifyListeners();
    if (_browserViewMode == BrowserViewMode.tree) {
      unawaited(syncTreeExpansion(tabId));
    }
  }

  void navigateZipUp(String tabId) {
    final tab = _tab(tabId);
    if (!tab.isZipViewer || tab.zipArchivePath == null) return;

    if (tab.zipInnerPath.isEmpty) {
      final zipPath = tab.zipArchivePath!;
      final parent = p.dirname(zipPath);
      _setTab(
        tabId,
        tab.copyWith(
          mode: TabMode.browser,
          currentPath: parent,
          clearZip: true,
          clearSelection: true,
        ),
      );
      _log(PathUtils.displayName(parent));
    } else {
      final parent = p.dirname(tab.zipInnerPath);
      final newInner = parent == '.' ? '' : parent;
      _setTab(tabId, tab.copyWith(zipInnerPath: newInner, clearSelection: true));
    }
    notifyListeners();
  }

  void setSearchQuery(String tabId, String query) {
    _setTab(tabId, _tab(tabId).copyWith(searchQuery: query));
    notifyListeners();
  }

  bool isSelectable(String tabId, BrowserEntry entry) {
    final tab = _tab(tabId);
    final currentPath = tab.currentPath;
    if (currentPath == '@home' || currentPath == '@apps' || currentPath == '@ftp') {
      return false;
    }
    if (entry.path == '@add_ftp_server' || entry.path == '@display') {
      return false;
    }
    return true;
  }

  void selectAll(String tabId) {
    final tab = _tab(tabId);
    final entries = listEntriesForTab(tabId);
    final selectablePaths = entries
        .where((e) => isSelectable(tabId, e))
        .map((e) => e.path)
        .toSet();
    _setTab(tabId, tab.copyWith(selectedPaths: selectablePaths));
    notifyListeners();
  }

  void toggleSelection(String tabId, String path) {
    final tab = _tab(tabId);
    final currentPath = tab.currentPath;
    if (currentPath == '@home' || currentPath == '@apps' || currentPath == '@ftp') {
      return;
    }
    if (path == '@add_ftp_server' || path == '@display') {
      return;
    }
    final norm = _norm(path);
    final next = <String>{};
    var removed = false;
    for (final p in tab.selectedPaths) {
      if (_norm(p) == norm) {
        removed = true;
      } else {
        next.add(p);
      }
    }
    if (!removed) next.add(path);
    _setTab(tabId, tab.copyWith(selectedPaths: next));
    notifyListeners();
  }

  void clearSelection(String tabId) {
    _setTab(tabId, _tab(tabId).copyWith(clearSelection: true));
    notifyListeners();
  }

  bool isSelected(String tabId, String path) {
    final norm = _norm(path);
    return _tab(tabId).selectedPaths.any((p) => _norm(p) == norm);
  }

  List<String> getSelectedPaths(String tabId) {
    final tab = _tab(tabId);
    if (tab.isZipViewer && tab.zipArchivePath != null) {
      return tab.selectedPaths.map((p) => 'zip://${tab.zipArchivePath}::$p').toList();
    }
    return tab.selectedPaths.toList();
  }

  List<BrowserEntry> _getAppsHomeEntries() {
    final l10n = L10nScope.current;
    return [
      BrowserEntry(
        name: l10n.systemApps,
        path: AppPathUtils.systemListPath,
        isDirectory: true,
        subtitle: l10n.systemApp,
        isVirtual: true,
      ),
      BrowserEntry(
        name: l10n.userApps,
        path: AppPathUtils.userListPath,
        isDirectory: true,
        subtitle: l10n.userApp,
        isVirtual: true,
      ),
    ];
  }

  List<BrowserEntry> _getInstalledAppsEntries(String listPath) {
    final l10n = L10nScope.current;
    final cacheKey = AppPathUtils.isSystemList(listPath) ? 'system' : 'user';
    final apps = _appsCache[cacheKey] ?? [];
    return apps
        .map(
          (app) => BrowserEntry(
            name: app.appName,
            path: app.packageName,
            isDirectory: false,
            size: app.apkSize,
            subtitle: '${app.versionName.isNotEmpty ? 'v${app.versionName}' : 'v${app.versionCode}'} · ${_formatSize(app.apkSize)} · ${app.isSystem ? l10n.systemApp : l10n.userApp}',
            isVirtual: true,
            iconBytes: _appIcons[app.packageName],
          ),
        )
        .toList();
  }

  static String _formatSize(int size) {
    if (size <= 0) return '0 B';
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  void _scheduleAfterFrame(void Function() action) {
    SchedulerBinding.instance.addPostFrameCallback((_) => action());
  }

  void _scheduleShellLoad(String tabId, String path) {
    if (_shellLoadingPaths.contains(path)) return;
    if (_shellDirCache.containsKey(path)) {
      _setTab(tabId, _tab(tabId).bumpList());
      notifyListeners();
      return;
    }
    _scheduleAfterFrame(() => unawaited(_loadShellDirectory(tabId, path)));
  }

  void _scheduleAppsRefresh(String tabId, String listPath) {
    final cacheKey = AppPathUtils.isSystemList(listPath) ? 'system' : 'user';
    if (_appsLoadingKeys.contains(cacheKey)) return;
    _scheduleAfterFrame(() => unawaited(_refreshAppsForView(listPath, tabId: tabId, showLoadingIfEmpty: false)));
  }

  void _scheduleBackgroundDataPrefetch() {
    if (!_storageGranted) return;
    unawaited(_refreshRecentInBackground(showLoadingIfEmpty: false));
    if (Platform.isAndroid) {
      unawaited(_refreshAppsForView(AppPathUtils.systemListPath, showLoadingIfEmpty: false));
      unawaited(_refreshAppsForView(AppPathUtils.userListPath, showLoadingIfEmpty: false));
    }
  }

  String _recentPathKey(String path) {
    final normalized = p.normalize(path);
    return Platform.isWindows ? normalized.toLowerCase() : normalized;
  }

  int _mergeRecentResults(List<RecentFileEntry> scanned) {
    if (_recentFiles.isEmpty) {
      _recentFiles.addAll(scanned);
      return scanned.length;
    }

    final known = _recentFiles.map((e) => _recentPathKey(e.path)).toSet();
    var added = 0;
    for (final entry in scanned) {
      if (known.add(_recentPathKey(entry.path))) {
        _recentFiles.add(entry);
        added++;
      }
    }
    if (added > 0) {
      _recentFiles.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
      if (_recentFiles.length > RecentFilesScanner.maxResults) {
        _recentFiles.removeRange(RecentFilesScanner.maxResults, _recentFiles.length);
      }
    }
    return added;
  }

  int _mergeAppsResults(String cacheKey, List<InstalledAppInfo> scanned) {
    final existing = _appsCache[cacheKey];
    if (existing == null || existing.isEmpty) {
      final sorted = List<InstalledAppInfo>.from(scanned)
        ..sort((a, b) => a.appName.toLowerCase().compareTo(b.appName.toLowerCase()));
      _appsCache[cacheKey] = sorted;
      return scanned.length;
    }

    final known = existing.map((a) => a.packageName).toSet();
    var added = 0;
    for (final app in scanned) {
      if (known.add(app.packageName)) {
        existing.add(app);
        added++;
      }
    }
    if (added > 0) {
      existing.sort((a, b) => a.appName.toLowerCase().compareTo(b.appName.toLowerCase()));
    }
    return added;
  }

  Future<void> _refreshRecentInBackground({
    bool showLoadingIfEmpty = true,
    String? tabId,
  }) async {
    if (_recentScanInProgress) return;
    _recentScanInProgress = true;

    final generation = ++_recentScanGeneration;
    final showSpinner = showLoadingIfEmpty && _recentFiles.isEmpty;
    if (showSpinner) {
      _recentLoading = true;
      notifyListeners();
    }

    try {
      final roots = StorageRoots.discover(_permissionService);
      final results = await RecentFilesScanner.scan(
        roots: roots,
        showHidden: _showHidden,
      );
      if (generation != _recentScanGeneration) return;
      final added = _mergeRecentResults(results);
      if (added > 0) {
        _log(L10nScope.current.logRecentAdded(added));
      } else if (_recentFiles.isEmpty && results.isNotEmpty) {
        _log(L10nScope.current.logRecentScanned(results.length));
      }
    } catch (e) {
      if (generation == _recentScanGeneration) {
        _log(L10nScope.current.logRecentScanError('$e'));
      }
    } finally {
      _recentScanInProgress = false;
      if (generation == _recentScanGeneration) {
        _recentLoading = false;
        if (tabId != null) _setTab(tabId, _tab(tabId).bumpList());
        notifyListeners();
      }
    }
  }

  Future<void> _refreshAppsForView(
    String listPath, {
    String? tabId,
    bool showLoadingIfEmpty = true,
  }) async {
    await Future<void>.delayed(Duration.zero);

    final cacheKey = AppPathUtils.isSystemList(listPath) ? 'system' : 'user';
    if (_appsLoadingKeys.contains(cacheKey)) return;

    final generation = (_appsLoadGenerationByKey[cacheKey] ?? 0) + 1;
    _appsLoadGenerationByKey[cacheKey] = generation;

    final showSpinner = showLoadingIfEmpty && (_appsCache[cacheKey]?.isEmpty ?? true);
    if (showSpinner) {
      _appsLoadingKeys.add(cacheKey);
      _appsError = null;
      notifyListeners();
    }

    try {
      final apps = await _appManagerService.listApps(systemApps: cacheKey == 'system');
      if (generation != _appsLoadGenerationByKey[cacheKey]) return;
      final added = _mergeAppsResults(cacheKey, apps);
      if (added > 0) {
        final label = cacheKey == 'system' ? L10nScope.current.logAppsTypeSystem : L10nScope.current.logAppsTypeUser;
        _log(L10nScope.current.logAppsAdded(added, label));
        unawaited(_prefetchAppIcons(apps.map((a) => a.packageName).toList()));
      } else if (_appsCache[cacheKey]?.isEmpty ?? true) {
        _log(L10nScope.current.logAppsLoaded(apps.length));
        unawaited(_prefetchAppIcons(apps.map((a) => a.packageName).toList()));
      }
    } catch (e) {
      if (generation == _appsLoadGenerationByKey[cacheKey]) {
        _appsError = e.toString();
        _log(L10nScope.current.logAppsLoadError('$e'));
      }
    } finally {
      if (generation == _appsLoadGenerationByKey[cacheKey]) {
        _appsLoadingKeys.remove(cacheKey);
        if (tabId != null) _setTab(tabId, _tab(tabId).bumpList());
        notifyListeners();
      }
    }
  }

  Future<void> _prefetchAppIcons(List<String> packages) async {
    var changed = false;
    for (final package in packages) {
      if (_appIcons.containsKey(package)) continue;
      try {
        final bytes = await _appManagerService.getAppIcon(package);
        if (bytes != null && bytes.isNotEmpty) {
          _appIcons[package] = bytes;
          changed = true;
        }
      } catch (_) {}
    }
    if (changed) notifyListeners();
  }

  Future<void> ensureAppIcon(String packageName) async {
    if (_appIcons.containsKey(packageName)) return;
    try {
      final bytes = await _appManagerService.getAppIcon(packageName);
      if (bytes != null && bytes.isNotEmpty) {
        _appIcons[packageName] = bytes;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _loadShellDirectory(String tabId, String path) async {
    await Future<void>.delayed(Duration.zero);

    if (_shellDirCache.containsKey(path)) {
      _setTab(tabId, _tab(tabId).bumpList());
      notifyListeners();
      return;
    }
    if (_shellLoadingPaths.contains(path)) return;

    _shellLoadingPaths.add(path);
    _shellErrors.remove(path);
    _dirAccessNotes.remove(path);
    notifyListeners();

    try {
      final entries = await _shellListService.listDirectory(
        path,
        showHidden: _showHidden,
        rootMode: _rootAccessMode,
      );
      _shellDirCache[path] = entries
          .map((entity) => _mapListedEntry(
                entity,
                probeAccess: ShellListService.isRootFilesystemPath(path) &&
                    !_rootAccessMode.usesSuperuser,
              ))
          .toList();
      if (path == '/') {
        _log(L10nScope.current.logReadItemsRoot(entries.length));
      } else {
        _log(L10nScope.current.logReadItemsAt(entries.length, PathUtils.displayName(path)));
      }
    } catch (e) {
      if (_isPermissionDenied(e) && ShellListService.isRootFilesystemPath(path)) {
        _setDirectoryAccessDenied(path);
      } else {
        _shellErrors[path] = e.toString();
        _dirAccessNotes.remove(path);
        _log(L10nScope.current.logReadError(PathUtils.displayName(path), '$e'));
      }
    } finally {
      _shellLoadingPaths.remove(path);
      _setTab(tabId, _tab(tabId).bumpList());
      notifyListeners();
    }
  }

  Future<void> openAppInfo(String packageName) async {
    try {
      await _appManagerService.openAppSettings(packageName);
      _log(L10nScope.current.logOpenAppInfo);
      notifyListeners();
    } catch (e) {
      _log(L10nScope.current.logOpenAppInfoError('$e'));
      notifyListeners();
    }
  }

  Future<void> copyAppApk(String packageName) async {
    final app = getAppInfo(packageName);
    if (app == null) return;
    _setBusy(true);
    try {
      final path = await _appManagerService.resolveApkPath(app);
      copyToClipboard([path]);
      _log(L10nScope.current.logApkCopied(app.appName));
    } catch (e) {
      _log(L10nScope.current.logApkCopyError('$e'));
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  Future<void> shareAppApk(String packageName) async {
    final app = getAppInfo(packageName);
    if (app == null) return;
    _setBusy(true);
    try {
      await _appManagerService.shareApk(app);
      _log(L10nScope.current.logApkShared(app.appName));
    } catch (e) {
      _log(L10nScope.current.logApkShareError('$e'));
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  Future<void> openAppOnPlayStore(String packageName) async {
    try {
      await _appManagerService.openPlayStore(packageName);
    } catch (e) {
      _log(L10nScope.current.logPlayStoreError('$e'));
      notifyListeners();
    }
  }

  Future<void> backupAppApk(String packageName) async {
    final app = getAppInfo(packageName);
    if (app == null) return;
    _setBusy(true);
    try {
      final path = await _appManagerService.backupApk(app);
      _log(L10nScope.current.logApkBackup(path));
      notifyListeners();
    } catch (e) {
      _log(L10nScope.current.logApkBackupError('$e'));
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  Future<void> uninstallApp(String packageName) async {
    final app = getAppInfo(packageName);
    _setBusy(true);
    try {
      await _appManagerService.uninstallApp(packageName);
      _log(L10nScope.current.logUninstall(app?.appName ?? packageName));
    } catch (e) {
      _log(L10nScope.current.logUninstallError('$e'));
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  Future<void> openSelectedApp(String packageName) async {
    _setBusy(true);
    try {
      await _appManagerService.openApp(packageName);
      _log(L10nScope.current.logLaunchApp(packageName));
      notifyListeners();
    } catch (e) {
      _log(L10nScope.current.logOpenAppError('$e'));
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  Future<void> uninstallSelectedApp(String packageName) async {
    await uninstallApp(packageName);
  }

  Future<void> extractAppApk(String packageName) async {
    await backupAppApk(packageName);
  }

  String _storageSubtitle(String path) {
    final space = getDiskSpace(path);
    final l10n = L10nScope.current;
    return space != null ? l10n.storageFreeSlash(space['free']!, space['total']!) : path;
  }

  /// Đường dẫn dùng `df` — Root (`/`) lấy theo bộ nhớ trong, không phải partition hệ thống.
  String diskSpacePathFor(String entryPath) {
    if (entryPath == '/') {
      return _internalStoragePath ?? StorageRoots.defaultRoot(_permissionService);
    }
    return entryPath;
  }

  Future<List<BrowserEntry>> _buildHomeEntries() async {
    final l10n = L10nScope.current;
    final volumes = await StorageRoots.discoverHomeVolumes(_permissionService);
    final entries = <BrowserEntry>[];
    final removable = volumes.where((v) => v.isRemovable).toList();
    HomeStorageVolume? internalVolume;
    for (final volume in volumes) {
      if (!volume.isRemovable) {
        internalVolume = volume;
        break;
      }
    }
    _internalStoragePath = internalVolume?.path ?? StorageRoots.defaultRoot(_permissionService);

    for (final volume in volumes) {
      if (volume.isRemovable) {
        final name = removable.length > 1
            ? '${l10n.shortcutSdCard} (${volume.volumeId ?? p.basename(volume.path)})'
            : l10n.shortcutSdCard;
        entries.add(
          BrowserEntry(
            name: name,
            path: volume.path,
            isDirectory: true,
            subtitle: _storageSubtitle(volume.path),
            isVirtual: true,
          ),
        );
      } else {
        entries.add(
          BrowserEntry(
            name: l10n.deviceStorage,
            path: volume.path,
            isDirectory: true,
            subtitle: _storageSubtitle(volume.path),
            isVirtual: true,
          ),
        );
      }
    }

    if (_rootAccessMode != RootAccessMode.disabled) {
      entries.add(
        BrowserEntry(
          name: 'Root',
          path: '/',
          isDirectory: true,
          subtitle: _storageSubtitle(_internalStoragePath!),
          isVirtual: true,
        ),
      );
    }

    entries.addAll([
      BrowserEntry(
        name: l10n.shortcutRecent,
        path: '@recent',
        isDirectory: true,
        isVirtual: true,
      ),
      BrowserEntry(
        name: l10n.shortcutApps,
        path: '@apps',
        isDirectory: true,
        subtitle: l10n.shortcutSystemAppsSubtitle,
        isVirtual: true,
      ),
      BrowserEntry(
        name: l10n.shortcutFtp,
        path: '@ftp',
        isDirectory: true,
        isVirtual: true,
      ),
    ]);

    return entries;
  }

  Future<void> _loadHomeEntries({String? tabId}) async {
    if (_homeEntriesLoading) return;

    final generation = ++_homeLoadGeneration;
    _homeEntriesLoading = true;
    notifyListeners();

    try {
      _homeEntriesCache = await _buildHomeEntries();
    } catch (e) {
      if (generation == _homeLoadGeneration) {
        _log(L10nScope.current.logHomeLoadError('$e'));
        final l10n = L10nScope.current;
        _homeEntriesCache ??= [
          BrowserEntry(
            name: l10n.deviceStorage,
            path: StorageRoots.defaultRoot(_permissionService),
            isDirectory: true,
            subtitle: StorageRoots.defaultRoot(_permissionService),
            isVirtual: true,
          ),
          if (_rootAccessMode != RootAccessMode.disabled)
            BrowserEntry(
              name: 'Root',
              path: '/',
              isDirectory: true,
              subtitle: _storageSubtitle(
                _internalStoragePath ?? StorageRoots.defaultRoot(_permissionService),
              ),
              isVirtual: true,
            ),
          BrowserEntry(
            name: l10n.shortcutRecent,
            path: '@recent',
            isDirectory: true,
            isVirtual: true,
          ),
          BrowserEntry(
            name: l10n.shortcutApps,
            path: '@apps',
            isDirectory: true,
            subtitle: l10n.shortcutSystemAppsSubtitle,
            isVirtual: true,
          ),
          BrowserEntry(
            name: l10n.shortcutFtp,
            path: '@ftp',
            isDirectory: true,
            isVirtual: true,
          ),
        ];
      }
    } finally {
      if (generation == _homeLoadGeneration) {
        _homeEntriesLoading = false;
        if (tabId != null) _setTab(tabId, _tab(tabId).bumpList());
        notifyListeners();
      }
    }
  }

  void _scheduleHomeLoad(String tabId) {
    if (_homeEntriesCache != null) {
      _setTab(tabId, _tab(tabId).bumpList());
      notifyListeners();
      return;
    }
    if (_homeEntriesLoading) return;
    _scheduleAfterFrame(() => unawaited(_loadHomeEntries(tabId: tabId)));
  }

  void invalidateHomeEntries() {
    _homeEntriesCache = null;
  }

  String _recentSubtitle(RecentFileEntry entry) {
    final when = DateFormat('dd/MM/yyyy HH:mm').format(entry.modifiedAt);
    final dir = PathUtils.shortDisplayDir(entry.path);
    return '$dir · $when';
  }

  List<BrowserEntry> _getRecentEntries() {
    return _recentFiles
        .map(
          (recent) => BrowserEntry(
            name: p.basename(recent.path),
            path: recent.path,
            isDirectory: false,
            size: recent.size,
            subtitle: _recentSubtitle(recent),
          ),
        )
        .toList();
  }

  List<BrowserEntry> _getFtpServersEntries() {
    final l10n = L10nScope.current;
    final list = <BrowserEntry>[];
    list.add(
      BrowserEntry(
        name: l10n.shortcutAddFtp,
        path: '@add_ftp_server',
        isDirectory: false,
        isVirtual: true,
      ),
    );
    for (final server in _ftpServers) {
      list.add(
        BrowserEntry(
          name: server.name,
          path: '@ftp/${server.id}',
          isDirectory: true,
          isVirtual: true,
          subtitle: '${server.username}@${server.host}:${server.port}',
        ),
      );
    }
    return list;
  }

  Map<String, String>? getDiskSpace(String path) {
    try {
      if (Platform.isAndroid || Platform.isLinux || Platform.isMacOS) {
        final res = Process.runSync('df', ['-k', path]);
        if (res.exitCode == 0) {
          final lines = res.stdout.toString().split('\n');
          if (lines.length > 1) {
            final parts = lines[1].trim().split(RegExp(r'\s+'));
            if (parts.length >= 4) {
              final totalKb = int.tryParse(parts[1]) ?? 0;
              final usedKb = int.tryParse(parts[2]) ?? 0;
              final freeKb = int.tryParse(parts[3]) ?? 0;
              if (totalKb > 0) {
                final totalGb = (totalKb / (1024 * 1024)).toStringAsFixed(1);
                final freeGb = (freeKb / (1024 * 1024)).toStringAsFixed(1);
                final pct = (usedKb / totalKb * 100).toInt();
                return {'total': '${totalGb}GB', 'free': '${freeGb}GB', 'percent': '$pct'};
              }
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> loadFtpServers() async {
    try {
      const storage = FlutterSecureStorage();
      final listJson = await storage.read(key: 'ftp_servers');
      if (listJson != null) {
        final list = jsonDecode(listJson) as List;
        _ftpServers.clear();
        _ftpServers.addAll(list.map((item) => FtpServerConfig.fromMap(item as Map<String, dynamic>)));
      }
    } catch (_) {}
    notifyListeners();
  }

  Future<void> saveFtpServers() async {
    try {
      const storage = FlutterSecureStorage();
      final listJson = jsonEncode(_ftpServers.map((s) => s.toMap()).toList());
      await storage.write(key: 'ftp_servers', value: listJson);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> addFtpServer(FtpServerConfig server) async {
    _ftpServers.add(server);
    await saveFtpServers();
  }

  FtpServerConfig? getFtpServer(String id) {
    for (final server in _ftpServers) {
      if (server.id == id) return server;
    }
    return null;
  }

  Future<void> updateFtpServer(FtpServerConfig server) async {
    final index = _ftpServers.indexWhere((s) => s.id == server.id);
    if (index == -1) return;
    _ftpServers[index] = server;
    _ftpCache.removeWhere((key, _) => key.startsWith('@ftp/${server.id}'));
    await saveFtpServers();
  }

  Future<void> removeFtpServer(String id) async {
    _ftpServers.removeWhere((s) => s.id == id);
    _ftpCache.removeWhere((key, _) => key.startsWith('@ftp/$id'));
    await saveFtpServers();
  }

  (String, String) _parseFtpPath(String path) {
    final inner = path.substring(5); // remove "@ftp/"
    final firstSlash = inner.indexOf('/');
    if (firstSlash == -1) {
      return (inner, '/');
    }
    final serverId = inner.substring(0, firstSlash);
    var remotePath = inner.substring(firstSlash);
    if (!remotePath.startsWith('/')) {
      remotePath = '/$remotePath';
    }
    return (serverId, remotePath);
  }

  Future<FtpClient> _connectFtp(String serverId) async {
    final server = _ftpServers.firstWhere((s) => s.id == serverId);
    final client = FtpClient(
      socketInitOptions: FtpSocketInitOptions(
        host: server.host,
        port: server.port,
      ),
      authOptions: FtpAuthOptions(
        username: server.username,
        password: server.password,
      ),
    );
    await client.connect().timeout(const Duration(seconds: 10));
    return client;
  }

  bool _isFtpDirectory(String path) {
    final parentPath = p.dirname(path).replaceAll('\\', '/');
    final cache = _ftpCache[parentPath] ?? [];
    final name = p.basename(path);
    final entry = cache.where((e) => e.name == name).firstOrNull;
    return entry?.isDirectory ?? false;
  }

  String _uniqueFtpName(String dirPath, String baseName) {
    final entries = _ftpCache[dirPath] ?? [];
    final names = entries.map((e) => e.name).toSet();
    var candidate = baseName;
    var counter = 1;
    while (names.contains(candidate)) {
      final ext = p.extension(baseName);
      final nameWithoutExt = p.basenameWithoutExtension(baseName);
      candidate = ext.isEmpty
          ? '$nameWithoutExt ($counter)'
          : '$nameWithoutExt ($counter)$ext';
      counter++;
    }
    return candidate;
  }

  Future<void> loadFtpEntries(String tabId, String serverId, String remotePath) async {
    final cacheKey = remotePath.isEmpty ? '@ftp/$serverId' : '@ftp/$serverId/$remotePath';
    if (_ftpLoadingPaths.contains(cacheKey)) return;
    _ftpLoadingPaths.add(cacheKey);

    Future.microtask(() => notifyListeners());

    final server = _ftpServers.firstWhere((s) => s.id == serverId);
    final client = FtpClient(
      socketInitOptions: FtpSocketInitOptions(
        host: server.host,
        port: server.port,
      ),
      authOptions: FtpAuthOptions(
        username: server.username,
        password: server.password,
      ),
    );

    try {
      await client.connect().timeout(const Duration(seconds: 15));
      if (remotePath.isNotEmpty) {
        final ftpPath = remotePath.startsWith('/') ? remotePath : '/$remotePath';
        await client.fs.changeDirectory(ftpPath);
      }
      final list = await client.fs.listDirectory();
      
      final entries = <BrowserEntry>[];
      for (final item in list) {
        final isDir = item is FtpDirectory;
        final name = item.name;

        if (!_showHidden && (name.startsWith('.') || name == 'Thumbs.db' || name == 'desktop.ini')) {
          continue;
        }

        entries.add(
          BrowserEntry(
            name: name,
            path: '@ftp/$serverId/${p.join(remotePath, name).replaceAll('\\', '/')}',
            isDirectory: isDir,
            size: item.info?.size,
            isVirtual: true,
          ),
        );
      }

      entries.sort((a, b) {
        if (a.isDirectory != b.isDirectory) return a.isDirectory ? -1 : 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      _ftpCache[cacheKey] = entries;
      _ftpErrors.remove(cacheKey);
    } catch (e) {
      _ftpErrors[cacheKey] = _formatFtpError(e);
      _log(L10nScope.current.logFtpError('$e'));
    } finally {
      try {
        await client.disconnect();
      } catch (_) {}
      _ftpLoadingPaths.remove(cacheKey);
      _setTab(tabId, _tab(tabId).bumpList());
      notifyListeners();
    }
  }

  String _formatFtpError(Object error) {
    final l10n = L10nScope.current;
    final msg = error.toString();
    if (msg.contains('Failed host lookup') ||
        msg.contains('No address associated with hostname') ||
        msg.contains('TimeoutException') ||
        msg.contains('timed out') ||
        msg.contains('Connection refused')) {
      return l10n.ftpConnectionError;
    }
    return msg;
  }

  void _scheduleZipListing(String tabId, String zipPath, String innerPath) {
    final pwd = _zipPasswords[zipPath];
    final key = _zipListKey(zipPath, innerPath, pwd);
    if (_zipListLoading.contains(key) || _zipListCache.containsKey(key)) return;

    _scheduleAfterFrame(() => unawaited(_loadZipListing(tabId, zipPath, innerPath)));
  }

  Future<void> _loadZipListing(String tabId, String zipPath, String innerPath) async {
    await Future<void>.delayed(Duration.zero);

    final pwd = _zipPasswords[zipPath];
    final key = _zipListKey(zipPath, innerPath, pwd);
    if (_zipListLoading.contains(key) || _zipListCache.containsKey(key)) return;

    _zipListLoading.add(key);
    notifyListeners();

    try {
      final l10n = L10nScope.current;
      final items = await _archiveService.listZipContents(zipPath, innerPath, password: pwd);
      if (items.isEmpty) {
        _zipErrors[zipPath] = l10n.cannotReadPath(p.basename(zipPath));
      } else {
        _zipListCache[key] = items;
        _zipErrors.remove(zipPath);
      }
    } catch (e) {
      final l10n = L10nScope.current;
      final errorMsg = e is ArchivePasswordException
          ? e.toString()
          : l10n.cannotReadPath(p.basename(zipPath));
      if (e is ArchivePasswordException) {
        _zipPasswords.remove(zipPath);
      }
      _zipErrors[zipPath] = errorMsg;
      _log(L10nScope.current.logZipReadError('$e'));
    } finally {
      _zipListLoading.remove(key);
      _setTab(tabId, _tab(tabId).bumpList());
      notifyListeners();
    }
  }

  List<BrowserEntry> listEntriesForTab(String tabId) {
    final tab = _tab(tabId);
    List<BrowserEntry> items;

    if (tab.currentPath == '@home') {
      if (_homeEntriesCache != null) {
        items = _homeEntriesCache!;
      } else {
        _scheduleHomeLoad(tabId);
        return [];
      }
    } else if (tab.currentPath == '@recent') {
      items = _getRecentEntries();
    } else if (tab.currentPath == '@apps') {
      items = _getAppsHomeEntries();
    } else if (AppPathUtils.isAppsList(tab.currentPath)) {
      items = _getInstalledAppsEntries(tab.currentPath);
      if (items.isEmpty && !isAppsListLoading(tab.currentPath) && _appsError == null) {
        _scheduleAppsRefresh(tabId, tab.currentPath);
      }
    } else if (tab.currentPath == '@ftp') {
      items = _getFtpServersEntries();
    } else if (tab.currentPath.startsWith('@ftp/')) {
      final inner = tab.currentPath.substring(5);
      final parts = inner.split('/');
      final serverId = parts[0];
      final remotePath = parts.sublist(1).join('/');
      
      final cacheKey = tab.currentPath;
      if (_ftpCache.containsKey(cacheKey)) {
        items = _ftpCache[cacheKey]!;
      } else if (_ftpErrors.containsKey(cacheKey)) {
        items = [];
      } else {
        loadFtpEntries(tabId, serverId, remotePath);
        return [];
      }
    } else if (tab.isZipViewer && tab.zipArchivePath != null) {
      final zipPath = tab.zipArchivePath!;
      if (_zipErrors.containsKey(zipPath)) {
        return [];
      }
      final pwd = _zipPasswords[zipPath];
      final key = _zipListKey(zipPath, tab.zipInnerPath, pwd);
      if (_zipListCache.containsKey(key)) {
        items = _zipListCache[key]!;
      } else {
        _scheduleZipListing(tabId, zipPath, tab.zipInnerPath);
        return [];
      }
    } else {
      try {
        if (ShellListService.shouldUseShell(tab.currentPath, mode: _rootAccessMode)) {
          if (_shellDirCache.containsKey(tab.currentPath)) {
            items = _shellDirCache[tab.currentPath]!;
          } else {
            _scheduleShellLoad(tabId, tab.currentPath);
            return [];
          }
        } else {
          if (_dirAccessNotes.containsKey(tab.currentPath)) {
            items = [];
          } else {
            final probeAccess = ShellListService.isRootFilesystemPath(tab.currentPath) &&
                !_rootAccessMode.usesSuperuser;
            items = listDirectory(tab.currentPath)
                .map((entity) => _mapFileSystemEntity(entity, probeAccess: probeAccess))
                .toList();
          }
        }
      } on FileAccessException catch (e) {
        if (ShellListService.isRootFilesystemPath(tab.currentPath) &&
            _isPermissionDenied(e)) {
          _setDirectoryAccessDenied(tab.currentPath);
          items = [];
        } else {
          rethrow;
        }
      }
    }

    final q = tab.searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      items = items.where((e) => e.name.toLowerCase().contains(q)).toList();
    }
    return items;
  }

  void _resyncTreeAfterRefresh(String tabId) {
    if (_browserViewMode != BrowserViewMode.tree) return;
    if (!supportsTreeView(_tab(tabId))) return;
    unawaited(syncTreeExpansion(tabId));
  }

  void refreshTab(String tabId) {
    _invalidateTreeCache(tabId: tabId);
    final tab = _tab(tabId);
    if (tab.currentPath == '@home') {
      invalidateHomeEntries();
      unawaited(_loadHomeEntries(tabId: tabId));
      return;
    }
    if (tab.currentPath == '@recent') {
      unawaited(_refreshRecentInBackground(showLoadingIfEmpty: false, tabId: tabId));
      return;
    }
    if (tab.currentPath == '@ftp') {
      unawaited(_refreshFtpList(tabId));
      return;
    }
    if (AppPathUtils.isAppsList(tab.currentPath)) {
      _appsError = null;
      unawaited(_refreshAppsForView(tab.currentPath, tabId: tabId, showLoadingIfEmpty: false));
      return;
    }
    if (tab.currentPath == '@apps') {
      _setTab(tabId, _tab(tabId).bumpList());
      notifyListeners();
      return;
    }
    if (tab.isZipViewer && tab.zipArchivePath != null) {
      _archiveService.clearZipCache(tab.zipArchivePath);
      _zipListCache.removeWhere((k, _) => k.startsWith('${tab.zipArchivePath}|'));
      unawaited(_loadZipListing(tabId, tab.zipArchivePath!, tab.zipInnerPath).then((_) {
        _resyncTreeAfterRefresh(tabId);
      }));
      return;
    }
    if (ShellListService.shouldUseShell(tab.currentPath, mode: _rootAccessMode)) {
      _shellDirCache.remove(tab.currentPath);
      _shellErrors.remove(tab.currentPath);
      _dirAccessNotes.remove(tab.currentPath);
      unawaited(_loadShellDirectory(tabId, tab.currentPath).then((_) {
        _resyncTreeAfterRefresh(tabId);
      }));
      return;
    }
    if (tab.currentPath.startsWith('@ftp/')) {
      _ftpCache.remove(tab.currentPath);
      _ftpErrors.remove(tab.currentPath);
      final inner = tab.currentPath.substring(5);
      final parts = inner.split('/');
      final serverId = parts[0];
      final remotePath = parts.sublist(1).join('/');
      unawaited(loadFtpEntries(tabId, serverId, remotePath));
      return;
    }
    _setTab(tabId, _tab(tabId).bumpList());
    notifyListeners();
    _resyncTreeAfterRefresh(tabId);
  }

  Future<void> _refreshFtpList(String tabId) async {
    await loadFtpServers();
    _setTab(tabId, _tab(tabId).bumpList());
    notifyListeners();
  }

  void closeEditorInTab(String tabId) {
    final tab = _tab(tabId);
    final restoreZip = tab.zipArchivePath != null;
    _setTab(
      tabId,
      tab.copyWith(
        mode: restoreZip ? TabMode.zipViewer : TabMode.browser,
        clearEditor: true,
      ),
    );
    notifyListeners();
  }

  // ── File operations ──────────────────────────────────────

  List<FileSystemEntity> listDirectory(String dirPath) {
    if (dirPath.startsWith('@')) return [];
    return _fileService.listDirectory(dirPath, showHidden: _showHidden);
  }

  Future<void> openFileInTab(String tabId, String filePath) async {
    try {
      final editor = await _loadEditorTab(filePath);
      _setTab(
        tabId,
        _tab(tabId).copyWith(mode: TabMode.editor, editor: editor),
      );
      _activeTabId = tabId;
      _log(L10nScope.current.logFileOpened(p.basename(filePath)));
      notifyListeners();
    } catch (e) {
      _log(L10nScope.current.logOpenAppError('$e'));
      notifyListeners();
    }
  }

  Future<void> openFileAs(String tabId, String filePath, FileOpenAs openAs) async {
    try {
      if (openAs == FileOpenAs.archive) {
        if (FileTypeUtils.isZip(filePath)) {
          openZipView(tabId, filePath);
        } else if (FileTypeUtils.isTar(filePath)) {
          await unzipFile(tabId, filePath);
        } else {
          _log(L10nScope.current.logFormatNotSupportedOpen(FileTypeUtils.archiveFormatName(filePath)));
          notifyListeners();
        }
        return;
      }

      final editor = await _loadEditorTabAs(filePath, openAs);
      _setTab(
        tabId,
        _tab(tabId).copyWith(mode: TabMode.editor, editor: editor),
      );
      _activeTabId = tabId;
      _log(L10nScope.current.logFileOpened(p.basename(filePath)));
      notifyListeners();
    } catch (e) {
      _log(L10nScope.current.logOpenAppError('$e'));
      notifyListeners();
    }
  }

  Future<String?> _resolveLocalPath(String filePath) async {
    if (filePath.startsWith('@ftp/')) {
      return downloadFtpFileToTemp(filePath);
    }
    return filePath;
  }

  Future<EditorTab> _loadEditorTabAs(String filePath, FileOpenAs openAs) async {
    switch (openAs) {
      case FileOpenAs.text:
        final String content;
        if (filePath.startsWith('@ftp/')) {
          final (serverId, remotePath) = _parseFtpPath(filePath);
          final client = await _connectFtp(serverId);
          try {
            final ftpFile = client.getFile(remotePath);
            final bytes = await client.fs.downloadFile(ftpFile);
            content = TextEncodingService.instance.decode(bytes, _textEncoding);
          } finally {
            await client.disconnect();
          }
        } else {
          content = await _fileService.readText(filePath, encoding: _textEncoding);
        }
        return EditorTab(
          type: EditorTabType.text,
          filePath: filePath,
          title: p.basename(filePath),
          content: content,
          language: LanguageDetector.detect(filePath),
        );
      case FileOpenAs.pdf:
        return EditorTab(
          type: EditorTabType.pdf,
          filePath: filePath,
          localPath: await _resolveLocalPath(filePath),
          title: p.basename(filePath),
        );
      case FileOpenAs.image:
        return EditorTab(
          type: EditorTabType.media,
          filePath: filePath,
          localPath: await _resolveLocalPath(filePath),
          title: p.basename(filePath),
          forcedMediaMode: MediaOpenMode.image,
        );
      case FileOpenAs.video:
        return EditorTab(
          type: EditorTabType.media,
          filePath: filePath,
          localPath: await _resolveLocalPath(filePath),
          title: p.basename(filePath),
          forcedMediaMode: MediaOpenMode.video,
        );
      case FileOpenAs.audio:
        return EditorTab(
          type: EditorTabType.media,
          filePath: filePath,
          localPath: await _resolveLocalPath(filePath),
          title: p.basename(filePath),
          forcedMediaMode: MediaOpenMode.audio,
        );
      case FileOpenAs.archive:
        throw StateError('Archive open-as is handled separately');
    }
  }

  Future<String?> downloadFtpFileToTemp(String filePath) async {
    if (!filePath.startsWith('@ftp/')) return filePath;
    final (serverId, remotePath) = _parseFtpPath(filePath);
    final client = await _connectFtp(serverId);
    try {
      final ftpFile = client.getFile(remotePath);
      final bytes = await client.fs.downloadFile(ftpFile);
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/${p.basename(filePath)}');
      await tempFile.writeAsBytes(bytes);
      return tempFile.path;
    } catch (e) {
      _log(L10nScope.current.logFtpFileLoadError('$e'));
      return null;
    } finally {
      await client.disconnect();
    }
  }

  List<String> getMediaFilesOfSameType(String filePath, {MediaOpenMode? forcedMode}) {
    bool matches(String path) {
      if (forcedMode != null) {
        return switch (forcedMode) {
          MediaOpenMode.image => FileTypeUtils.isImage(path),
          MediaOpenMode.video => FileTypeUtils.isVideo(path),
          MediaOpenMode.audio => FileTypeUtils.isAudio(path),
        };
      }
      if (FileTypeUtils.isImage(filePath)) return FileTypeUtils.isImage(path);
      if (FileTypeUtils.isVideo(filePath)) return FileTypeUtils.isVideo(path);
      if (FileTypeUtils.isAudio(filePath)) return FileTypeUtils.isAudio(path);
      return false;
    }

    if (filePath.startsWith('@ftp/')) {
      final parentPath = p.dirname(filePath).replaceAll('\\', '/');
      final entries = _ftpCache[parentPath] ?? [];
      return entries
          .where((e) => !e.isDirectory)
          .map((e) => e.path)
          .where(matches)
          .toList();
    } else {
      final parentDir = p.dirname(filePath);
      try {
        final entities = _fileService.listDirectory(parentDir, showHidden: _showHidden);
        return entities
            .whereType<File>()
            .map((f) => f.path)
            .where(matches)
            .toList();
      } catch (_) {
        return [filePath];
      }
    }
  }

  void toggleShowSearch(String tabId) {
    final tab = _tab(tabId);
    final nextShow = !tab.showSearch;
    _setTab(tabId, tab.copyWith(
      showSearch: nextShow,
      searchQuery: nextShow ? tab.searchQuery : '',
    ));
    notifyListeners();
  }

  Future<EditorTab> _loadEditorTab(String filePath) async {
    final ext = p.extension(filePath).toLowerCase();
    final isPdf = ext == '.pdf';
    final isMedia = FileTypeUtils.isPreviewableMedia(filePath);

    if (isPdf || isMedia) {
      String? localPath;
      if (filePath.startsWith('@ftp/')) {
        localPath = await downloadFtpFileToTemp(filePath);
      } else {
        localPath = filePath;
      }
      return EditorTab(
        type: isPdf ? EditorTabType.pdf : EditorTabType.media,
        filePath: filePath,
        localPath: localPath,
        title: p.basename(filePath),
        content: '',
      );
    }

    final String content;
    if (filePath.startsWith('@ftp/')) {
      final (serverId, remotePath) = _parseFtpPath(filePath);
      final client = await _connectFtp(serverId);
      try {
        final ftpFile = client.getFile(remotePath);
        final bytes = await client.fs.downloadFile(ftpFile);
        content = TextEncodingService.instance.decode(bytes, _textEncoding);
      } finally {
        await client.disconnect();
      }
    } else {
      content = await _fileService.readText(filePath, encoding: _textEncoding);
    }
    return EditorTab(
      type: EditorTabType.text,
      filePath: filePath,
      title: p.basename(filePath),
      content: content,
      language: LanguageDetector.detect(filePath),
    );
  }

  Future<String?> createNewFile({String? tabId}) async {
    final id = tabId ?? _activeTabId;
    if (id == null) return null;
    final tab = _tab(id);
    if (tab.isZipViewer) return null;
    final dir = tab.currentPath;

    if (dir.startsWith('@ftp/')) {
      _ftpLoadingPaths.add(dir);
      notifyListeners();
      try {
        final name = _uniqueFtpName(dir, 'untitled.txt');
        final (serverId, remoteDirPath) = _parseFtpPath(dir);
        final remoteFilePath = p.join(remoteDirPath, name).replaceAll('\\', '/');
        final client = await _connectFtp(serverId);
        try {
          final ftpFile = client.getFile(remoteFilePath);
          await ftpFile.create(recursive: true);
        } finally {
          await client.disconnect();
        }
        final filePath = '@ftp/$serverId/${remoteFilePath.startsWith('/') ? remoteFilePath.substring(1) : remoteFilePath}';
        _log(L10nScope.current.logCreateFile(name));
        refreshTab(id);
        return filePath;
      } finally {
        _ftpLoadingPaths.remove(dir);
        notifyListeners();
      }
    } else {
      final name = _fileService.uniqueName(dir, 'untitled.txt');
      final filePath = p.join(dir, name);
      await _fileService.createFile(filePath);
      _log(L10nScope.current.logCreateFile(name));
      refreshTab(id);
      return filePath;
    }
  }

  Future<String?> createNewFolder({String? tabId}) async {
    final id = tabId ?? _activeTabId;
    if (id == null) return null;
    final tab = _tab(id);
    if (tab.isZipViewer) return null;
    final dir = tab.currentPath;

    if (dir.startsWith('@ftp/')) {
      _ftpLoadingPaths.add(dir);
      notifyListeners();
      try {
        final name = _uniqueFtpName(dir, 'New Folder');
        final (serverId, remoteDirPath) = _parseFtpPath(dir);
        final remoteFolderPath = p.join(remoteDirPath, name).replaceAll('\\', '/');
        final client = await _connectFtp(serverId);
        try {
          final ftpFolder = client.getDirectory(remoteFolderPath);
          await ftpFolder.create(recursive: true);
        } finally {
          await client.disconnect();
        }
        final folderPath = '@ftp/$serverId/${remoteFolderPath.startsWith('/') ? remoteFolderPath.substring(1) : remoteFolderPath}';
        _log(L10nScope.current.logCreateFolder(name));
        refreshTab(id);
        return folderPath;
      } finally {
        _ftpLoadingPaths.remove(dir);
        notifyListeners();
      }
    } else {
      final name = _fileService.uniqueName(dir, 'New Folder');
      final folderPath = p.join(dir, name);
      await _fileService.createFolder(folderPath);
      _log(L10nScope.current.logCreateFolder(name));
      refreshTab(id);
      return folderPath;
    }
  }

  void copyToClipboard(List<String> paths) {
    _clipboard = FileClipboardEntry(paths: paths, operation: ClipboardOperation.copy);
    _log(L10nScope.current.logCopiedItems(paths.length));
    notifyListeners();
  }

  void cutToClipboard(List<String> paths) {
    _clipboard = FileClipboardEntry(paths: paths, operation: ClipboardOperation.cut);
    _log(L10nScope.current.logCutItems(paths.length));
    notifyListeners();
  }

  Future<void> pasteTo(String tabId, String destinationDir) async {
    if (_clipboard == null || _clipboard!.paths.isEmpty) return;
    final tab = _tab(tabId);
    if (tab.isZipViewer) {
      _log(L10nScope.current.logCannotPasteInZip);
      notifyListeners();
      return;
    }
    final isFtp = destinationDir.startsWith('@ftp/');
    if (isFtp) {
      _ftpLoadingPaths.add(destinationDir);
    }

    final isMove = _clipboard!.operation == ClipboardOperation.cut;
    final cancelToken = ArchiveCancelToken();
    _startFileOperation(
      TabFileOperation.paste,
      tabId,
      label: L10nScope.current.itemCount(_clipboard!.paths.length),
      cancelToken: cancelToken,
    );
    _setBusy(true);
    final l10n = L10nScope.current;
    _statusMessage = isMove ? l10n.moving : l10n.pasting;

    final op = _tabFileOperations[tabId]!;

    try {
      _log(isMove ? L10nScope.current.moving : L10nScope.current.pasting);
      notifyListeners();

      final total = isFtp
          ? _clipboard!.paths.length
          : await _countTransferItems(_clipboard!.paths, isMove: isMove);
      final tracker = EntryProgressTracker(total > 0 ? total : _clipboard!.paths.length);

      void onTransferProgress(String name, double progress) {
        _setTabOperationProgress(tabId, progress, name);
        if (_activeTabId == tabId) {
          final l10n = L10nScope.current;
          final percent = (progress * 100).round();
          _statusMessage = isMove
              ? l10n.moveProgress(name, percent)
              : l10n.pasteProgress(name, percent);
        }
        notifyListeners();
      }

      for (final srcPath in _clipboard!.paths) {
        if (cancelToken.isCancelled) throw const ArchiveCancelledException();
        await _transferSinglePath(
          srcPath,
          destinationDir,
          isMove: isMove,
          tracker: tracker,
          onProgress: onTransferProgress,
          cancelToken: cancelToken,
          rollbackPaths: op.rollbackPaths,
          movedPairs: isMove ? op.movedPairs : null,
        );
      }

      if (isMove) {
        _clipboard = null;
      }
      _log(L10nScope.current.logPasteSuccess);
      clearSelection(tabId);
      _hapticOnFileOpComplete();
      refreshTab(tabId);
    } on ArchiveCancelledException {
      await _performOperationRollback(tabId);
      _log(L10nScope.current.cancelPaste);
      _statusMessage = L10nScope.current.cancelPaste;
    } catch (e) {
      await _performOperationRollback(tabId);
      _log(L10nScope.current.logPasteError('$e'));
      notifyListeners();
    } finally {
      if (isFtp) {
        _ftpLoadingPaths.remove(destinationDir);
      }
      _endFileOperation(tabId);
      if (_tabFileOperations.isEmpty) {
        _setBusy(false);
      }
    }
  }

  Future<int> _countTransferItems(List<String> paths, {required bool isMove}) async {
    if (isMove) return paths.length;
    return _fileService.countDeletionItemsInPaths(paths);
  }

  Future<void> _transferSinglePath(
    String sourcePath,
    String destDir, {
    required bool isMove,
    EntryProgressTracker? tracker,
    void Function(String name, double progress)? onProgress,
    ArchiveCancelToken? cancelToken,
    List<String>? rollbackPaths,
    List<({String src, String dest})>? movedPairs,
  }) async {
    if (cancelToken?.isCancelled == true) throw const ArchiveCancelledException();

    final name = p.basename(sourcePath);
    final destPath = p.join(destDir, name).replaceAll('\\', '/');
    
    final srcIsFtp = sourcePath.startsWith('@ftp/');
    final destIsFtp = destDir.startsWith('@ftp/');

    if (sourcePath.startsWith('zip://')) {
      final separatorIndex = sourcePath.indexOf('::');
      if (separatorIndex == -1) return;
      final zipPath = sourcePath.substring(6, separatorIndex);
      final innerPath = sourcePath.substring(separatorIndex + 2);
      
      if (destIsFtp) {
        final tempPath = await _extractZipEntryToTemp(zipPath, innerPath);
        final tempIsDirectory = FileSystemEntity.isDirectorySync(tempPath);
        if (tempIsDirectory) {
          await _uploadLocalDirectory(tempPath, destPath, isMove: true);
        } else {
          await _uploadLocalFile(tempPath, destPath, isMove: true);
        }
      } else {
        await _archiveService.extractEntry(zipPath, innerPath, destDir);
      }
      rollbackPaths?.add(destPath);
      onProgress?.call(name, tracker?.advance() ?? 1.0);
      return;
    }
    
    if (srcIsFtp && destIsFtp) {
      // FTP to FTP
      final (srcServerId, srcRemotePath) = _parseFtpPath(sourcePath);
      final (destServerId, destRemotePath) = _parseFtpPath(destDir);
      
      if (srcServerId == destServerId) {
        // Same FTP server
        final client = await _connectFtp(srcServerId);
        try {
          final targetDestPath = p.join(destRemotePath, name).replaceAll('\\', '/');
          final isDir = _isFtpDirectory(sourcePath);
          if (isDir) {
            if (isMove) {
              final ftpFolder = client.getDirectory(srcRemotePath);
              await ftpFolder.move(targetDestPath);
            } else {
              await _copyFtpDirectoryWithinServer(client, srcRemotePath, targetDestPath);
            }
          } else {
            final ftpFile = client.getFile(srcRemotePath);
            if (isMove) {
              await ftpFile.move(targetDestPath);
            } else {
              await ftpFile.copy(targetDestPath);
            }
          }
        } finally {
          await client.disconnect();
        }
      } else {
        // Different FTP servers
        final isDir = _isFtpDirectory(sourcePath);
        if (isDir) {
          await _transferFtpDirectoryCrossServer(sourcePath, destPath, isMove: isMove);
        } else {
          await _transferFtpFileCrossServer(sourcePath, destPath, isMove: isMove);
        }
      }
      if (isMove) {
        movedPairs?.add((src: sourcePath, dest: destPath));
      } else {
        rollbackPaths?.add(destPath);
      }
      onProgress?.call(name, tracker?.advance() ?? 1.0);
    } else if (srcIsFtp && !destIsFtp) {
      // FTP to Local
      final isDir = _isFtpDirectory(sourcePath);
      if (isDir) {
        await _downloadFtpDirectory(sourcePath, destPath, isMove: isMove);
      } else {
        await _downloadFtpFile(sourcePath, destPath, isMove: isMove);
      }
      if (isMove) {
        movedPairs?.add((src: sourcePath, dest: destPath));
      } else {
        rollbackPaths?.add(destPath);
      }
      onProgress?.call(name, tracker?.advance() ?? 1.0);
    } else if (!srcIsFtp && destIsFtp) {
      // Local to FTP
      final isDir = _fileService.isDirectory(sourcePath);
      if (isDir) {
        await _uploadLocalDirectory(sourcePath, destPath, isMove: isMove);
      } else {
        await _uploadLocalFile(sourcePath, destPath, isMove: isMove);
      }
      if (isMove) {
        movedPairs?.add((src: sourcePath, dest: destPath));
      } else {
        rollbackPaths?.add(destPath);
      }
      onProgress?.call(name, tracker?.advance() ?? 1.0);
    } else {
      // Local to Local
      if (isMove) {
        await _fileService.movePaths([sourcePath], destDir);
        movedPairs?.add((src: sourcePath, dest: destPath));
        onProgress?.call(name, tracker?.advance() ?? 1.0);
      } else if (tracker != null && onProgress != null) {
        final created = await _fileService.copyPathWithProgress(
          sourcePath,
          destDir,
          tracker,
          onProgress,
          shouldCancel: () => cancelToken?.isCancelled ?? false,
        );
        rollbackPaths?.add(created);
      } else {
        final created = await _fileService.copyPath(sourcePath, destDir);
        rollbackPaths?.add(created);
        onProgress?.call(name, tracker?.advance() ?? 1.0);
      }
    }
  }

  Future<void> _copyFtpDirectoryWithinServer(FtpClient client, String srcRemoteDir, String destRemoteDir) async {
    final destFolder = client.getDirectory(destRemoteDir);
    await destFolder.create(recursive: true);
    
    final srcFolder = client.getDirectory(srcRemoteDir);
    final list = await srcFolder.list();
    for (final item in list) {
      final targetPath = p.join(destRemoteDir, item.name).replaceAll('\\', '/');
      if (item is FtpDirectory) {
        await _copyFtpDirectoryWithinServer(client, item.path, targetPath);
      } else if (item is FtpFile) {
        await item.copy(targetPath);
      }
    }
  }

  Future<void> _transferFtpFileCrossServer(String srcPath, String destPath, {required bool isMove}) async {
    final (srcServerId, srcRemotePath) = _parseFtpPath(srcPath);
    final (destServerId, destRemotePath) = _parseFtpPath(destPath);
    
    final srcClient = await _connectFtp(srcServerId);
    final destClient = await _connectFtp(destServerId);
    
    try {
      final srcFile = srcClient.getFile(srcRemotePath);
      final destFile = destClient.getFile(destRemotePath);
      
      final bytes = await srcClient.fs.downloadFile(srcFile);
      await destClient.fs.uploadFile(destFile, bytes);
      
      if (isMove) {
        await srcFile.delete();
      }
    } finally {
      await srcClient.disconnect();
      await destClient.disconnect();
    }
  }

  Future<void> _transferFtpDirectoryCrossServer(String srcPath, String destPath, {required bool isMove}) async {
    final (srcServerId, srcRemotePath) = _parseFtpPath(srcPath);
    final (destServerId, destRemotePath) = _parseFtpPath(destPath);
    
    final srcClient = await _connectFtp(srcServerId);
    final destClient = await _connectFtp(destServerId);
    
    try {
      await _copyFtpDirectoryCrossServer(srcClient, destClient, srcRemotePath, destRemotePath);
      if (isMove) {
        final srcFolder = srcClient.getDirectory(srcRemotePath);
        await srcFolder.delete(recursive: true);
      }
    } finally {
      await srcClient.disconnect();
      await destClient.disconnect();
    }
  }

  Future<void> _copyFtpDirectoryCrossServer(FtpClient srcClient, FtpClient destClient, String srcRemoteDir, String destRemoteDir) async {
    final destFolder = destClient.getDirectory(destRemoteDir);
    await destFolder.create(recursive: true);
    
    final srcFolder = srcClient.getDirectory(srcRemoteDir);
    final list = await srcFolder.list();
    for (final item in list) {
      final targetPath = p.join(destRemoteDir, item.name).replaceAll('\\', '/');
      if (item is FtpDirectory) {
        await _copyFtpDirectoryCrossServer(srcClient, destClient, item.path, targetPath);
      } else if (item is FtpFile) {
        final bytes = await srcClient.fs.downloadFile(item);
        final destFile = destClient.getFile(targetPath);
        await destClient.fs.uploadFile(destFile, bytes);
      }
    }
  }

  Future<void> _downloadFtpFile(String srcPath, String destPath, {required bool isMove}) async {
    final (srcServerId, srcRemotePath) = _parseFtpPath(srcPath);
    final srcClient = await _connectFtp(srcServerId);
    try {
      final srcFile = srcClient.getFile(srcRemotePath);
      final bytes = await srcClient.fs.downloadFile(srcFile);
      await _fileService.writeBytes(destPath, bytes);
      if (isMove) {
        await srcFile.delete();
      }
    } finally {
      await srcClient.disconnect();
    }
  }

  Future<void> _downloadFtpDirectory(String srcPath, String destPath, {required bool isMove}) async {
    final (srcServerId, srcRemotePath) = _parseFtpPath(srcPath);
    final srcClient = await _connectFtp(srcServerId);
    try {
      await _downloadFtpDirectoryHelper(srcClient, srcRemotePath, destPath);
      if (isMove) {
        final srcFolder = srcClient.getDirectory(srcRemotePath);
        await srcFolder.delete(recursive: true);
      }
    } finally {
      await srcClient.disconnect();
    }
  }

  Future<void> _downloadFtpDirectoryHelper(FtpClient srcClient, String srcRemoteDir, String destLocalDir) async {
    await Directory(destLocalDir).create(recursive: true);
    final srcFolder = srcClient.getDirectory(srcRemoteDir);
    final list = await srcFolder.list();
    for (final item in list) {
      final targetPath = p.join(destLocalDir, item.name);
      if (item is FtpDirectory) {
        await _downloadFtpDirectoryHelper(srcClient, item.path, targetPath);
      } else if (item is FtpFile) {
        final bytes = await srcClient.fs.downloadFile(item);
        await _fileService.writeBytes(targetPath, bytes);
      }
    }
  }

  Future<void> _uploadLocalFile(String srcPath, String destPath, {required bool isMove}) async {
    final (destServerId, destRemotePath) = _parseFtpPath(destPath);
    final destClient = await _connectFtp(destServerId);
    try {
      final bytes = await _fileService.readBytes(srcPath);
      final destFile = destClient.getFile(destRemotePath);
      await destClient.fs.uploadFile(destFile, bytes);
      if (isMove) {
        await _fileService.delete(srcPath);
      }
    } finally {
      await destClient.disconnect();
    }
  }

  Future<void> _uploadLocalDirectory(String srcPath, String destPath, {required bool isMove}) async {
    final (destServerId, destRemotePath) = _parseFtpPath(destPath);
    final destClient = await _connectFtp(destServerId);
    try {
      await _uploadLocalDirectoryHelper(destClient, srcPath, destRemotePath);
      if (isMove) {
        await _fileService.delete(srcPath);
      }
    } finally {
      await destClient.disconnect();
    }
  }

  Future<void> _uploadLocalDirectoryHelper(FtpClient destClient, String srcLocalDir, String destRemoteDir) async {
    final destFolder = destClient.getDirectory(destRemoteDir);
    await destFolder.create(recursive: true);
    
    final localDir = Directory(srcLocalDir);
    await for (final entity in localDir.list(recursive: false, followLinks: false)) {
      final targetPath = p.join(destRemoteDir, p.basename(entity.path)).replaceAll('\\', '/');
      if (entity is Directory) {
        await _uploadLocalDirectoryHelper(destClient, entity.path, targetPath);
      } else if (entity is File) {
        final bytes = await entity.readAsBytes();
        final destFile = destClient.getFile(targetPath);
        await destClient.fs.uploadFile(destFile, bytes);
      }
    }
  }

  Future<void> duplicatePaths(String tabId, List<String> paths) async {
    final tab = _tab(tabId);
    if (tab.isZipViewer) return;
    final dir = tab.currentPath;
    final isFtp = dir.startsWith('@ftp/');
    if (isFtp) {
      _ftpLoadingPaths.add(dir);
    }

    final cancelToken = ArchiveCancelToken();
    _startFileOperation(
      TabFileOperation.duplicate,
      tabId,
      label: L10nScope.current.itemCount(paths.length),
      cancelToken: cancelToken,
    );
    _setBusy(true);
    _statusMessage = L10nScope.current.duplicating;

    final op = _tabFileOperations[tabId]!;

    try {
      _log(L10nScope.current.duplicating);
      notifyListeners();

      final total = isFtp ? paths.length : await _fileService.countDeletionItemsInPaths(paths);
      final tracker = EntryProgressTracker(total > 0 ? total : paths.length);

      void onDuplicateProgress(String name, double progress) {
        _setTabOperationProgress(tabId, progress, name);
        if (_activeTabId == tabId) {
          final percent = (progress * 100).round();
          _statusMessage = L10nScope.current.duplicateProgress(name, percent);
        }
        notifyListeners();
      }

      for (final path in paths) {
        if (cancelToken.isCancelled) throw const ArchiveCancelledException();
        if (path.startsWith('@ftp/')) {
          final (serverId, remotePath) = _parseFtpPath(path);
          final client = await _connectFtp(serverId);
          try {
            final isDir = _isFtpDirectory(path);
            final remoteDir = p.dirname(remotePath).replaceAll('\\', '/');
            final base = p.basename(remotePath);
            final String newName;
            if (isDir) {
              newName = _uniqueFtpName('@ftp/$serverId/${remoteDir.startsWith('/') ? remoteDir.substring(1) : remoteDir}', '$base - Copy');
              final targetDestPath = p.join(remoteDir, newName).replaceAll('\\', '/');
              await _copyFtpDirectoryWithinServer(client, remotePath, targetDestPath);
              op.rollbackPaths.add('@ftp/$serverId/${targetDestPath.startsWith('/') ? targetDestPath.substring(1) : targetDestPath}');
            } else {
              final ext = p.extension(base);
              final name = p.basenameWithoutExtension(base);
              newName = _uniqueFtpName('@ftp/$serverId/${remoteDir.startsWith('/') ? remoteDir.substring(1) : remoteDir}', '$name - Copy$ext');
              final targetDestPath = p.join(remoteDir, newName).replaceAll('\\', '/');
              final ftpFile = client.getFile(remotePath);
              await ftpFile.copy(targetDestPath);
              op.rollbackPaths.add('@ftp/$serverId/${targetDestPath.startsWith('/') ? targetDestPath.substring(1) : targetDestPath}');
            }
          } finally {
            await client.disconnect();
          }
          onDuplicateProgress(p.basename(path), tracker.advance());
        } else {
          final created = await _fileService.duplicateWithProgress(
            path,
            tracker,
            onDuplicateProgress,
            shouldCancel: () => cancelToken.isCancelled,
          );
          op.rollbackPaths.add(created);
        }
      }
      _log(L10nScope.current.logDuplicateSuccess(paths.length));
      clearSelection(tabId);
      _hapticOnFileOpComplete();
      refreshTab(tabId);
    } on ArchiveCancelledException {
      await _performOperationRollback(tabId);
      _log(L10nScope.current.cancelDuplicate);
      _statusMessage = L10nScope.current.cancelDuplicate;
    } catch (e) {
      await _performOperationRollback(tabId);
      _log(L10nScope.current.logDuplicateError('$e'));
      notifyListeners();
    } finally {
      if (isFtp) {
        _ftpLoadingPaths.remove(dir);
      }
      _endFileOperation(tabId);
      if (_tabFileOperations.isEmpty) {
        _setBusy(false);
      }
    }
  }

  Future<void> deletePaths(String tabId, List<String> paths) async {
    if (paths.isEmpty) return;

    final tab = _tab(tabId);
    final dir = tab.currentPath;
    final isFtp = dir.startsWith('@ftp/');
    if (isFtp) {
      _ftpLoadingPaths.add(dir);
    }

    _startFileOperation(
      TabFileOperation.delete,
      tabId,
      label: L10nScope.current.itemCount(paths.length),
      cancelToken: ArchiveCancelToken(),
    );
    _setBusy(true);
    _statusMessage = L10nScope.current.deleting;
    final cancelToken = _tabFileOperations[tabId]!.cancelToken!;

    try {
      final total = isFtp ? paths.length : await _fileService.countDeletionItemsInPaths(paths);
      final tracker = EntryProgressTracker(total > 0 ? total : paths.length);

      void onDeleteProgress(String name, double progress) {
        _setTabOperationProgress(tabId, progress, name);
        if (_activeTabId == tabId) {
          final percent = (progress * 100).round();
          _statusMessage = L10nScope.current.deleteProgress(name, percent);
        }
        notifyListeners();
      }

      _log(L10nScope.current.deleting);
      notifyListeners();

      var stoppedEarly = false;
      for (final path in paths) {
        if (cancelToken.isCancelled) {
          stoppedEarly = true;
          break;
        }
        if (path.startsWith('@ftp/')) {
          final (serverId, remotePath) = _parseFtpPath(path);
          final client = await _connectFtp(serverId);
          try {
            final isDir = _isFtpDirectory(path);
            final parentPath = p.dirname(path).replaceAll('\\', '/');
            final cache = _ftpCache[parentPath] ?? [];
            final name = p.basename(path);
            final entry = cache.where((e) => e.name == name).firstOrNull;

            final isDirResolved = entry?.isDirectory ?? isDir;
            if (isDirResolved) {
              final ftpFolder = client.getDirectory(remotePath);
              await ftpFolder.delete(recursive: true);
            } else {
              final ftpFile = client.getFile(remotePath);
              await ftpFile.delete();
            }
          } finally {
            await client.disconnect();
          }
          onDeleteProgress(p.basename(path), tracker.advance());
        } else if (_useTrash) {
          await TrashService.instance.moveToTrash(path);
          ThumbnailService.instance.evict(path);
          onDeleteProgress(p.basename(path), tracker.advance());
        } else {
          await _fileService.deletePathWithProgress(
            path,
            tracker,
            onDeleteProgress,
            shouldCancel: () => cancelToken.isCancelled,
          );
          ThumbnailService.instance.evict(path);
        }
        if (cancelToken.isCancelled) {
          stoppedEarly = true;
          break;
        }
      }

      if (tab.isEditing && tab.editor?.filePath != null && !stoppedEarly) {
        if (paths.any((path) => _norm(path) == _norm(tab.editor!.filePath!))) {
          closeEditorInTab(tabId);
        }
      }

      if (stoppedEarly) {
        final l10n = L10nScope.current;
        _queueFileOpNotice(
          l10n.deleteStopped,
          L10nScope.current.logDeletePartialNotice,
        );
        _log(L10nScope.current.deleteStopped);
        _statusMessage = l10n.deleteStopped;
      } else {
        _log(_useTrash ? L10nScope.current.logMovedToTrash(paths.length) : L10nScope.current.logDeletedItems(paths.length));
        _hapticOnFileOpComplete();
      }
      clearSelection(tabId);
      refreshTab(tabId);
    } catch (e) {
      _log(L10nScope.current.logDeleteError('$e'));
      notifyListeners();
    } finally {
      if (isFtp) {
        _ftpLoadingPaths.remove(dir);
      }
      _endFileOperation(tabId);
      if (_tabFileOperations.isEmpty) {
        _setBusy(false);
      }
    }
  }

  Future<void> renamePath(String tabId, String oldPath, String newName) async {
    final tab = _tab(tabId);
    final dir = tab.currentPath;
    final isFtp = dir.startsWith('@ftp/');
    if (isFtp) {
      _ftpLoadingPaths.add(dir);
      notifyListeners();
    }
    try {
      final String newPath;
      if (oldPath.startsWith('@ftp/')) {
        final (serverId, oldRemotePath) = _parseFtpPath(oldPath);
        final client = await _connectFtp(serverId);
        try {
          final parentPath = p.dirname(oldRemotePath).replaceAll('\\', '/');
          final newRemotePath = p.join(parentPath, newName).replaceAll('\\', '/');
          final isDir = _isFtpDirectory(oldPath);
          if (isDir) {
            final ftpFolder = client.getDirectory(oldRemotePath);
            await ftpFolder.rename(newName);
          } else {
            final ftpFile = client.getFile(oldRemotePath);
            await ftpFile.rename(newName);
          }
          newPath = '@ftp/$serverId/${newRemotePath.startsWith('/') ? newRemotePath.substring(1) : newRemotePath}';
        } finally {
          await client.disconnect();
        }
      } else {
        newPath = p.join(p.dirname(oldPath), newName);
        await _fileService.renameEntity(oldPath, newPath);
        ThumbnailService.instance.evict(oldPath);
      }
      if (tab.isEditing && tab.editor?.filePath == oldPath) {
        _setTab(
          tabId,
          tab.copyWith(
            editor: tab.editor!.copyWith(filePath: newPath, title: newName),
          ),
        );
      }
      final selected = tab.selectedPaths.map((p) => _norm(p) == _norm(oldPath) ? newPath : p).toSet();
      _setTab(tabId, tab.copyWith(selectedPaths: selected));
      _log(L10nScope.current.logRenamedTo(newName));
      refreshTab(tabId);
    } finally {
      if (isFtp) {
        _ftpLoadingPaths.remove(dir);
        notifyListeners();
      }
    }
  }

  // ── Zip / Unzip / Open with system ─────────────────────────

  Future<void> zipPaths(
    String tabId,
    List<String> paths, {
    String? zipName,
    String? password,
  }) async {
    if (paths.isEmpty) return;
    var dir = _tab(tabId).currentPath;
    if (dir == '@recent') {
      dir = StorageRoots.defaultRoot(_permissionService);
    }
    final isFtp = dir.startsWith('@ftp/');
    if (isFtp) {
      _ftpLoadingPaths.add(dir);
    }

    final cancelToken = ArchiveCancelToken();
    var baseName = zipName?.trim() ?? '';
    if (baseName.isEmpty) {
      baseName = paths.length == 1
          ? '${p.basenameWithoutExtension(paths.first)}.zip'
          : 'archive.zip';
    }
    if (!baseName.toLowerCase().endsWith('.zip')) {
      baseName = '$baseName.zip';
    }

    _startFileOperation(
      TabFileOperation.zip,
      tabId,
      label: baseName,
      cancelToken: cancelToken,
    );
    _setBusy(true);
    _statusMessage = L10nScope.current.zipping;

    String? rollbackPath;

    void onProgress(double progress, String? file) {
      _setTabOperationProgress(tabId, progress.clamp(0.0, 1.0), file ?? baseName);
      if (_activeTabId == tabId && file != null) {
        final percent = (progress * 100).round();
        _statusMessage = L10nScope.current.zipProgress(p.basename(file), percent);
      }
      notifyListeners();
    }

    try {
      _log(L10nScope.current.zipping);
      notifyListeners();

      if (isFtp) {
        final (serverId, remoteDirPath) = _parseFtpPath(dir);
        final zipName = _uniqueFtpName(dir, baseName);

        final tempDir = await Directory.systemTemp.createTemp('cope_zip_');
        rollbackPath = tempDir.path;
        _tabFileOperations[tabId]?.destDir = rollbackPath;

        final localZipPath = p.join(tempDir.path, zipName);

        final localPathsToZip = <String>[];
        for (final path in paths) {
          if (cancelToken.isCancelled) throw const ArchiveCancelledException();
          final name = p.basename(path);
          final localDest = p.join(tempDir.path, name);
          final isDir = _isFtpDirectory(path);
          if (isDir) {
            await _downloadFtpDirectory(path, localDest, isMove: false);
          } else {
            await _downloadFtpFile(path, localDest, isMove: false);
          }
          localPathsToZip.add(localDest);
        }

        if (cancelToken.isCancelled) throw const ArchiveCancelledException();

        await _archiveService.zipPaths(
          localPathsToZip,
          localZipPath,
          password: password,
          onProgress: onProgress,
          cancelToken: cancelToken,
        );

        if (cancelToken.isCancelled) throw const ArchiveCancelledException();

        final destClient = await _connectFtp(serverId);
        try {
          final remoteZipPath = p.join(remoteDirPath, zipName).replaceAll('\\', '/');
          final destFile = destClient.getFile(remoteZipPath);
          final bytes = await File(localZipPath).readAsBytes();
          await destClient.fs.uploadFile(destFile, bytes);
        } finally {
          await destClient.disconnect();
        }

        await tempDir.delete(recursive: true);
        rollbackPath = null;
        _tabFileOperations[tabId]?.destDir = null;
        _log(L10nScope.current.logZippedTo(zipName));
      } else {
        final zipName = _fileService.uniqueName(dir, baseName);
        final zipPath = p.join(dir, zipName);
        rollbackPath = zipPath;
        _tabFileOperations[tabId]?.destDir = rollbackPath;

        await _archiveService.zipPaths(
          paths,
          zipPath,
          password: password,
          onProgress: onProgress,
          cancelToken: cancelToken,
        );

        rollbackPath = null;
        _tabFileOperations[tabId]?.destDir = null;
        _log(L10nScope.current.logZippedTo(zipName));
      }
      _hapticOnFileOpComplete();
      clearSelection(tabId);
      refreshTab(tabId);
    } on ArchiveCancelledException {
      if (rollbackPath != null) {
        _tabFileOperations[tabId]?.destDir ??= rollbackPath;
      }
      await _performOperationRollback(tabId);
      _log(L10nScope.current.cancelZip);
      _statusMessage = L10nScope.current.cancelZip;
    } catch (e) {
      if (rollbackPath != null) {
        _tabFileOperations[tabId]?.destDir ??= rollbackPath;
      }
      await _performOperationRollback(tabId);
      _log(L10nScope.current.logZipError('$e'));
      notifyListeners();
    } finally {
      if (isFtp) {
        _ftpLoadingPaths.remove(dir);
      }
      _endFileOperation(tabId);
      if (_tabFileOperations.isEmpty) {
        _setBusy(false);
      }
    }
  }

  Future<void> zipClipboard(String tabId) async {
    if (_clipboard == null || _clipboard!.paths.isEmpty) return;
    await zipPaths(tabId, _clipboard!.paths);
  }

  Future<bool> isZipPasswordProtected(String zipPath) =>
      _archiveService.isPasswordProtected(zipPath);

  Future<void> unzipFile(String tabId, String zipPath, {String? password}) async {
    final dir = _tab(tabId).currentPath;
    final isFtp = dir.startsWith('@ftp/');
    if (isFtp) {
      _ftpLoadingPaths.add(dir);
    }

    final cancelToken = ArchiveCancelToken();
    _startFileOperation(
      TabFileOperation.unzip,
      tabId,
      label: p.basename(zipPath),
      cancelToken: cancelToken,
    );
    _setBusy(true);
    _statusMessage = L10nScope.current.unzipping;
    final folderBaseName = p.basenameWithoutExtension(zipPath);
    String? destDir;

    void onProgress(double progress, String? file) {
      _setTabOperationProgress(tabId, progress.clamp(0.0, 1.0), file ?? p.basename(zipPath));
      if (_activeTabId == tabId && file != null) {
        final percent = (progress * 100).round();
        _statusMessage = L10nScope.current.unzipProgress(p.basename(file), percent);
      }
      notifyListeners();
    }

    try {
      _log(L10nScope.current.unzipping);
      notifyListeners();

      final isTar = FileTypeUtils.isTar(zipPath);

      if (isFtp) {
        final (serverId, remoteDirPath) = _parseFtpPath(dir);
        final folderName = _uniqueFtpName(dir, folderBaseName);
        
        final tempDir = await Directory.systemTemp.createTemp('cope_unzip_');
        destDir = tempDir.path;
        _tabFileOperations[tabId]?.destDir = destDir;
        final localZipName = p.basename(zipPath);
        final localZipPath = p.join(tempDir.path, localZipName);
        
        await _downloadFtpFile(zipPath, localZipPath, isMove: false);
        
        final localUnzippedDir = p.join(tempDir.path, folderName);

        if (isTar) {
          await _archiveService.extractTar(localZipPath, localUnzippedDir);
        } else {
          await _archiveService.unzipTo(
            localZipPath,
            localUnzippedDir,
            password: password,
            onProgress: onProgress,
            cancelToken: cancelToken,
          );
        }
        
        final remoteFolderDest = p.join(remoteDirPath, folderName).replaceAll('\\', '/');
        await _uploadLocalDirectory(localUnzippedDir, '@ftp/$serverId/${remoteFolderDest.startsWith('/') ? remoteFolderDest.substring(1) : remoteFolderDest}', isMove: false);
        
        await tempDir.delete(recursive: true);
        destDir = null;
        _tabFileOperations[tabId]?.destDir = null;
        _log(L10nScope.current.logUnzipTo(folderName));
      } else {
        final folderName = _fileService.uniqueName(dir, folderBaseName);
        destDir = p.join(dir, folderName);
        _tabFileOperations[tabId]?.destDir = destDir;

        if (isTar) {
          await _archiveService.extractTar(zipPath, destDir);
        } else {
          await _archiveService.unzipTo(
            zipPath,
            destDir,
            password: password,
            onProgress: onProgress,
            cancelToken: cancelToken,
          );
        }
        destDir = null;
        _tabFileOperations[tabId]?.destDir = null;
        _log(L10nScope.current.logUnzipTo(folderName));
      }
      _hapticOnFileOpComplete();
      refreshTab(tabId);
    } on ArchiveCancelledException {
      if (destDir != null) {
        _tabFileOperations[tabId]?.destDir ??= destDir;
      }
      await _performOperationRollback(tabId);
      _log(L10nScope.current.cancelUnzip);
      _statusMessage = L10nScope.current.cancelUnzip;
    } catch (e) {
      if (destDir != null) {
        _tabFileOperations[tabId]?.destDir ??= destDir;
      }
      await _performOperationRollback(tabId);
      _log(L10nScope.current.logUnzipError('$e'));
      notifyListeners();
    } finally {
      if (isFtp) {
        _ftpLoadingPaths.remove(dir);
      }
      _endFileOperation(tabId);
      if (_tabFileOperations.isEmpty) {
        _setBusy(false);
      }
    }
  }

  Future<void> openWithSystem(String filePath) async {
    _setBusy(true);
    try {
      final String finalPath;
      if (filePath.startsWith('@ftp/')) {
        final (serverId, remotePath) = _parseFtpPath(filePath);
        final client = await _connectFtp(serverId);
        try {
          final tempDir = await Directory.systemTemp.createTemp('cope_open_');
          final tempPath = p.join(tempDir.path, p.basename(filePath));
          final ftpFile = client.getFile(remotePath);
          final bytes = await client.fs.downloadFile(ftpFile);
          await File(tempPath).writeAsBytes(bytes);
          finalPath = tempPath;
        } finally {
          await client.disconnect();
        }
      } else {
        finalPath = filePath;
      }

      if (FileTypeUtils.isApk(finalPath)) {
        await installApkFile(finalPath);
        return;
      }
      
      final result = await _openWithService.openWithSystem(finalPath);
      _log(await _openWithService.openResultMessage(result));
      notifyListeners();
    } catch (e) {
      _log(L10nScope.current.logOpenAppError('$e'));
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  Future<void> installApkFile(String filePath) async {
    _setBusy(true);
    try {
      if (!File(filePath).existsSync()) {
        _log(L10nScope.current.logApkNotFound);
        notifyListeners();
        return;
      }
      final result = await _openWithService.openWithSystem(filePath);
      final message = result.type == ResultType.done
          ? L10nScope.current.openWithDone
          : await _openWithService.openResultMessage(result);
      _log(message);
      notifyListeners();
    } catch (e) {
      _log(L10nScope.current.logInstallApkError('$e'));
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  Future<String> _extractZipEntryToTemp(String zipPath, String innerPath, {String? password}) {
    return _archiveService.extractEntryToTemp(zipPath, innerPath, password: password);
  }

  Future<void> openZipFileAs(
    String tabId,
    String zipPath,
    String innerPath,
    FileOpenAs openAs, {
    String? password,
  }) async {
    _setZipOpening(zipPath, innerPath);
    final l10n = L10nScope.current;
    _statusMessage = l10n.openFileProgress(p.basename(innerPath));
    _setBusy(true);
    try {
      var pwd = password;
      if (pwd == null || pwd.isEmpty) {
        final protected = await _archiveService.isPasswordProtected(zipPath);
        if (protected) {
          _zipErrors[zipPath] = l10n.zipPasswordProtected;
          notifyListeners();
          return;
        }
      }

      _log(L10nScope.current.logOpeningFromZip);
      notifyListeners();
      final tempPath = await _extractZipEntryToTemp(zipPath, innerPath, password: pwd);
      await openFileAs(tabId, tempPath, openAs);
    } catch (e) {
      if (e is ArchivePasswordException) {
        _zipErrors[zipPath] = e.toString();
      }
      _log(L10nScope.current.logOpenAppError('$e'));
      notifyListeners();
    } finally {
      _setZipOpening(null, null);
      _setBusy(false);
    }
  }

  Future<void> openZipFile(String tabId, String zipPath, String innerPath, {String? password}) async {
    _setZipOpening(zipPath, innerPath);
    final l10n = L10nScope.current;
    _statusMessage = l10n.openFileProgress(p.basename(innerPath));
    _setBusy(true);
    try {
      var pwd = password;
      if (pwd == null || pwd.isEmpty) {
        final protected = await _archiveService.isPasswordProtected(zipPath);
        if (protected) {
          _zipErrors[zipPath] = l10n.zipPasswordProtected;
          notifyListeners();
          return;
        }
      }

      _log(L10nScope.current.logOpeningFromZip);
      notifyListeners();
      final tempPath = await _extractZipEntryToTemp(zipPath, innerPath, password: pwd);
      await handleFileTap(tabId, tempPath);
    } catch (e) {
      if (e is ArchivePasswordException) {
        _zipErrors[zipPath] = e.toString();
      }
      _log(L10nScope.current.logOpenAppError('$e'));
      notifyListeners();
    } finally {
      _setZipOpening(null, null);
      _setBusy(false);
    }
  }

  Future<void> shareZipFile(String zipPath, String innerPath, {String? password}) async {
    _setBusy(true);
    try {
      _log(L10nScope.current.logPrepareShareFromZip);
      notifyListeners();
      final tempPath = await _extractZipEntryToTemp(zipPath, innerPath, password: password);
      await SharePlus.instance.share(ShareParams(files: [XFile(tempPath)]));
    } catch (e) {
      _log(L10nScope.current.logShareFileError('$e'));
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  Future<void> handleItemTap(String tabId, BrowserEntry entry) async {
    final tab = _tab(tabId);
    if (tab.hasSelection && isSelectable(tabId, entry)) {
      toggleSelection(tabId, entry.path);
      return;
    }

    if (tab.isZipViewer) {
      if (entry.isDirectory) {
        navigateZipInner(tabId, entry.path);
      } else {
        await openZipFile(
          tabId,
          tab.zipArchivePath!,
          entry.path,
          password: _zipPasswords[tab.zipArchivePath!],
        );
      }
      return;
    }

    if (AppPathUtils.isAppPackage(entry.path)) {
      final package = AppPathUtils.packageFromPath(entry.path);
      if (package != null) await openSelectedApp(package);
      return;
    }

    if (!entry.isDirectory && FileTypeUtils.isApk(entry.path)) {
      if (_openApkAsZip) {
        openZipView(tabId, entry.path);
      } else {
        await installApkFile(entry.path);
      }
      return;
    }

    if (!entry.isDirectory && FileTypeUtils.isArchive(entry.path)) {
      if (FileTypeUtils.isZip(entry.path)) {
        openZipView(tabId, entry.path);
      } else if (FileTypeUtils.isTar(entry.path)) {
        await unzipFile(tabId, entry.path);
      } else {
        final format = FileTypeUtils.archiveFormatName(entry.path);
        _log(L10nScope.current.logFormatNotSupportedDirect(format));
        notifyListeners();
      }
      return;
    }

    if (entry.isDirectory) {
      await navigateTo(tabId, entry.path);
    } else {
      await handleFileTap(tabId, entry.path);
    }
  }

  Future<void> handleFileTap(String tabId, String filePath) async {
    final isPdf = p.extension(filePath).toLowerCase() == '.pdf';
    final isMedia = FileTypeUtils.isPreviewableMedia(filePath);

    if (FileTypeUtils.isEditableInApp(filePath) || isPdf || isMedia) {
      await openFileInTab(tabId, filePath);
    } else {
      await openWithSystem(filePath);
    }
  }

  // ── Editor updates ─────────────────────────────────────────

  void updateTabContent(String tabId, String content) {
    final tab = _tab(tabId);
    if (tab.editor == null) return;
    _setTab(tabId, tab.copyWith(editor: tab.editor!.copyWith(content: content, isModified: true)));
    notifyListeners();
  }

  Future<void> saveActiveTab() async {
    final tab = activeTab;
    if (tab == null) return;
    await saveTab(tab.id);
  }

  Future<void> saveTab(String tabId) async {
    final tab = _tab(tabId);
    final editor = tab.editor;
    if (editor == null) return;

    try {
      switch (editor.type) {
        case EditorTabType.text:
          var path = editor.filePath;
          if (path == null) {
            path = await FilePicker.saveFile(dialogTitle: 'Lưu file', fileName: 'untitled.txt');
            if (path == null) return;
          }
          if (path.startsWith('@ftp/')) {
            final (serverId, remotePath) = _parseFtpPath(path);
            final client = await _connectFtp(serverId);
            try {
              final ftpFile = client.getFile(remotePath);
              final bytes = TextEncodingService.instance.encode(editor.content, _textEncoding);
              await client.fs.uploadFile(ftpFile, bytes);
            } finally {
              await client.disconnect();
            }
          } else {
            await _fileService.writeText(path, editor.content, encoding: _textEncoding);
          }
          _setTab(tabId, tab.copyWith(editor: editor.copyWith(filePath: path, title: p.basename(path), isModified: false)));
        case EditorTabType.empty:
        case EditorTabType.pdf:
        case EditorTabType.media:
          return;
      }
      _log(L10nScope.current.logFileSaved(p.basename(editor.filePath ?? '')));
      refreshTab(tabId);
    } catch (e) {
      _log(L10nScope.current.logSaveError('$e'));
      notifyListeners();
    }
  }

  // ── Web Server ─────────────────────────────────────────────

  Future<void> startWebServer() async {
    try {
      final sharedRoot = _security?.webServerSharedRoot;
      final restrictToRoots = sharedRoot != null && sharedRoot.isNotEmpty;
      final roots = restrictToRoots
          ? [sharedRoot]
          : StorageRoots.discover(_permissionService);
      final defaultRoot = restrictToRoots
          ? sharedRoot
          : StorageRoots.defaultRoot(_permissionService);

      Future<bool> Function(String password)? verifier;
      if (_security != null) {
        verifier = await _security!.buildWebServerVerifier();
      }

      final addresses = await _webServerService.start(
        defaultRoot: defaultRoot,
        knownRoots: roots,
        restrictToRoots: restrictToRoots,
        asyncPasswordVerifier: verifier,
      );
      final l10n = L10nScope.current;
      final authNote = verifier != null ? l10n.logWebServerAuthWith : '';
      final url = NetworkUtils.buildPreferredUrl(addresses, WebServerService.port);
      final scopeNote = restrictToRoots
          ? l10n.logWebServerScopeFolder(sharedRoot)
          : l10n.logWebServerScopeAll;
      _log(l10n.logWebServerStarted(authNote, url ?? addresses.join(', '), scopeNote));
      if (url != null) {
        await WebServerNotificationService.instance.showRunning(url: url);
      }
      notifyListeners();
    } catch (e) {
      _log(L10nScope.current.logWebServerStartError('$e'));
      notifyListeners();
    }
  }

  Future<void> restartWebServerIfRunning() async {
    if (!isWebServerRunning) return;
    await stopWebServer();
    await startWebServer();
  }

  Future<void> stopWebServer() async {
    await _webServerService.stop();
    await WebServerNotificationService.instance.cancel();
    _log(L10nScope.current.logWebServerStopped);
    notifyListeners();
  }

  bool _isRootPath(String path) {
    return path == '@home' ||
        path == '/storage/emulated/0' ||
        path == '/' ||
        path == '@ftp' ||
        path == '@recent' ||
        path == '@apps' ||
        PathUtils.parentPath(path) == null;
  }

  bool handleBackNavigation() {
    final tab = activeTab;
    if (tab == null) return false;

    // 1. If editor is open, close the editor in this tab
    if (tab.isEditing) {
      closeEditorInTab(tab.id);
      return true;
    }

    // 2. If ZIP viewer is active, go up inside the archive
    if (tab.isZipViewer) {
      navigateZipUp(tab.id);
      return true;
    }

    // 3. If NOT at a root path, navigate up
    if (!_isRootPath(tab.currentPath)) {
      navigateUp(tab.id);
      return true;
    }

    // 4. If we are at a root path (out of directories)
    if (tab.currentPath != '@home') {
      if (_tabs.length > 1) {
        closeTab(tab.id);
        return true;
      } else {
        // Last tab, navigate to @home
        navigateTo(tab.id, '@home');
        return true;
      }
    } else {
      // Path is @home
      if (_tabs.length > 1) {
        closeTab(tab.id);
        return true;
      } else {
        // Last tab and at @home, return false to let the app close/exit
        return false;
      }
    }
  }

  @override
  void dispose() {
    if (_localeListener != null) {
      _localeProvider?.removeListener(_localeListener!);
    }
    WebServerNotificationService.instance.cancel();
    _webServerService.stop();
    super.dispose();
  }
}
