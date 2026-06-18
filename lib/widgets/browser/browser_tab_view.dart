import 'dart:io';

import 'package:cope_x_studio/models/app_tab.dart';
import 'package:cope_x_studio/models/browser_entry.dart';
import 'package:cope_x_studio/providers/workspace_provider.dart';
import 'package:cope_x_studio/services/file_service.dart';
import 'package:cope_x_studio/theme/app_sizes.dart';
import 'package:cope_x_studio/theme/vscode_theme.dart';
import 'package:cope_x_studio/utils/file_type_utils.dart';
import 'package:cope_x_studio/utils/path_utils.dart';
import 'package:cope_x_studio/widgets/browser/file_thumbnail.dart';
import 'package:cope_x_studio/widgets/browser/rename_dialog.dart';
import 'package:cope_x_studio/widgets/shell/web_server_sheet.dart';
import 'package:cope_x_studio/widgets/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

class BrowserTabView extends StatelessWidget {
  const BrowserTabView({super.key, required this.tab});

  final AppTab tab;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkspaceProvider>();

    if (!provider.storageGranted && provider.permissionChecked) {
      return _PermissionGate(provider: provider);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BrowserToolbar(tab: tab),
        _SearchBar(tab: tab),
        if (tab.hasSelection) _SelectionBar(tab: tab),
        Expanded(child: _FileListArea(tab: tab)),
      ],
    );
  }
}

class _PermissionGate extends StatelessWidget {
  const _PermissionGate({required this.provider});

  final WorkspaceProvider provider;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sd_storage, size: 64, color: VsCodeColors.accent),
            const SizedBox(height: 16),
            const Text(
              'Cần quyền truy cập tất cả file',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Bật MANAGE_EXTERNAL_STORAGE để duyệt toàn bộ bộ nhớ.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: VsCodeColors.foregroundDim),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: provider.requestManageExternalStorage,
              icon: const Icon(Icons.admin_panel_settings),
              label: const Text('Cấp quyền'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrowserToolbar extends StatelessWidget {
  const _BrowserToolbar({required this.tab});

  final AppTab tab;

  String _displayPath() {
    if (tab.isZipViewer && tab.zipArchivePath != null) {
      final zip = tab.zipArchivePath!;
      if (tab.zipInnerPath.isEmpty) return zip;
      return '$zip/${tab.zipInnerPath}';
    }
    return tab.currentPath;
  }

  bool _canGoUp() {
    if (tab.isZipViewer) return true;
    return PathUtils.parentPath(tab.currentPath) != null;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkspaceProvider>();

    return Container(
      height: 50,
      color: VsCodeColors.tabBar,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_upward, size: AppSizes.iconMedium),
            tooltip: 'Thư mục cha',
            onPressed: _canGoUp() ? () => provider.navigateUp(tab.id) : null,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: AppSizes.iconMedium),
            tooltip: 'Làm mới',
            onPressed: () => provider.refreshTab(tab.id),
          ),
          if (tab.isZipViewer)
            const Padding(
              padding: EdgeInsets.only(right: 6),
              child: Icon(Icons.folder_zip, size: 18, color: VsCodeColors.accent),
            ),
          Expanded(
            child: Text(
              _displayPath(),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: AppSizes.fontSmall, color: VsCodeColors.foregroundDim),
            ),
          ),
          if (!tab.isZipViewer) ...[
            IconButton(
              icon: const Icon(Icons.note_add_outlined, size: AppSizes.iconMedium),
              tooltip: 'File mới',
              onPressed: () => _createNew(context, provider, isFile: true),
            ),
            IconButton(
              icon: const Icon(Icons.create_new_folder_outlined, size: AppSizes.iconMedium),
              tooltip: 'Thư mục mới',
              onPressed: () => _createNew(context, provider, isFile: false),
            ),
          ],
          IconButton(
            icon: Icon(
              Icons.wifi_tethering,
              size: AppSizes.iconMedium,
              color: provider.isWebServerRunning ? VsCodeColors.accent : null,
            ),
            tooltip: 'Web Server',
            onPressed: () => WebServerSheet.show(context),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: AppSizes.iconMedium),
            tooltip: 'Thêm',
            onSelected: (value) {
              switch (value) {
                case 'zip_clip':
                  provider.zipClipboard(tab.id);
                case 'zip_folder':
                  if (!tab.isZipViewer) {
                    provider.zipPaths(tab.id, [tab.currentPath]);
                  }
                case 'clear_selection':
                  provider.clearSelection(tab.id);
                case 'web_server':
                  WebServerSheet.show(context);
                case 'settings':
                  Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const SettingsScreen()));
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, size: 20),
                    SizedBox(width: 10),
                    Text('Cài đặt'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'web_server',
                child: Row(
                  children: [
                    Icon(Icons.wifi_tethering, size: 20),
                    SizedBox(width: 10),
                    Text('Web Server (port 2910)'),
                  ],
                ),
              ),
              if (!tab.isZipViewer)
                const PopupMenuItem(
                  value: 'zip_folder',
                  child: Row(
                    children: [
                      Icon(Icons.folder_zip_outlined, size: 20),
                      SizedBox(width: 10),
                      Text('Nén thư mục hiện tại'),
                    ],
                  ),
                ),
              if (provider.clipboard != null && provider.clipboard!.paths.isNotEmpty)
                const PopupMenuItem(
                  value: 'zip_clip',
                  child: Row(
                    children: [
                      Icon(Icons.folder_zip_outlined, size: 20),
                      SizedBox(width: 10),
                      Text('Nén các mục đã copy'),
                    ],
                  ),
                ),
              if (tab.hasSelection)
                const PopupMenuItem(
                  value: 'clear_selection',
                  child: Row(
                    children: [
                      Icon(Icons.deselect, size: 20),
                      SizedBox(width: 10),
                      Text('Bỏ chọn tất cả'),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _createNew(BuildContext context, WorkspaceProvider provider, {required bool isFile}) async {
    final path = isFile
        ? await provider.createNewFile(tabId: tab.id)
        : await provider.createNewFolder(tabId: tab.id);
    if (path == null || !context.mounted) return;

    final newName = await RenameDialog.showForPath(context, path);
    if (newName != null && context.mounted) {
      await provider.renamePath(tab.id, path, newName);
    }
  }
}

class _SearchBar extends StatefulWidget {
  const _SearchBar({required this.tab});

  final AppTab tab;

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.tab.searchQuery);
  }

  @override
  void didUpdateWidget(covariant _SearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tab.id != widget.tab.id && _controller.text != widget.tab.searchQuery) {
      _controller.text = widget.tab.searchQuery;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<WorkspaceProvider>();

    return Container(
      height: 44,
      color: VsCodeColors.tabBar,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: TextField(
        controller: _controller,
        style: const TextStyle(fontSize: AppSizes.fontSmall),
        decoration: InputDecoration(
          hintText: 'Tìm kiếm trong thư mục...',
          hintStyle: const TextStyle(color: VsCodeColors.foregroundDim, fontSize: AppSizes.fontSmall),
          prefixIcon: const Icon(Icons.search, size: 20, color: VsCodeColors.foregroundDim),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _controller.clear();
                    provider.setSearchQuery(widget.tab.id, '');
                  },
                )
              : null,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          filled: true,
          fillColor: const Color(0xFF2A2A2A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (v) => provider.setSearchQuery(widget.tab.id, v),
      ),
    );
  }
}

