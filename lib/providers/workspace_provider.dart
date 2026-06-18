import 'dart:io';

import 'package:cope_x_studio/models/app_tab.dart';
import 'package:cope_x_studio/models/browser_entry.dart';
import 'package:cope_x_studio/models/editor_tab.dart';
import 'package:cope_x_studio/models/file_clipboard.dart';
import 'package:cope_x_studio/services/archive_service.dart';
import 'package:cope_x_studio/services/docx_service.dart';
import 'package:cope_x_studio/services/excel_service.dart';
import 'package:cope_x_studio/services/file_service.dart';
import 'package:cope_x_studio/services/language_detector.dart';
import 'package:cope_x_studio/services/open_with_service.dart';
import 'package:cope_x_studio/services/permission_service.dart';
import 'package:cope_x_studio/services/pptx_service.dart';
import 'package:cope_x_studio/services/thumbnail_service.dart';
import 'package:cope_x_studio/services/web_server/web_server_service.dart';
import 'package:cope_x_studio/providers/security_provider.dart';
import 'package:cope_x_studio/services/storage_roots.dart';
import 'package:cope_x_studio/utils/file_type_utils.dart';
import 'package:cope_x_studio/utils/path_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

class WorkspaceProvider extends ChangeNotifier {
  WorkspaceProvider({
    FileService? fileService,
    DocxService? docxService,
    ExcelService? excelService,
    PptxService? pptxService,
    PermissionService? permissionService,
    ArchiveService? archiveService,
    OpenWithService? openWithService,
    WebServerService? webServerService,
  })  : _fileService = fileService ?? FileService(),
        _docxService = docxService ?? DocxService(),
        _excelService = excelService ?? ExcelService(),
        _pptxService = pptxService ?? PptxService(),
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
  final DocxService _docxService;
  final ExcelService _excelService;
  final PptxService _pptxService;
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

  List<AppTab> get tabs => List.unmodifiable(_tabs);
  String? get activeTabId => _activeTabId;
  AppTab? get activeTab => _tabs.where((t) => t.id == _activeTabId).firstOrNull;
  FileClipboardEntry? get clipboard => _clipboard;
  String? get statusMessage => _statusMessage;
  List<String> get logHistory => List.unmodifiable(_logHistory);
  bool get storageGranted => _storageGranted;
  bool get permissionChecked => _permissionChecked;
  bool get isWebServerRunning => _webServerService.isRunning;
  String? get webServerRoot => _webServerService.rootPath;
  List<String> get webServerUrls {
    if (!_webServerService.isRunning) return [];
    return _webServerService.addresses
        .map((a) => 'http://$a:${WebServerService.port}')
        .toList();
  }

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

  String get _defaultPath => PathUtils.defaultBrowsePath(_permissionService);

  int _tabIndex(String tabId) => _tabs.indexWhere((t) => t.id == tabId);

  AppTab _tab(String tabId) => _tabs[_tabIndex(tabId)];

  void _setTab(String tabId, AppTab tab) {
    final i = _tabIndex(tabId);
    if (i == -1) return;
    _tabs[i] = tab;
  }

  // ── Permissions ──────────────────────────────────────────────

  Future<void> initPermissions() async {
    _permissionChecked = true;

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
    final tab = AppTab(currentPath: _defaultPath);
    _tabs.add(tab);
    _activeTabId = tab.id;
  }

  // ── Tabs ───────────────────────────────────────────────────

