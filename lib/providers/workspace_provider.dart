import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:share_plus/share_plus.dart';

import 'package:cope_x_studio/models/app_tab.dart';
import 'package:cope_x_studio/models/browser_entry.dart';
import 'package:cope_x_studio/models/editor_tab.dart';
import 'package:cope_x_studio/models/file_clipboard.dart';
import 'package:cope_x_studio/models/ftp_server_config.dart';
import 'package:cope_x_studio/models/installed_app_info.dart';
import 'package:cope_x_studio/models/recent_file_entry.dart';
import 'package:cope_x_studio/services/app_manager_service.dart';
import 'package:cope_x_studio/models/tab_file_operation.dart';
import 'package:cope_x_studio/models/tab_file_operation_state.dart';
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
import 'package:cope_x_studio/services/web_server/web_server_service.dart';
import 'package:cope_x_studio/services/web_server/web_server_notification_service.dart';
import 'package:cope_x_studio/providers/security_provider.dart';
import 'package:cope_x_studio/services/storage_roots.dart';
import 'package:cope_x_studio/utils/network_utils.dart';
import 'package:cope_x_studio/utils/app_path_utils.dart';
import 'package:cope_x_studio/utils/file_type_utils.dart';
import 'package:cope_x_studio/utils/path_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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

  void attachSecurity(SecurityProvider security) => _security = security;

  final List<AppTab> _tabs = [];
  String? _activeTabId;
  FileClipboardEntry? _clipboard;
  String? _statusMessage;
  final List<String> _logHistory = [];
  bool _storageGranted = false;
  bool _permissionChecked = false;
  bool _showHidden = false;

  final List<RecentFileEntry> _recentFiles = [];
  bool _recentLoading = false;
  int _recentScanGeneration = 0;

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
  final Set<String> _shellLoadingPaths = {};
  bool isShellLoading(String path) => _shellLoadingPaths.contains(path);
  String? getShellError(String path) => _shellErrors[path];

  final Map<String, List<InstalledAppInfo>> _appsCache = {};
  final Map<String, Uint8List> _appIcons = {};
  bool _appsLoading = false;
  String? _appsError;
  int _appsLoadGeneration = 0;
  bool get isAppsLoading => _appsLoading;
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

  bool _isBusy = false;
  bool get isBusy => _isBusy;

  final Map<String, String> _zipPasswords = {};
  final Map<String, String> _zipErrors = {};
  final Map<String, List<BrowserEntry>> _zipListCache = {};
  final Set<String> _zipListLoading = {};

  final Map<String, TabFileOperationState> _tabFileOperations = {};

  bool isFileOperationOverlayForTab(String tabId) => _tabFileOperations.containsKey(tabId);

  TabFileOperationState? fileOperationForTab(String tabId) => _tabFileOperations[tabId];

  double archiveProgressForTab(String tabId) =>
      _tabFileOperations[tabId]?.progress ?? 0;

  String? archiveProgressLabelForTab(String tabId) =>
      _tabFileOperations[tabId]?.label;

  bool fileOperationCanCancelForTab(String tabId) =>
      _tabFileOperations[tabId]?.canCancel ?? false;

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

  Future<void> cancelArchiveExtraction([String? tabId]) async {
    final targetTabId = tabId ?? _activeTabId;
    if (targetTabId == null) return;

    final op = _tabFileOperations[targetTabId];
    if (op?.type != TabFileOperation.unzip) return;

    op?.cancelToken?.cancel();
    await _archiveService.abortExtraction();

    final dest = op?.destDir;
    if (dest != null) {
      try {
        final dir = Directory(dest);
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      } catch (_) {}
    }

    _log('Đã hủy giải nén');
    _statusMessage = 'Đã hủy giải nén';
    _endFileOperation(targetTabId);
    if (_tabFileOperations.isEmpty) {
      _setBusy(false);
    }
    notifyListeners();
  }

  void _cancelArchiveExtractionIfActive(String tabId) {
    if (_tabFileOperations[tabId]?.type == TabFileOperation.unzip) {
      unawaited(cancelArchiveExtraction(tabId));
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

  Future<void> unlockZip(String tabId, String zipPath, String password) async {
    _setBusy(true);
    try {
      await _archiveService.verifyZipPassword(zipPath, password);
      _zipPasswords[zipPath] = password;
      _zipErrors.remove(zipPath);
      _archiveService.clearZipCache(zipPath);
      _zipListCache.removeWhere((k, _) => k.startsWith('$zipPath|'));
      _log('Đã mở khóa ZIP: ${p.basename(zipPath)}');
      refreshTab(tabId);
    } catch (e) {
      _zipErrors[zipPath] = e is ArchivePasswordException ? e.toString() : 'Sai mật khẩu';
      _log('Lỗi mở khóa: $e');
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }
  bool get isRecentLoading => _recentLoading;
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
    notifyListeners();
  }

  Future<void> toggleShowHidden() async {
    await setShowHidden(!_showHidden);
  }

  // ── Permissions ──────────────────────────────────────────────

  Future<void> initPermissions() async {
    _permissionChecked = true;

    try {
      const storage = FlutterSecureStorage();
      final saved = await storage.read(key: 'show_hidden');
      _showHidden = saved == 'true';
    } catch (_) {}

    await loadFtpServers();

    if (kIsWeb || Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      _storageGranted = true;
      _ensureInitialTab();
      notifyListeners();
      return;
    }

    if (Platform.isAndroid) {
      _storageGranted = await _permissionService.hasManageExternalStorage();
      if (!_storageGranted) {
        _log('Bật quyền "Truy cập tất cả file" trong Cài đặt');
        await requestManageExternalStorage();
      } else {
        _ensureInitialTab();
      }
    } else {
      _storageGranted = true;
      _ensureInitialTab();
    }
    notifyListeners();
  }

  Future<void> recheckPermissions() async {
    if (!Platform.isAndroid) return;
    final wasGranted = _storageGranted;
    _storageGranted = await _permissionService.hasManageExternalStorage();
    if (!wasGranted && _storageGranted) {
      _log('Đã cấp quyền truy cập tất cả file');
      _ensureInitialTab();
    }
    notifyListeners();
  }

  Future<PermissionResult> requestManageExternalStorage() async {
    await _permissionService.requestManageExternalStorage();
    _storageGranted = await _permissionService.hasManageExternalStorage();
    _permissionChecked = true;
    if (_storageGranted) {
      _log('Đã cấp quyền truy cập tất cả file');
      _ensureInitialTab();
    } else {
      _log('Bật "Cho phép truy cập để quản lý tất cả tệp" trong Cài đặt');
    }
    notifyListeners();
    return _storageGranted ? PermissionResult.granted : PermissionResult.denied;
  }

  Future<void> openAllFilesAccessSettings() =>
      _permissionService.openAllFilesAccessSettings();

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
    _log('Tab mới: ${PathUtils.displayName(browsePath)}');
    notifyListeners();
  }

  void closeTab(String tabId) {
    _cancelArchiveExtractionIfActive(tabId);
    final index = _tabIndex(tabId);
    if (index == -1) return;
    _tabs.removeAt(index);
    if (_activeTabId == tabId) {
      _activeTabId = _tabs.isEmpty ? null : _tabs[index.clamp(0, _tabs.length - 1)].id;
    }
    if (_tabs.isEmpty && _storageGranted) {
      _ensureInitialTab();
    }
    notifyListeners();
  }

  void activateTab(String tabId) {
    if (_tabs.any((t) => t.id == tabId)) {
      _activeTabId = tabId;
      notifyListeners();
    }
  }

  // ── Browser navigation (per tab) ─────────────────────────

  Future<void> navigateTo(String tabId, String path) async {
    _cancelArchiveExtractionIfActive(tabId);
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
      await _refreshRecentForView();
    } else if (AppPathUtils.isAppsList(path)) {
      await _refreshAppsForView(path, tabId: tabId);
    } else if (path == '/' && ShellListService.shouldUseShell(path)) {
      await _loadShellDirectory(tabId, path);
    } else {
      _log(PathUtils.displayName(path));
      notifyListeners();
    }
    if (path == '@recent' || AppPathUtils.isAppsList(path)) {
      _log(PathUtils.displayName(path));
    }
  }

  Future<void> revealFileLocation(String tabId, String filePath) async {
    final parent = PathUtils.parentPath(filePath);
    if (parent == null) return;
    await navigateTo(tabId, parent);
    _log('Vị trí: ${PathUtils.shortDisplayDir(filePath)}');
  }

  void navigateUp(String tabId) {
    _cancelArchiveExtractionIfActive(tabId);
    final tab = _tab(tabId);
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
    _log('Xem ZIP: ${p.basename(zipPath)}');
    notifyListeners();

    try {
      final protected = await _archiveService.isPasswordProtected(zipPath);
      if (protected && !_zipPasswords.containsKey(zipPath)) {
        _zipErrors[zipPath] = 'File nén được bảo vệ bằng mật khẩu';
        notifyListeners();
      }
    } catch (e) {
      _zipErrors[zipPath] = 'Không thể đọc file nén: $e';
      notifyListeners();
    }
  }

  void navigateZipInner(String tabId, String innerPath) {
    _setTab(
      tabId,
      _tab(tabId).copyWith(zipInnerPath: innerPath, clearSelection: true),
    );
    notifyListeners();
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

  void toggleSelection(String tabId, String path) {
    final tab = _tab(tabId);
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
    return const [
      BrowserEntry(
        name: 'Hệ thống',
        path: AppPathUtils.systemListPath,
        isDirectory: true,
        subtitle: 'Ứng dụng hệ thống',
        isVirtual: true,
      ),
      BrowserEntry(
        name: 'Cài đặt',
        path: AppPathUtils.userListPath,
        isDirectory: true,
        subtitle: 'Ứng dụng người dùng cài đặt',
        isVirtual: true,
      ),
    ];
  }

  List<BrowserEntry> _getInstalledAppsEntries(String listPath) {
    final cacheKey = AppPathUtils.isSystemList(listPath) ? 'system' : 'user';
    final apps = _appsCache[cacheKey] ?? [];
    return apps
        .map(
          (app) => BrowserEntry(
            name: app.appName,
            path: app.packageName,
            isDirectory: false,
            size: app.apkSize,
            subtitle: '${app.versionName.isNotEmpty ? 'v${app.versionName}' : 'v${app.versionCode}'} · ${_formatSize(app.apkSize)} · ${app.isSystem ? 'Ứng dụng hệ thống' : 'Ứng dụng người dùng'}',
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
    if (_shellLoadingPaths.contains(path) || _shellDirCache.containsKey(path)) return;
    _scheduleAfterFrame(() => unawaited(_loadShellDirectory(tabId, path)));
  }

  void _scheduleAppsRefresh(String tabId, String listPath) {
    if (_appsLoading) return;
    _scheduleAfterFrame(() => unawaited(_refreshAppsForView(listPath, tabId: tabId)));
  }

  Future<void> _refreshAppsForView(String listPath, {String? tabId}) async {
    await Future<void>.delayed(Duration.zero);

    final cacheKey = AppPathUtils.isSystemList(listPath) ? 'system' : 'user';
    final generation = ++_appsLoadGeneration;
    _appsLoading = true;
    _appsError = null;
    notifyListeners();

    try {
      final apps = await _appManagerService.listApps(systemApps: cacheKey == 'system');
      if (generation != _appsLoadGeneration) return;
      _appsCache[cacheKey] = apps;
      _log('Đã tải ${apps.length} ứng dụng');
      unawaited(_prefetchAppIcons(apps.map((a) => a.packageName).toList()));
    } catch (e) {
      if (generation == _appsLoadGeneration) {
        _appsError = e.toString();
        _log('Lỗi tải ứng dụng: $e');
      }
    } finally {
      if (generation == _appsLoadGeneration) {
        _appsLoading = false;
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

    if (_shellLoadingPaths.contains(path) || _shellDirCache.containsKey(path)) return;

    _shellLoadingPaths.add(path);
    _shellErrors.remove(path);
    notifyListeners();

    try {
      final entries = await _shellListService.listDirectory(path, showHidden: _showHidden);
      _shellDirCache[path] = entries
          .map(
            (entity) => BrowserEntry(
              name: p.basename(entity.path),
              path: entity.path,
              isDirectory: entity.isDirectory,
              size: entity.size,
            ),
          )
          .toList();
      _log('Đã đọc ${entries.length} mục tại Root');
    } catch (e) {
      _shellErrors[path] = e.toString();
      _log('Lỗi đọc Root: $e');
    } finally {
      _shellLoadingPaths.remove(path);
      _setTab(tabId, _tab(tabId).bumpList());
      notifyListeners();
    }
  }

  Future<void> openAppInfo(String packageName) async {
    try {
      await _appManagerService.openAppSettings(packageName);
      _log('Mở thông tin ứng dụng');
      notifyListeners();
    } catch (e) {
      _log('Lỗi mở thông tin ứng dụng: $e');
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
      _log('Đã sao chép APK: ${app.appName}');
    } catch (e) {
      _log('Lỗi sao chép APK: $e');
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
      _log('Chia sẻ APK: ${app.appName}');
    } catch (e) {
      _log('Lỗi chia sẻ APK: $e');
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  Future<void> openAppOnPlayStore(String packageName) async {
    try {
      await _appManagerService.openPlayStore(packageName);
    } catch (e) {
      _log('Lỗi mở Play Store: $e');
      notifyListeners();
    }
  }

  Future<void> backupAppApk(String packageName) async {
    final app = getAppInfo(packageName);
    if (app == null) return;
    _setBusy(true);
    try {
      final path = await _appManagerService.backupApk(app);
      _log('Đã backup APK → $path');
      notifyListeners();
    } catch (e) {
      _log('Lỗi backup APK: $e');
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
      _log('Gỡ cài đặt: ${app?.appName ?? packageName}');
    } catch (e) {
      _log('Lỗi gỡ cài đặt: $e');
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  Future<void> openSelectedApp(String packageName) async {
    _setBusy(true);
    try {
      await _appManagerService.openApp(packageName);
      _log('Khởi chạy ứng dụng: $packageName');
      notifyListeners();
    } catch (e) {
      _log('Lỗi mở ứng dụng: $e');
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

  List<BrowserEntry> _getHomeEntries() {
    final rootSpace = getDiskSpace('/');
    final storageSpace = getDiskSpace('/storage/emulated/0');

    final rootSub = rootSpace != null ? 'Trống ${rootSpace['free']}/${rootSpace['total']}' : '/';
    final storageSub = storageSpace != null ? 'Trống ${storageSpace['free']}/${storageSpace['total']}' : '/storage/emulated/0';

    return [
      BrowserEntry(
        name: 'Bộ nhớ thiết bị',
        path: '/storage/emulated/0',
        isDirectory: true,
        subtitle: storageSub,
        isVirtual: true,
      ),
      BrowserEntry(
        name: 'Root',
        path: '/',
        isDirectory: true,
        subtitle: rootSub,
        isVirtual: true,
      ),
      const BrowserEntry(
        name: 'Các tập tin gần đây',
        path: '@recent',
        isDirectory: true,
        isVirtual: true,
      ),
      const BrowserEntry(
        name: 'Trình quản lý ứng dụng',
        path: '@apps',
        isDirectory: true,
        subtitle: 'Hệ thống · Cài đặt',
        isVirtual: true,
      ),
      const BrowserEntry(
        name: 'FTP',
        path: '@ftp',
        isDirectory: true,
        isVirtual: true,
      ),
    ];
  }

  Future<void> _refreshRecentForView() async {
    final generation = ++_recentScanGeneration;
    _recentLoading = true;
    notifyListeners();

    try {
      final roots = StorageRoots.discover(_permissionService);
      final results = await RecentFilesScanner.scan(
        roots: roots,
        showHidden: _showHidden,
      );
      if (generation != _recentScanGeneration) return;
      _recentFiles
        ..clear()
        ..addAll(results);
      _log('Đã quét ${results.length} tập tin gần đây');
    } catch (e) {
      if (generation == _recentScanGeneration) {
        _log('Lỗi quét tập tin gần đây: $e');
      }
    } finally {
      if (generation == _recentScanGeneration) {
        _recentLoading = false;
        notifyListeners();
      }
    }
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
    final list = <BrowserEntry>[];
    list.add(
      const BrowserEntry(
        name: '+ Thêm máy chủ',
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
    _ftpErrors.remove(cacheKey);

    // Schedule notification for background fetch
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
      await client.connect().timeout(const Duration(seconds: 10));
      if (remotePath.isNotEmpty) {
        final ftpPath = remotePath.startsWith('/') ? remotePath : '/$remotePath';
        await client.fs.changeDirectory(ftpPath);
      }
      final list = await client.fs.listDirectory();
      
      final entries = <BrowserEntry>[];
      for (final item in list) {
        final isDir = item is FtpDirectory;
        final name = item.name;

        // Filter out hidden files
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
    } catch (e) {
      _ftpErrors[cacheKey] = e.toString();
      _log('Lỗi FTP: $e');
    } finally {
      try {
        await client.disconnect();
      } catch (_) {}
      _ftpLoadingPaths.remove(cacheKey);
      notifyListeners();
    }
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
      final items = await _archiveService.listZipContents(zipPath, innerPath, password: pwd);
      if (items.isEmpty) {
        _zipErrors[zipPath] = 'Không đọc được nội dung ZIP (file có thể quá lớn hoặc bị hỏng)';
      } else {
        _zipListCache[key] = items;
        _zipErrors.remove(zipPath);
      }
    } catch (e) {
      final errorMsg = e is ArchivePasswordException
          ? e.toString()
          : 'Không thể đọc file nén: $e';
      if (e is ArchivePasswordException) {
        _zipPasswords.remove(zipPath);
      }
      _zipErrors[zipPath] = errorMsg;
      _log('Lỗi đọc ZIP: $e');
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
      items = _getHomeEntries();
    } else if (tab.currentPath == '@recent') {
      items = _getRecentEntries();
    } else if (tab.currentPath == '@apps') {
      items = _getAppsHomeEntries();
    } else if (AppPathUtils.isAppsList(tab.currentPath)) {
      items = _getInstalledAppsEntries(tab.currentPath);
      if (items.isEmpty && !_appsLoading && _appsError == null) {
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
        if (ShellListService.shouldUseShell(tab.currentPath)) {
          if (_shellDirCache.containsKey(tab.currentPath)) {
            items = _shellDirCache[tab.currentPath]!;
          } else {
            _scheduleShellLoad(tabId, tab.currentPath);
            return [];
          }
        } else {
          items = listDirectory(tab.currentPath).map((entity) {
            final isDir = entity is Directory;
            int? size;
            if (entity is File) {
              try {
                size = entity.statSync().size;
              } catch (_) {}
            }
            return BrowserEntry(
              name: p.basename(entity.path),
              path: entity.path,
              isDirectory: isDir,
              size: size,
            );
          }).toList();
        }
      } on FileAccessException {
        rethrow;
      }
    }

    final q = tab.searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      items = items.where((e) => e.name.toLowerCase().contains(q)).toList();
    }
    return items;
  }

  void refreshTab(String tabId) {
    final tab = _tab(tabId);
    if (tab.currentPath == '@recent') {
      unawaited(_refreshRecentForView());
      return;
    }
    if (tab.currentPath == '@ftp') {
      unawaited(_refreshFtpList(tabId));
      return;
    }
    if (AppPathUtils.isAppsList(tab.currentPath)) {
      _appsCache.remove(AppPathUtils.isSystemList(tab.currentPath) ? 'system' : 'user');
      _appsError = null;
      unawaited(_refreshAppsForView(tab.currentPath, tabId: tabId));
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
      unawaited(_loadZipListing(tabId, tab.zipArchivePath!, tab.zipInnerPath));
      return;
    }
    if (ShellListService.shouldUseShell(tab.currentPath)) {
      _shellDirCache.remove(tab.currentPath);
      unawaited(_loadShellDirectory(tabId, tab.currentPath));
      return;
    }
    if (tab.currentPath.startsWith('@ftp/')) {
      _ftpCache.remove(tab.currentPath);
    }
    _setTab(tabId, _tab(tabId).bumpList());
    notifyListeners();
  }

  Future<void> _refreshFtpList(String tabId) async {
    await loadFtpServers();
    _setTab(tabId, _tab(tabId).bumpList());
    notifyListeners();
  }

  void closeEditorInTab(String tabId) {
    _setTab(
      tabId,
      _tab(tabId).copyWith(mode: TabMode.browser, clearEditor: true),
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
      _log('Đã mở ${p.basename(filePath)}');
      notifyListeners();
    } catch (e) {
      _log('Lỗi mở file: $e');
      notifyListeners();
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
      _log('Lỗi tải tệp FTP: $e');
      return null;
    } finally {
      await client.disconnect();
    }
  }

  List<String> getMediaFilesOfSameType(String filePath) {
    final isImg = FileTypeUtils.isImage(filePath);
    final isVid = FileTypeUtils.isVideo(filePath);
    final isAud = FileTypeUtils.isAudio(filePath);

    if (filePath.startsWith('@ftp/')) {
      final parentPath = p.dirname(filePath).replaceAll('\\', '/');
      final entries = _ftpCache[parentPath] ?? [];
      return entries
          .where((e) => !e.isDirectory)
          .map((e) => e.path)
          .where((path) {
            if (isImg) return FileTypeUtils.isImage(path);
            if (isVid) return FileTypeUtils.isVideo(path);
            if (isAud) return FileTypeUtils.isAudio(path);
            return false;
          })
          .toList();
    } else {
      final parentDir = p.dirname(filePath);
      try {
        final entities = _fileService.listDirectory(parentDir, showHidden: _showHidden);
        return entities
            .whereType<File>()
            .map((f) => f.path)
            .where((path) {
              if (isImg) return FileTypeUtils.isImage(path);
              if (isVid) return FileTypeUtils.isVideo(path);
              if (isAud) return FileTypeUtils.isAudio(path);
              return false;
            })
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
        content = utf8.decode(bytes, allowMalformed: true);
      } finally {
        await client.disconnect();
      }
    } else {
      content = await _fileService.readText(filePath);
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
        _log('Tạo file mới: $name');
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
      _log('Tạo file mới: $name');
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
        _log('Tạo thư mục mới: $name');
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
      _log('Tạo thư mục mới: $name');
      refreshTab(id);
      return folderPath;
    }
  }

  void copyToClipboard(List<String> paths) {
    _clipboard = FileClipboardEntry(paths: paths, operation: ClipboardOperation.copy);
    _log('Đã copy ${paths.length} mục');
    notifyListeners();
  }

  void cutToClipboard(List<String> paths) {
    _clipboard = FileClipboardEntry(paths: paths, operation: ClipboardOperation.cut);
    _log('Đã cut ${paths.length} mục');
    notifyListeners();
  }

  Future<void> pasteTo(String tabId, String destinationDir) async {
    if (_clipboard == null || _clipboard!.paths.isEmpty) return;
    final tab = _tab(tabId);
    if (tab.isZipViewer) {
      _log('Không thể paste vào bên trong ZIP');
      notifyListeners();
      return;
    }
    final isFtp = destinationDir.startsWith('@ftp/');
    if (isFtp) {
      _ftpLoadingPaths.add(destinationDir);
    }
    _setBusy(true);
    try {
      _log('Đang thực hiện dán...');
      notifyListeners();

      final isMove = _clipboard!.operation == ClipboardOperation.cut;
      for (final srcPath in _clipboard!.paths) {
        await _transferSinglePath(srcPath, destinationDir, isMove: isMove);
      }

      if (isMove) {
        _clipboard = null;
      }
      _log('Đã dán thành công');
      clearSelection(tabId);
      refreshTab(tabId);
    } catch (e) {
      _log('Lỗi paste: $e');
      notifyListeners();
    } finally {
      if (isFtp) {
        _ftpLoadingPaths.remove(destinationDir);
      }
      _setBusy(false);
    }
  }

  Future<void> _transferSinglePath(String sourcePath, String destDir, {required bool isMove}) async {
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
    } else if (srcIsFtp && !destIsFtp) {
      // FTP to Local
      final isDir = _isFtpDirectory(sourcePath);
      if (isDir) {
        await _downloadFtpDirectory(sourcePath, destPath, isMove: isMove);
      } else {
        await _downloadFtpFile(sourcePath, destPath, isMove: isMove);
      }
    } else if (!srcIsFtp && destIsFtp) {
      // Local to FTP
      final isDir = _fileService.isDirectory(sourcePath);
      if (isDir) {
        await _uploadLocalDirectory(sourcePath, destPath, isMove: isMove);
      } else {
        await _uploadLocalFile(sourcePath, destPath, isMove: isMove);
      }
    } else {
      // Local to Local
      if (isMove) {
        await _fileService.movePaths([sourcePath], destDir);
      } else {
        await _fileService.copyPaths([sourcePath], destDir);
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
    _setBusy(true);
    try {
      _log('Đang nhân đôi...');
      notifyListeners();
      for (final path in paths) {
        if (path.startsWith('@ftp/')) {
          final (serverId, remotePath) = _parseFtpPath(path);
          final client = await _connectFtp(serverId);
          try {
            final isDir = _isFtpDirectory(path);
            final dir = p.dirname(remotePath).replaceAll('\\', '/');
            final base = p.basename(remotePath);
            final String newName;
            if (isDir) {
              newName = _uniqueFtpName('@ftp/$serverId/${dir.startsWith('/') ? dir.substring(1) : dir}', '$base - Copy');
              final targetDestPath = p.join(dir, newName).replaceAll('\\', '/');
              await _copyFtpDirectoryWithinServer(client, remotePath, targetDestPath);
            } else {
              final ext = p.extension(base);
              final name = p.basenameWithoutExtension(base);
              newName = _uniqueFtpName('@ftp/$serverId/${dir.startsWith('/') ? dir.substring(1) : dir}', '$name - Copy$ext');
              final targetDestPath = p.join(dir, newName).replaceAll('\\', '/');
              final ftpFile = client.getFile(remotePath);
              await ftpFile.copy(targetDestPath);
            }
          } finally {
            await client.disconnect();
          }
        } else {
          await _fileService.duplicate(path);
        }
      }
      _log('Đã nhân đôi ${paths.length} mục');
      clearSelection(tabId);
      refreshTab(tabId);
    } catch (e) {
      _log('Lỗi nhân đôi: $e');
      notifyListeners();
    } finally {
      if (isFtp) {
        _ftpLoadingPaths.remove(dir);
      }
      _setBusy(false);
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

    _startFileOperation(TabFileOperation.delete, tabId, label: '${paths.length} mục');
    _setBusy(true);
    _statusMessage = 'Đang xóa...';

    try {
      final total = isFtp ? paths.length : await _fileService.countDeletionItemsInPaths(paths);
      final tracker = EntryProgressTracker(total > 0 ? total : paths.length);

      void onDeleteProgress(String name, double progress) {
        _setTabOperationProgress(tabId, progress, name);
        if (_activeTabId == tabId) {
          _statusMessage = 'Đang xóa: $name (${(progress * 100).toStringAsFixed(0)}%)';
        }
        notifyListeners();
      }

      _log('Đang xóa ${paths.length} mục...');
      notifyListeners();

      for (final path in paths) {
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
        } else {
          await _fileService.deletePathWithProgress(path, tracker, onDeleteProgress);
        }
      }

      if (tab.isEditing && tab.editor?.filePath != null) {
        if (paths.any((path) => _norm(path) == _norm(tab.editor!.filePath!))) {
          closeEditorInTab(tabId);
        }
      }
      _log('Đã xóa ${paths.length} mục');
      clearSelection(tabId);
      refreshTab(tabId);
    } catch (e) {
      _log('Lỗi xóa: $e');
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
      _log('Đã đổi tên thành $newName');
      refreshTab(tabId);
    } finally {
      if (isFtp) {
        _ftpLoadingPaths.remove(dir);
        notifyListeners();
      }
    }
  }

  // ── Zip / Unzip / Open with system ─────────────────────────

  Future<void> zipPaths(String tabId, List<String> paths, {String? password}) async {
    if (paths.isEmpty) return;
    final dir = _tab(tabId).currentPath;
    final isFtp = dir.startsWith('@ftp/');
    if (isFtp) {
      _ftpLoadingPaths.add(dir);
    }
    _setBusy(true);
    final baseName = paths.length == 1
        ? '${p.basenameWithoutExtension(paths.first)}.zip'
        : 'archive.zip';

    try {
      _log('Đang nén...');
      notifyListeners();

      if (isFtp) {
        final (serverId, remoteDirPath) = _parseFtpPath(dir);
        final zipName = _uniqueFtpName(dir, baseName);
        
        final tempDir = await Directory.systemTemp.createTemp('cope_zip_');
        final localZipPath = p.join(tempDir.path, zipName);
        
        final List<String> localPathsToZip = [];
        for (final path in paths) {
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
        
        await _archiveService.zipPaths(localPathsToZip, localZipPath, password: password);
        
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
        _log('Đã nén thành $zipName');
      } else {
        final zipName = _fileService.uniqueName(dir, baseName);
        final zipPath = p.join(dir, zipName);
        await _archiveService.zipPaths(paths, zipPath, password: password);
        _log('Đã nén thành $zipName');
      }
      refreshTab(tabId);
    } catch (e) {
      _log('Lỗi nén ZIP: $e');
      notifyListeners();
    } finally {
      if (isFtp) {
        _ftpLoadingPaths.remove(dir);
      }
      _setBusy(false);
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
    _statusMessage = 'Đang giải nén...';
    final folderBaseName = p.basenameWithoutExtension(zipPath);
    String? destDir;

    void onProgress(double progress, String? file) {
      _setTabOperationProgress(tabId, progress.clamp(0.0, 1.0), file ?? p.basename(zipPath));
      if (_activeTabId == tabId && file != null) {
        final pct = (progress * 100).toStringAsFixed(0);
        _statusMessage = 'Giải nén: ${p.basename(file)} ($pct%)';
      }
      notifyListeners();
    }

    try {
      _log('Đang giải nén...');
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
        _log('Đã giải nén vào $folderName');
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
        _log('Đã giải nén vào $folderName');
      }
      refreshTab(tabId);
    } on ArchiveCancelledException {
      _log('Đã hủy giải nén');
      if (destDir != null) {
        try {
          final rollbackDir = Directory(destDir);
          if (await rollbackDir.exists()) {
            await rollbackDir.delete(recursive: true);
          }
        } catch (_) {}
      }
    } catch (e) {
      _log('Lỗi giải nén: $e');
      if (destDir != null) {
        try {
          final rollbackDir = Directory(destDir);
          if (await rollbackDir.exists()) {
            await rollbackDir.delete(recursive: true);
          }
        } catch (_) {}
      }
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
      
      final result = await _openWithService.openWithSystem(finalPath);
      _log(await _openWithService.openResultMessage(result));
      notifyListeners();
    } catch (e) {
      _log('Lỗi mở file: $e');
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  Future<String> _extractZipEntryToTemp(String zipPath, String innerPath, {String? password}) {
    return _archiveService.extractEntryToTemp(zipPath, innerPath, password: password);
  }

  Future<void> openZipFile(String tabId, String zipPath, String innerPath, {String? password}) async {
    _setZipOpening(zipPath, innerPath);
    _statusMessage = 'Đang mở ${p.basename(innerPath)}...';
    _setBusy(true);
    try {
      var pwd = password;
      if (pwd == null || pwd.isEmpty) {
        final protected = await _archiveService.isPasswordProtected(zipPath);
        if (protected) {
          _zipErrors[zipPath] = 'File nén được bảo vệ bằng mật khẩu';
          notifyListeners();
          return;
        }
      }

      _log('Đang mở file từ ZIP...');
      notifyListeners();
      final tempPath = await _extractZipEntryToTemp(zipPath, innerPath, password: pwd);
      await handleFileTap(tabId, tempPath);
    } catch (e) {
      if (e is ArchivePasswordException) {
        _zipErrors[zipPath] = e.toString();
      }
      _log('Lỗi mở file: $e');
      notifyListeners();
    } finally {
      _setZipOpening(null, null);
      _setBusy(false);
    }
  }

  Future<void> shareZipFile(String zipPath, String innerPath, {String? password}) async {
    _setBusy(true);
    try {
      _log('Đang chuẩn bị chia sẻ file từ ZIP...');
      notifyListeners();
      final tempPath = await _extractZipEntryToTemp(zipPath, innerPath, password: password);
      await SharePlus.instance.share(ShareParams(files: [XFile(tempPath)]));
    } catch (e) {
      _log('Lỗi chia sẻ file: $e');
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  Future<void> handleItemTap(String tabId, BrowserEntry entry) async {
    final tab = _tab(tabId);
    if (tab.hasSelection) {
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

    if (!entry.isDirectory && FileTypeUtils.isArchive(entry.path)) {
      if (FileTypeUtils.isZip(entry.path)) {
        openZipView(tabId, entry.path);
      } else if (FileTypeUtils.isTar(entry.path)) {
        await unzipFile(tabId, entry.path);
      } else {
        final format = FileTypeUtils.archiveFormatName(entry.path);
        _log('Định dạng $format chưa được hỗ trợ giải nén trực tiếp.');
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
              final bytes = utf8.encode(editor.content);
              await client.fs.uploadFile(ftpFile, bytes);
            } finally {
              await client.disconnect();
            }
          } else {
            await _fileService.writeText(path, editor.content);
          }
          _setTab(tabId, tab.copyWith(editor: editor.copyWith(filePath: path, title: p.basename(path), isModified: false)));
        case EditorTabType.empty:
        case EditorTabType.pdf:
        case EditorTabType.media:
          return;
      }
      _log('Đã lưu ${p.basename(editor.filePath ?? '')}');
      refreshTab(tabId);
    } catch (e) {
      _log('Lỗi lưu: $e');
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
      final authNote = verifier != null ? ' (có mật khẩu)' : '';
      final url = NetworkUtils.buildPreferredUrl(addresses, WebServerService.port);
      final scopeNote = restrictToRoots ? ' — thư mục: $sharedRoot' : ' — toàn bộ bộ nhớ';
      _log('Web server$authNote: ${url ?? addresses.join(', ')}$scopeNote');
      if (url != null) {
        await WebServerNotificationService.instance.showRunning(url: url);
      }
      notifyListeners();
    } catch (e) {
      _log('Lỗi bật web server: $e');
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
    _log('Đã tắt web server');
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
    WebServerNotificationService.instance.cancel();
    _webServerService.stop();
    super.dispose();
  }
}