class _SelectionBar extends StatelessWidget {
  const _SelectionBar({required this.tab});

  final AppTab tab;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<WorkspaceProvider>();
    final count = tab.selectedPaths.length;
    final paths = provider.getSelectedPaths(tab.id);

    return Container(
      height: 44,
      color: VsCodeColors.selection,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Text('$count đã chọn', style: const TextStyle(fontSize: AppSizes.fontSmall, fontWeight: FontWeight.w600)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.copy, size: 20),
            tooltip: 'Copy',
            onPressed: () => provider.copyToClipboard(paths),
          ),
          IconButton(
            icon: const Icon(Icons.content_cut, size: 20),
            tooltip: 'Cut',
            onPressed: () => provider.cutToClipboard(paths),
          ),
          if (!tab.isZipViewer)
            IconButton(
              icon: const Icon(Icons.control_point_duplicate, size: 20),
              tooltip: 'Nhân đôi',
              onPressed: () => provider.duplicatePaths(tab.id, paths),
            ),
          IconButton(
            icon: const Icon(Icons.folder_zip_outlined, size: 20),
            tooltip: 'Nén ZIP',
            onPressed: () => provider.zipPaths(tab.id, paths),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            tooltip: 'Xóa',
            onPressed: () => provider.deletePaths(tab.id, paths),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            tooltip: 'Bỏ chọn',
            onPressed: () => provider.clearSelection(tab.id),
          ),
        ],
      ),
    );
  }
}

class _FileListArea extends StatelessWidget {
  const _FileListArea({required this.tab});

  final AppTab tab;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkspaceProvider>();
    // ignore: unused_local_variable
    final _ = tab.listRevision;