  void newTab({String? path}) {
    final browsePath = path ?? activeTab?.currentPath ?? _defaultPath;
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

  List<BrowserEntry> listEntriesForTab(String tabId) {
    final tab = _tab(tabId);
    List<BrowserEntry> items;

    if (tab.isZipViewer && tab.zipArchivePath != null) {
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

  List<FileSystemEntity> listDirectory(String dirPath) =>
      _fileService.listDirectory(dirPath);

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

  Future<EditorTab> _loadEditorTab(String filePath) async {
    final ext = p.extension(filePath).toLowerCase();
    switch (ext) {
      case '.docx':
        final bytes = await _fileService.readBytes(filePath);
        return EditorTab(
          type: EditorTabType.docx,
          filePath: filePath,
          title: p.basename(filePath),
          docxParagraphs: _docxService.readParagraphsFromBytes(bytes),
          originalBytes: bytes,
        );
      case '.xlsx':
        final bytes = await _fileService.readBytes(filePath);
        final sheet = _excelService.loadFirstSheetFromBytes(bytes);
        return EditorTab(
          type: EditorTabType.excel,
          filePath: filePath,
          title: p.basename(filePath),
          excelSheetName: sheet.name,
          excelData: sheet.rows,
          originalBytes: bytes,
        );
      case '.pptx':
        final bytes = await _fileService.readBytes(filePath);
        return EditorTab(
          type: EditorTabType.pptx,
          filePath: filePath,
          title: p.basename(filePath),
          pptxSlides: _pptxService.loadSlidesFromBytes(bytes),
          originalBytes: bytes,
        );
      default:
        final content = await _fileService.readText(filePath);
        return EditorTab(
          type: EditorTabType.text,
          filePath: filePath,
          title: p.basename(filePath),
          content: content,
          language: LanguageDetector.detect(filePath),
        );
    }
  }

  Future<String?> createNewFile({String? tabId}) async {
    final id = tabId ?? _activeTabId;
    if (id == null) return null;
    final tab = _tab(id);
    if (tab.isZipViewer) return null;
    final dir = tab.currentPath;
    final name = _fileService.uniqueName(dir, 'untitled.txt');
    final filePath = p.join(dir, name);
    await _fileService.createFile(filePath);
    _log('Tạo file mới: $name');
    refreshTab(id);
    return filePath;
  }

  Future<String?> createNewFolder({String? tabId}) async {
    final id = tabId ?? _activeTabId;
    if (id == null) return null;
    final tab = _tab(id);
    if (tab.isZipViewer) return null;
    final dir = tab.currentPath;
    final name = _fileService.uniqueName(dir, 'New Folder');
    final folderPath = p.join(dir, name);
    await _fileService.createFolder(folderPath);
    _log('Tạo thư mục mới: $name');
    refreshTab(id);
    return folderPath;
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
    try {
      if (_clipboard!.operation == ClipboardOperation.copy) {
        await _fileService.copyPaths(_clipboard!.paths, destinationDir);
        _log('Đã paste (copy)');
      } else {
        await _fileService.movePaths(_clipboard!.paths, destinationDir);
        _clipboard = null;
        _log('Đã paste (move)');
      }
      clearSelection(tabId);
      refreshTab(tabId);
    } catch (e) {
      _log('Lỗi paste: $e');
      notifyListeners();
    }
  }

  Future<void> duplicatePaths(String tabId, List<String> paths) async {
    final tab = _tab(tabId);
    if (tab.isZipViewer) return;
    try {
      for (final path in paths) {
        await _fileService.duplicate(path);
      }
      _log('Đã nhân đôi ${paths.length} mục');
      clearSelection(tabId);
      refreshTab(tabId);
    } catch (e) {
      _log('Lỗi nhân đôi: $e');
      notifyListeners();
    }
  }

  Future<void> deletePaths(String tabId, List<String> paths) async {
    for (final path in paths) {
      await _fileService.delete(path);
    }
    final tab = _tab(tabId);
    if (tab.isEditing && tab.editor?.filePath != null) {
      if (paths.any((path) => _norm(path) == _norm(tab.editor!.filePath!))) {
        closeEditorInTab(tabId);
      }
    }
    _log('Đã xóa ${paths.length} mục');
    clearSelection(tabId);
    refreshTab(tabId);
  }

  Future<void> renamePath(String tabId, String oldPath, String newName) async {
    final newPath = p.join(p.dirname(oldPath), newName);
    await _fileService.renameEntity(oldPath, newPath);
    ThumbnailService.instance.evict(oldPath);
    final tab = _tab(tabId);
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
  }

  // ── Zip / Unzip / Open with system ─────────────────────────

  Future<void> zipPaths(String tabId, List<String> paths) async {
    if (paths.isEmpty) return;
    final dir = _tab(tabId).currentPath;
    final baseName = paths.length == 1
        ? '${p.basenameWithoutExtension(paths.first)}.zip'
        : 'archive.zip';
    final zipName = _fileService.uniqueName(dir, baseName);
    final zipPath = p.join(dir, zipName);

    try {
      _log('Đang nén...');
      notifyListeners();
      await _archiveService.zipPaths(paths, zipPath);
      _log('Đã nén thành $zipName');
      refreshTab(tabId);
    } catch (e) {
      _log('Lỗi nén ZIP: $e');
      notifyListeners();
    }
  }

  Future<void> zipClipboard(String tabId) async {
    if (_clipboard == null || _clipboard!.paths.isEmpty) return;
    await zipPaths(tabId, _clipboard!.paths);
  }

  Future<void> unzipFile(String tabId, String zipPath) async {
    final dir = _tab(tabId).currentPath;
    final folderName = _fileService.uniqueName(
      dir,
      p.basenameWithoutExtension(zipPath),
    );
    final destDir = p.join(dir, folderName);

    try {
      _log('Đang giải nén...');
      notifyListeners();
      await _archiveService.unzipTo(zipPath, destDir);
      _log('Đã giải nén vào $folderName');
      refreshTab(tabId);
    } catch (e) {
      _log('Lỗi giải nén: $e');
      notifyListeners();
    }
  }

  Future<void> openWithSystem(String filePath) async {
    try {
      final result = await _openWithService.openWithSystem(filePath);
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
    if (FileTypeUtils.isEditableInApp(filePath)) {
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

  void updateDocxParagraphs(String tabId, List<String> paragraphs) {
    final tab = _tab(tabId);
    if (tab.editor == null) return;
    _setTab(tabId, tab.copyWith(editor: tab.editor!.copyWith(docxParagraphs: paragraphs, isModified: true)));
    notifyListeners();
  }

  void updateExcelData(String tabId, List<List<String>> data) {
    final tab = _tab(tabId);
    if (tab.editor == null) return;
    _setTab(tabId, tab.copyWith(editor: tab.editor!.copyWith(excelData: data, isModified: true)));
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
          await _fileService.writeText(path, editor.content);
          _setTab(tabId, tab.copyWith(editor: editor.copyWith(filePath: path, title: p.basename(path), isModified: false)));
        case EditorTabType.docx:
          var path = editor.filePath!;
          await _docxService.saveParagraphs(path, editor.docxParagraphs, originalBytes: editor.originalBytes);
          final bytes = await _fileService.readBytes(path);
          _setTab(tabId, tab.copyWith(editor: editor.copyWith(isModified: false, originalBytes: bytes)));
        case EditorTabType.excel:
          var path = editor.filePath!;
          await _excelService.saveSheet(path, editor.excelSheetName ?? 'Sheet1', editor.excelData, originalBytes: editor.originalBytes);
          final bytes = await _fileService.readBytes(path);
          _setTab(tabId, tab.copyWith(editor: editor.copyWith(isModified: false, originalBytes: bytes)));
        case EditorTabType.pptx:
          _log('PowerPoint chỉ hỗ trợ xem');
          notifyListeners();
          return;
        case EditorTabType.empty:
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
      final roots = StorageRoots.discover(_permissionService);
      final defaultRoot = StorageRoots.defaultRoot(_permissionService);
      Future<bool> Function(String password)? verifier;
      if (_security != null && _security!.hasPassword) {
        verifier = (pwd) => _security!.verifyPassword(pwd);
      }
      final addresses = await _webServerService.start(
        defaultRoot: defaultRoot,
        knownRoots: roots,
        asyncPasswordVerifier: verifier,
      );
      final authNote = verifier != null ? ' (có mật khẩu)' : '';
      final urls = addresses.map((a) => 'http://$a:${WebServerService.port}').join(', ');
      _log('Web server$authNote: $urls — toàn quyền bộ nhớ');
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
    _log('Đã tắt web server');
    notifyListeners();
  }

  @override
  void dispose() {
    _webServerService.stop();
    super.dispose();
  }
}
