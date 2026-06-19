import 'dart:convert';
import 'dart:io';

import 'package:cope_x_studio/models/app_tab.dart';
import 'package:cope_x_studio/models/browser_entry.dart';
import 'package:cope_x_studio/models/editor_tab.dart';
import 'package:cope_x_studio/models/file_clipboard.dart';
import 'package:cope_x_studio/models/ftp_server_config.dart';
import 'package:cope_x_studio/services/archive_service.dart';
import 'package:cope_x_studio/services/file_service.dart';
import 'package:cope_x_studio/services/language_detector.dart';
import 'package:cope_x_studio/services/open_with_service.dart';
import 'package:cope_x_studio/services/permission_service.dart';
import 'package:cope_x_studio/services/thumbnail_service.dart';
import 'package:cope_x_studio/services/web_server/web_server_service.dart';
import 'package:cope_x_studio/services/web_server/web_server_notification_service.dart';
import 'package:cope_x_studio/providers/security_provider.dart';
import 'package:cope_x_studio/services/storage_roots.dart';
import 'package:cope_x_studio/utils/network_utils.dart';
import 'package:cope_x_studio/utils/file_type_utils.dart';
import 'package:cope_x_studio/utils/path_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
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
  })  : _fileService = fileService ?? FileService(),
        _permissionService = permissionService ?? PermissionService(),
        _archiveService = archiveService ?? ArchiveService(),
        _openWithService = openWithService ?? OpenWithService() {
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

  // FTP State
  final List<FtpServerConfig> _ftpServers = [];
  List<FtpServerConfig> get ftpServers => List.unmodifiable(_ftpServers);

  final Map<String, List<BrowserEntry>> _ftpCache = {};
  final Map<String, String> _ftpErrors = {};
  final Set<String> _ftpLoadingPaths = {};

  bool isFtpLoading(String path) => _ftpLoadingPaths.contains(path);
  String? getFtpError(String path) => _ftpErrors[path];

  List<AppTab> get tabs => List.unmodifiable(_tabs);
  String? get activeTabId => _activeTabId;
  AppTab? get activeTab => _tabs.where((t) => t.id == _activeTabId).firstOrNull;
  FileClipboardEntry? get clipboard => _clipboard;
  String? get statusMessage => _statusMessage;
  List<String> get logHistory => List.unmodifiable(_logHistory);
  bool get storageGranted => _storageGranted;
  bool get permissionChecked => _permissionChecked;
  bool get showHidden => _showHidden;
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

  void navigateTo(String tabId, String path) {
    _setTab(
      tabId,
      _tab(tabId).copyWith(
        currentPath: path,
        mode: TabMode.browser,
        clearEditor: true,
        clearSelection: true,
        clearZip: true,
      ),
    );
    _log(PathUtils.displayName(path));
    notifyListeners();
  }

  void navigateUp(String tabId) {
    final tab = _tab(tabId);
    if (tab.isZipViewer) {
      navigateZipUp(tabId);
      return;
    }

    if (tab.currentPath == '@ftp') {
      navigateTo(tabId, '@home');
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

  void openZipView(String tabId, String zipPath) {
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

  List<String> getSelectedPaths(String tabId) => _tab(tabId).selectedPaths.toList();

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

  Future<void> removeFtpServer(String id) async {
    _ftpServers.removeWhere((s) => s.id == id);
    _ftpCache.removeWhere((key, _) => key.startsWith('$id:'));
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

  List<BrowserEntry> listEntriesForTab(String tabId) {
    final tab = _tab(tabId);
    List<BrowserEntry> items;

    if (tab.currentPath == '@home') {
      items = _getHomeEntries();
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
      try {
        items = _archiveService.listZipDirectory(tab.zipArchivePath!, tab.zipInnerPath);
      } catch (e) {
        _log('Lỗi đọc ZIP: $e');
        notifyListeners();
        return [];
      }
    } else {
      try {
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
    if (tab.currentPath.startsWith('@ftp/')) {
      _ftpCache.remove(tab.currentPath);
    }
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
      notifyListeners();
    }
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
        notifyListeners();
      }
    }
  }

  Future<void> _transferSinglePath(String sourcePath, String destDir, {required bool isMove}) async {
    final name = p.basename(sourcePath);
    final destPath = p.join(destDir, name).replaceAll('\\', '/');
    
    final srcIsFtp = sourcePath.startsWith('@ftp/');
    final destIsFtp = destDir.startsWith('@ftp/');
    
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
      notifyListeners();
    }
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
        notifyListeners();
      }
    }
  }

  Future<void> deletePaths(String tabId, List<String> paths) async {
    final tab = _tab(tabId);
    final dir = tab.currentPath;
    final isFtp = dir.startsWith('@ftp/');
    if (isFtp) {
      _ftpLoadingPaths.add(dir);
      notifyListeners();
    }
    try {
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
        } else {
          await _fileService.delete(path);
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
    } finally {
      if (isFtp) {
        _ftpLoadingPaths.remove(dir);
        notifyListeners();
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

  Future<void> zipPaths(String tabId, List<String> paths) async {
    if (paths.isEmpty) return;
    final dir = _tab(tabId).currentPath;
    final isFtp = dir.startsWith('@ftp/');
    if (isFtp) {
      _ftpLoadingPaths.add(dir);
      notifyListeners();
    }
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
        
        await _archiveService.zipPaths(localPathsToZip, localZipPath);
        
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
        await _archiveService.zipPaths(paths, zipPath);
        _log('Đã nén thành $zipName');
      }
      refreshTab(tabId);
    } catch (e) {
      _log('Lỗi nén ZIP: $e');
      notifyListeners();
    } finally {
      if (isFtp) {
        _ftpLoadingPaths.remove(dir);
        notifyListeners();
      }
    }
  }

  Future<void> zipClipboard(String tabId) async {
    if (_clipboard == null || _clipboard!.paths.isEmpty) return;
    await zipPaths(tabId, _clipboard!.paths);
  }

  Future<void> unzipFile(String tabId, String zipPath) async {
    final dir = _tab(tabId).currentPath;
    final isFtp = dir.startsWith('@ftp/');
    if (isFtp) {
      _ftpLoadingPaths.add(dir);
      notifyListeners();
    }
    final folderBaseName = p.basenameWithoutExtension(zipPath);

    try {
      _log('Đang giải nén...');
      notifyListeners();

      if (isFtp) {
        final (serverId, remoteDirPath) = _parseFtpPath(dir);
        final folderName = _uniqueFtpName(dir, folderBaseName);
        
        final tempDir = await Directory.systemTemp.createTemp('cope_unzip_');
        final localZipName = p.basename(zipPath);
        final localZipPath = p.join(tempDir.path, localZipName);
        
        await _downloadFtpFile(zipPath, localZipPath, isMove: false);
        
        final localUnzippedDir = p.join(tempDir.path, folderName);
        await _archiveService.unzipTo(localZipPath, localUnzippedDir);
        
        final remoteFolderDest = p.join(remoteDirPath, folderName).replaceAll('\\', '/');
        await _uploadLocalDirectory(localUnzippedDir, '@ftp/$serverId/${remoteFolderDest.startsWith('/') ? remoteFolderDest.substring(1) : remoteFolderDest}', isMove: false);
        
        await tempDir.delete(recursive: true);
        _log('Đã giải nén vào $folderName');
      } else {
        final folderName = _fileService.uniqueName(dir, folderBaseName);
        final destDir = p.join(dir, folderName);
        await _archiveService.unzipTo(zipPath, destDir);
        _log('Đã giải nén vào $folderName');
      }
      refreshTab(tabId);
    } catch (e) {
      _log('Lỗi giải nén: $e');
      notifyListeners();
    } finally {
      if (isFtp) {
        _ftpLoadingPaths.remove(dir);
        notifyListeners();
      }
    }
  }

  Future<void> openWithSystem(String filePath) async {
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
        _log('Không thể mở file trong ZIP. Hãy giải nén trước.');
        notifyListeners();
      }
      return;
    }

    if (!entry.isDirectory && FileTypeUtils.isZip(entry.path)) {
      openZipView(tabId, entry.path);
      return;
    }

    if (entry.isDirectory) {
      navigateTo(tabId, entry.path);
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