    List<BrowserEntry> entries;
    try {
      entries = provider.listEntriesForTab(tab.id);
    } on FileAccessException catch (e) {
      return _EmptyGestureArea(
        tab: tab,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Không thể đọc thư mục:\n${e.message}', textAlign: TextAlign.center),
          ),
        ),
      );
    }

    if (entries.isEmpty) {
      final emptyText = tab.searchQuery.isNotEmpty
          ? 'Không tìm thấy kết quả'
          : (tab.isZipViewer ? 'ZIP trống' : 'Thư mục trống');
      return _EmptyGestureArea(
        tab: tab,
        child: Center(child: Text(emptyText, style: const TextStyle(fontSize: 16))),
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onLongPress: () => _showBackgroundMenu(context, provider, tab),
            onSecondaryTapDown: (d) => _showBackgroundMenu(context, provider, tab, d.globalPosition),
          ),
        ),
        ListView.builder(
          itemCount: entries.length,
          itemBuilder: (context, index) => _FileTile(tab: tab, entry: entries[index]),
        ),
      ],
    );
  }
}

class _EmptyGestureArea extends StatelessWidget {
  const _EmptyGestureArea({required this.tab, required this.child});

  final AppTab tab;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<WorkspaceProvider>();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: () => _showBackgroundMenu(context, provider, tab),
      onSecondaryTapDown: (d) => _showBackgroundMenu(context, provider, tab, d.globalPosition),
      child: child,
    );
  }
}

class _FileTile extends StatelessWidget {
  const _FileTile({required this.tab, required this.entry});

  final AppTab tab;
  final BrowserEntry entry;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkspaceProvider>();
    final selected = provider.isSelected(tab.id, entry.path);

    return Material(
      color: selected ? VsCodeColors.selection : Colors.transparent,
      child: InkWell(
        onTap: () => provider.handleItemTap(tab.id, entry),
        onLongPress: () {
          if (!selected && !tab.hasSelection) {
            provider.toggleSelection(tab.id, entry.path);
          } else {
            provider.toggleSelection(tab.id, entry.path);
          }
        },
        onSecondaryTapDown: (d) => _showItemMenu(context, provider, tab, entry, d.globalPosition),
        child: SizedBox(
          height: AppSizes.tileHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                if (tab.hasSelection)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Icon(
                      selected ? Icons.check_circle : Icons.circle_outlined,
                      size: 22,
                      color: selected ? VsCodeColors.accent : VsCodeColors.foregroundDim,
                    ),
                  ),
                if (entry.isZipVirtual)
                  Icon(
                    entry.isDirectory ? Icons.folder : Icons.insert_drive_file,
                    size: AppSizes.thumbSize,
                    color: entry.isDirectory ? VsCodeColors.accent : VsCodeColors.foregroundDim,
                  )
                else
                  FileThumbnail(
                    path: entry.path,
                    isDirectory: entry.isDirectory,
                    size: AppSizes.thumbSize,
                  ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: AppSizes.fontBody)),
                      if (!entry.isDirectory)
                        Text(
                          _entrySubtitle(entry),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: VsCodeColors.foregroundDim),
                        ),
                    ],
                  ),
                ),
                if (entry.isDirectory) const Icon(Icons.chevron_right, color: VsCodeColors.foregroundDim),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _entrySubtitle(BrowserEntry entry) {
  if (entry.isZipVirtual && entry.size != null) {
    return _formatSize(entry.size!);
  }
  try {
    final stat = File(entry.path).statSync();
    return '${_formatSize(stat.size)} · ${p.extension(entry.path).replaceFirst('.', '').toUpperCase()}';
  } catch (_) {
    return p.extension(entry.path).replaceFirst('.', '').toUpperCase();
  }
}

String _formatSize(int size) {
  if (size < 1024) return '$size B';
  if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
  if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}

List<String> _targetPaths(WorkspaceProvider provider, AppTab tab, String path) {
  if (tab.hasSelection && provider.isSelected(tab.id, path)) {
    return provider.getSelectedPaths(tab.id);
  }
  return [path];
}

void _showBackgroundMenu(
  BuildContext context,
  WorkspaceProvider provider,
  AppTab tab, [
  Offset? position,
]) {
  if (tab.isZipViewer) {
    _showMenu(context, position, [
      _menuItem('Làm mới', Icons.refresh, () => provider.refreshTab(tab.id)),
    ]);
    return;
  }

  final hasClipboard = provider.clipboard != null && provider.clipboard!.paths.isNotEmpty;
  _showMenu(context, position, [
    _menuItem('Paste', Icons.content_paste, () => provider.pasteTo(tab.id, tab.currentPath), enabled: hasClipboard),
    _menuItem('File mới', Icons.note_add_outlined, () async {
      final path = await provider.createNewFile(tabId: tab.id);
      if (path != null && context.mounted) {
        final name = await RenameDialog.showForPath(context, path);
        if (name != null && context.mounted) await provider.renamePath(tab.id, path, name);
      }
    }),
    _menuItem('Thư mục mới', Icons.create_new_folder_outlined, () async {
      final path = await provider.createNewFolder(tabId: tab.id);
      if (path != null && context.mounted) {
        final name = await RenameDialog.showForPath(context, path);
        if (name != null && context.mounted) await provider.renamePath(tab.id, path, name);
      }
    }),
    _menuItem('Làm mới', Icons.refresh, () => provider.refreshTab(tab.id)),
  ]);
}

void _showItemMenu(
  BuildContext context,
  WorkspaceProvider provider,
  AppTab tab,
  BrowserEntry entry,
  Offset position,
) {
  final paths = _targetPaths(provider, tab, entry.path);
  final isDir = entry.isDirectory;
  final path = entry.path;
  final isZipFile = !isDir && !entry.isZipVirtual && FileTypeUtils.isZip(path);
  final hasClipboard = provider.clipboard != null && provider.clipboard!.paths.isNotEmpty;
  final pasteDir = tab.isZipViewer ? null : tab.currentPath;

  _showMenu(context, position, [
    if (!tab.isZipViewer && !isDir)
      _menuItem('Mở trong app', Icons.edit_document, () {
        if (FileTypeUtils.isEditableInApp(path)) {
          provider.openFileInTab(tab.id, path);
        } else {
          provider.handleFileTap(tab.id, path);
        }
      }),
    if (!tab.isZipViewer && !isDir)
      _menuItem('Mở bằng ứng dụng khác', Icons.open_in_browser, () => provider.openWithSystem(path)),
    if (isZipFile)
      _menuItem('Xem nội dung ZIP', Icons.folder_zip, () => provider.openZipView(tab.id, path)),
    if (isDir && tab.isZipViewer)
      _menuItem('Mở', Icons.folder_open, () => provider.navigateZipInner(tab.id, path)),
    if (isDir && !tab.isZipViewer)
      _menuItem('Mở', Icons.folder_open, () => provider.navigateTo(tab.id, path)),
    if (!tab.isZipViewer)
      _menuItem('Nén ZIP', Icons.folder_zip_outlined, () => provider.zipPaths(tab.id, paths)),
    if (isZipFile)
      _menuItem('Giải nén', Icons.unarchive_outlined, () => provider.unzipFile(tab.id, path)),
    const PopupMenuDivider(),
    if (!tab.isZipViewer) ...[
      _menuItem('Copy', Icons.copy, () => provider.copyToClipboard(paths)),
      _menuItem('Cut', Icons.content_cut, () => provider.cutToClipboard(paths)),
      _menuItem('Paste', Icons.content_paste, () => provider.pasteTo(tab.id, pasteDir!), enabled: hasClipboard),
      _menuItem('Nhân đôi', Icons.control_point_duplicate, () => provider.duplicatePaths(tab.id, paths)),
      if (paths.length == 1)
        _menuItem('Đổi tên', Icons.drive_file_rename_outline, () => _renameItem(context, provider, tab.id, path)),
      _menuItem('Xóa', Icons.delete_outline, () => provider.deletePaths(tab.id, paths)),
    ],
  ]);
}

void _showMenu(BuildContext context, Offset? position, List<PopupMenuEntry<void>> items) {
  final overlaySize = MediaQuery.sizeOf(context);
  final pos = position ?? Offset(overlaySize.width / 2, overlaySize.height / 2);
  showMenu<void>(
    context: context,
    position: RelativeRect.fromLTRB(pos.dx, pos.dy, overlaySize.width - pos.dx, overlaySize.height - pos.dy),
    items: items,
  );
}

PopupMenuItem<void> _menuItem(String label, IconData icon, VoidCallback action, {bool enabled = true}) {
  return PopupMenuItem<void>(
    enabled: enabled,
    onTap: enabled ? () => Future.microtask(action) : null,
    child: Row(children: [Icon(icon, size: 20), const SizedBox(width: 10), Text(label, style: const TextStyle(fontSize: 15))]),
  );
}

Future<void> _renameItem(BuildContext context, WorkspaceProvider provider, String tabId, String path) async {
  final newName = await RenameDialog.showForPath(context, path);
  if (newName != null) {
    await provider.renamePath(tabId, path, newName);
  }
}
