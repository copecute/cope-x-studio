import 'dart:async';
import 'dart:io';

import 'package:cope_x_studio/models/app_tab.dart';
import 'package:cope_x_studio/models/browser_entry.dart';
import 'package:cope_x_studio/models/ftp_server_config.dart';
import 'package:cope_x_studio/providers/workspace_provider.dart';
import 'package:cope_x_studio/services/file_service.dart';
import 'package:cope_x_studio/theme/app_sizes.dart';
import 'package:cope_x_studio/theme/vscode_theme.dart';
import 'package:cope_x_studio/utils/app_path_utils.dart';
import 'package:cope_x_studio/utils/file_type_utils.dart';
import 'package:cope_x_studio/utils/path_utils.dart';
import 'package:cope_x_studio/widgets/browser/file_thumbnail.dart';
import 'package:cope_x_studio/widgets/browser/rename_dialog.dart';
import 'package:cope_x_studio/widgets/shell/web_server_sheet.dart';
import 'package:cope_x_studio/widgets/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class BrowserTabView extends StatelessWidget {
  const BrowserTabView({super.key, required this.tab});

  final AppTab tab;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkspaceProvider>();

    if (!provider.storageGranted && provider.permissionChecked) {
      return _PermissionGate(provider: provider);
    }

    final hasZipError = tab.isZipViewer &&
        tab.zipArchivePath != null &&
        provider.getZipError(tab.zipArchivePath!) != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BrowserToolbar(tab: tab),
        if (provider.isFileOperationOverlayForTab(tab.id))
          LinearProgressIndicator(
            minHeight: 2,
            backgroundColor: Colors.transparent,
            value: provider.archiveProgressForTab(tab.id) > 0
                ? provider.archiveProgressForTab(tab.id)
                : null,
            valueColor: const AlwaysStoppedAnimation<Color>(VsCodeColors.accent),
          ),
        if (tab.showSearch) _SearchBar(tab: tab),
        if (tab.hasSelection) _SelectionBar(tab: tab),
        Expanded(
          child: Stack(
            children: [
              hasZipError
                  ? _ZipUnlockView(
                      tab: tab,
                      zipPath: tab.zipArchivePath!,
                      error: provider.getZipError(tab.zipArchivePath!)!,
                    )
                  : _FileListArea(tab: tab),
              if (provider.isFileOperationOverlayForTab(tab.id))
                Positioned.fill(
                  child: Container(
                    color: Colors.black54,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 220,
                              child: LinearProgressIndicator(
                                minHeight: 6,
                                borderRadius: BorderRadius.circular(3),
                                value: provider.archiveProgressForTab(tab.id) > 0
                                    ? provider.archiveProgressForTab(tab.id)
                                    : null,
                                backgroundColor: Colors.white24,
                                valueColor: const AlwaysStoppedAnimation<Color>(VsCodeColors.accent),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              provider.fileOperationOverlayTitleForTab(tab.id),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            if (provider.archiveProgressLabelForTab(tab.id) != null) ...[
                              const SizedBox(height: 10),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Text(
                                  provider.archiveProgressLabelForTab(tab.id)!,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                  style: const TextStyle(
                                    color: VsCodeColors.foregroundDim,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                            if (provider.archiveProgressForTab(tab.id) > 0) ...[
                              const SizedBox(height: 8),
                              Text(
                                '${(provider.archiveProgressForTab(tab.id) * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  color: VsCodeColors.accent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                            if (provider.fileOperationCanCancelForTab(tab.id)) ...[
                              const SizedBox(height: 24),
                              OutlinedButton.icon(
                                onPressed: () => provider.cancelArchiveExtraction(tab.id),
                                icon: const Icon(Icons.close, size: 18),
                                label: const Text('Hủy'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white54),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
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
    return PathUtils.displayName(tab.currentPath);
  }

  bool _canGoUp() {
    if (tab.isZipViewer) return true;
    if (tab.currentPath == '@home') return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkspaceProvider>();
    final isWritable = !tab.currentPath.startsWith('@') || tab.currentPath.startsWith('@ftp/');

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
          if (tab.isZipViewer) ...[
            IconButton(
              icon: const Icon(Icons.unarchive_outlined, size: AppSizes.iconMedium, color: VsCodeColors.accent),
              tooltip: 'Giải nén',
              onPressed: () => _handleUnzip(context, provider, tab.id, tab.zipArchivePath!),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 6),
              child: Icon(Icons.folder_zip, size: 18, color: VsCodeColors.accent),
            ),
          ],
          Expanded(
            child: GestureDetector(
              onLongPress: () async {
                final path = _displayPath();
                await Clipboard.setData(ClipboardData(text: path));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã sao chép đường dẫn: $path'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              },
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  _displayPath(),
                  style: const TextStyle(fontSize: AppSizes.fontSmall, color: VsCodeColors.foregroundDim),
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.search,
              size: AppSizes.iconMedium,
              color: tab.showSearch ? VsCodeColors.accent : null,
            ),
            tooltip: 'Tìm kiếm',
            onPressed: () => provider.toggleShowSearch(tab.id),
          ),
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
                case 'new_file':
                  _createNew(context, provider, isFile: true);
                case 'new_folder':
                  _createNew(context, provider, isFile: false);
                case 'zip_clip':
                  provider.zipClipboard(tab.id);
                case 'zip_folder':
                  if (!tab.isZipViewer) {
                    unawaited(_handleZip(context, provider, tab.id, [tab.currentPath]));
                  }
                case 'clear_selection':
                  provider.clearSelection(tab.id);
                case 'web_server':
                  WebServerSheet.show(context);
                case 'settings':
                  Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const SettingsScreen()));
                case 'toggle_hidden':
                  provider.toggleShowHidden();
              }
            },
            itemBuilder: (context) => [
              if (!tab.isZipViewer && isWritable) ...[
                const PopupMenuItem(
                  value: 'new_file',
                  child: Row(
                    children: [
                      Icon(Icons.note_add_outlined, size: 20),
                      SizedBox(width: 10),
                      Text('File mới'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'new_folder',
                  child: Row(
                    children: [
                      Icon(Icons.create_new_folder_outlined, size: 20),
                      SizedBox(width: 10),
                      Text('Thư mục mới'),
                    ],
                  ),
                ),
              ],
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
              PopupMenuItem(
                value: 'toggle_hidden',
                child: Row(
                  children: [
                    Icon(
                      provider.showHidden ? Icons.visibility_off : Icons.visibility,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(provider.showHidden ? 'Ẩn tệp ẩn' : 'Hiện tệp ẩn'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'web_server',
                child: Row(
                  children: [
                    Icon(Icons.wifi_tethering, size: 20),
                    SizedBox(width: 10),
                    Text('Web Server'),
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

  void _sharePaths(List<String> paths) {
    final localPaths = paths.where((p) => !p.startsWith('@')).toList();
    if (localPaths.isEmpty) return;
    SharePlus.instance.share(ShareParams(
      files: localPaths.map((p) => XFile(p)).toList(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<WorkspaceProvider>();
    final count = tab.selectedPaths.length;
    final paths = provider.getSelectedPaths(tab.id);

    return Container(
      height: 44,
      color: VsCodeColors.selection,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, size: 20, color: Colors.redAccent),
            tooltip: 'Đóng',
            onPressed: () => provider.clearSelection(tab.id),
          ),
          const VerticalDivider(width: 8, color: Colors.white24, indent: 8, endIndent: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const SizedBox(width: 4),
                  Text('$count đã chọn', style: const TextStyle(fontSize: AppSizes.fontSmall, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 16),
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
                  if (count == 1)
                    IconButton(
                      icon: const Icon(Icons.drive_file_rename_outline, size: 20),
                      tooltip: 'Đổi tên',
                      onPressed: () => _renameItem(context, provider, tab.id, paths.first),
                    ),
                  IconButton(
                    icon: const Icon(Icons.folder_zip_outlined, size: 20),
                    tooltip: 'Nén ZIP',
                    onPressed: () => _handleZip(context, provider, tab.id, paths),
                  ),
                  IconButton(
                    icon: const Icon(Icons.share, size: 20),
                    tooltip: 'Chia sẻ',
                    onPressed: () => _sharePaths(paths),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    tooltip: 'Xóa',
                    onPressed: () => provider.deletePaths(tab.id, paths),
                  ),
                ],
              ),
            ),
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

    if (tab.currentPath.startsWith('@ftp/')) {
      final error = provider.getFtpError(tab.currentPath);
      if (error != null) {
        return _EmptyGestureArea(
          tab: tab,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                  const SizedBox(height: 12),
                  Text('Lỗi kết nối FTP:\n$error', textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.refreshTab(tab.id),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      if (provider.isFtpLoading(tab.currentPath) && entries.isEmpty) {
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Đang tải thư mục FTP...',
                style: TextStyle(color: VsCodeColors.foregroundDim),
              ),
            ],
          ),
        );
      }
    }

    if (tab.isZipViewer && provider.isZipListing && entries.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Đang đọc nội dung ZIP...',
              style: TextStyle(color: VsCodeColors.foregroundDim),
            ),
          ],
        ),
      );
    }

    if (tab.currentPath == '/' && provider.isShellLoading('/')) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Đang đọc Root...',
              style: TextStyle(color: VsCodeColors.foregroundDim),
            ),
          ],
        ),
      );
    }

    if (tab.currentPath == '/') {
      final shellError = provider.getShellError('/');
      if (shellError != null && entries.isEmpty) {
        return _EmptyGestureArea(
          tab: tab,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                  const SizedBox(height: 12),
                  Text('Không thể đọc Root:\n$shellError', textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.refreshTab(tab.id),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    if (AppPathUtils.isAppsList(tab.currentPath) && provider.isAppsLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Đang tải danh sách ứng dụng...',
              style: TextStyle(color: VsCodeColors.foregroundDim),
            ),
          ],
        ),
      );
    }

    if (AppPathUtils.isAppsList(tab.currentPath)) {
      final appsError = provider.appsError;
      if (appsError != null && entries.isEmpty) {
        return _EmptyGestureArea(
          tab: tab,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                  const SizedBox(height: 12),
                  Text(
                    'Không thể tải ứng dụng:\n$appsError',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.refreshTab(tab.id),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    if (tab.currentPath == '@recent' && provider.isRecentLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Đang quét tập tin gần đây...',
              style: TextStyle(color: VsCodeColors.foregroundDim),
            ),
          ],
        ),
      );
    }

    if (entries.isEmpty) {
      final emptyText = tab.searchQuery.isNotEmpty
          ? 'Không tìm thấy kết quả'
          : (tab.currentPath == '@recent'
              ? 'Không tìm thấy tập tin gần đây'
              : (AppPathUtils.isAppsList(tab.currentPath)
                  ? 'Không có ứng dụng'
                  : (tab.isZipViewer ? 'ZIP trống' : 'Thư mục trống')));
      return _EmptyGestureArea(
        tab: tab,
        child: Center(child: Text(emptyText, style: const TextStyle(fontSize: 16))),
      );
    }

    final isFtpLoading = tab.currentPath.startsWith('@ftp/') && provider.isFtpLoading(tab.currentPath);
    final isZipOpening = tab.isZipViewer &&
        tab.zipArchivePath != null &&
        provider.isZipOpening(tab.zipArchivePath!);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPress: () => _showBackgroundMenu(context, provider, tab),
      onSecondaryTapDown: (d) => _showBackgroundMenu(context, provider, tab, d.globalPosition),
      child: Stack(
        children: [
          ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) => _FileTile(tab: tab, entry: entries[index]),
          ),
          if (isFtpLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black38,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          if (isZipOpening)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Đang giải nén và mở file...',
                        style: const TextStyle(color: VsCodeColors.foregroundDim, fontSize: 15),
                      ),
                      if (provider.zipOpeningLabel != null) ...[
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            provider.zipOpeningLabel!,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
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

class _AppIconTile extends StatefulWidget {
  const _AppIconTile({required this.packageName});

  final String packageName;

  @override
  State<_AppIconTile> createState() => _AppIconTileState();
}

class _AppIconTileState extends State<_AppIconTile> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<WorkspaceProvider>().ensureAppIcon(widget.packageName);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bytes = context.watch<WorkspaceProvider>().appIcon(widget.packageName);
    if (bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.memory(
          bytes,
          width: AppSizes.thumbSize,
          height: AppSizes.thumbSize,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        ),
      );
    }
    return Icon(Icons.android, size: AppSizes.thumbSize, color: VsCodeColors.accent);
  }
}

class _FileTile extends StatelessWidget {
  const _FileTile({required this.tab, required this.entry});

  final AppTab tab;
  final BrowserEntry entry;

  IconData _getVirtualIcon(String path) {
    if (path == '/storage/emulated/0') return Icons.phone_android_outlined;
    if (path == '/') return Icons.storage_outlined;
    if (path == '@recent') return Icons.access_time_outlined;
    if (path == '@apps') return Icons.apps_outlined;
    if (path == AppPathUtils.systemListPath) return Icons.settings_system_daydream_outlined;
    if (path == AppPathUtils.userListPath) return Icons.install_mobile_outlined;
    if (path == '@ftp') return Icons.settings_ethernet;
    if (path == '@display') return Icons.settings_suggest_outlined;
    if (path == '@add_ftp_server') return Icons.add_circle_outline;
    if (path.startsWith('@ftp/')) return Icons.dns_outlined;
    return Icons.folder;
  }

  Color _getVirtualIconColor(String path) {
    if (path == '/storage/emulated/0') return Colors.cyanAccent;
    if (path == '/') return Colors.orangeAccent;
    if (path == '@recent') return Colors.greenAccent;
    if (path == '@apps') return Colors.purpleAccent;
    if (path == AppPathUtils.systemListPath) return Colors.orangeAccent;
    if (path == AppPathUtils.userListPath) return Colors.lightGreenAccent;
    if (path == '@ftp') return Colors.blueAccent;
    if (path == '@display') return Colors.grey;
    if (path == '@add_ftp_server') return VsCodeColors.accent;
    if (path.startsWith('@ftp/')) return Colors.blueAccent;
    return VsCodeColors.accent;
  }

  bool _isServerOrHomePath(String path) {
    if (path.startsWith('@ftp/')) {
      return path.split('/').length == 2;
    }
    return path.startsWith('@') || path == '/' || path == '/storage/emulated/0';
  }

  Widget _buildLeadingIcon(WorkspaceProvider provider) {
    if (AppPathUtils.isAppPackage(entry.path)) {
      final package = AppPathUtils.packageFromPath(entry.path);
      if (entry.iconBytes != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.memory(
            entry.iconBytes!,
            width: AppSizes.thumbSize,
            height: AppSizes.thumbSize,
            fit: BoxFit.cover,
            gaplessPlayback: true,
          ),
        );
      }
      if (package != null) {
        return _AppIconTile(packageName: package);
      }
      return Icon(Icons.android, size: AppSizes.thumbSize, color: VsCodeColors.accent);
    }
    if (entry.isVirtual && _isServerOrHomePath(entry.path)) {
      return Icon(
        _getVirtualIcon(entry.path),
        size: AppSizes.thumbSize,
        color: _getVirtualIconColor(entry.path),
      );
    }
    if (entry.isZipVirtual) {
      return Icon(
        entry.isDirectory ? Icons.folder : Icons.insert_drive_file,
        size: AppSizes.thumbSize,
        color: entry.isDirectory ? VsCodeColors.accent : VsCodeColors.foregroundDim,
      );
    }
    return FileThumbnail(
      path: entry.path,
      isDirectory: entry.isDirectory,
      size: AppSizes.thumbSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkspaceProvider>();
    final selected = provider.isSelected(tab.id, entry.path);

    return Material(
      color: selected ? VsCodeColors.selection : Colors.transparent,
      child: InkWell(
        onTap: () {
          if (entry.path == '@add_ftp_server') {
            _showFtpServerDialog(context, provider);
          } else if (entry.path == '@display') {
            Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const SettingsScreen()));
          } else {
            provider.handleItemTap(tab.id, entry);
          }
        },
        onLongPress: () {
          if (AppPathUtils.isAppPackage(entry.path)) {
            final box = context.findRenderObject() as RenderBox?;
            final pos = box?.localToGlobal(Offset.zero) ?? Offset.zero;
            _showAppMenu(context, provider, entry, pos);
            return;
          }
          if (tab.currentPath == '@recent' && !entry.isDirectory && !entry.isVirtual) {
            final box = context.findRenderObject() as RenderBox?;
            final pos = box?.localToGlobal(Offset.zero) ?? Offset.zero;
            _showItemMenu(context, provider, tab, entry, pos);
            return;
          }
          if (tab.currentPath == '@ftp' && entry.path.startsWith('@ftp/') && entry.path != '@add_ftp_server') {
            _showFtpServerContextMenu(context, provider, entry);
          } else if (!selected && !tab.hasSelection) {
            provider.toggleSelection(tab.id, entry.path);
          } else {
            provider.toggleSelection(tab.id, entry.path);
          }
        },
        onSecondaryTapDown: (d) {
          if (AppPathUtils.isAppPackage(entry.path)) {
            _showAppMenu(context, provider, entry, d.globalPosition);
            return;
          }
          if (tab.currentPath == '@ftp' && entry.path.startsWith('@ftp/') && entry.path != '@add_ftp_server') {
            _showFtpServerContextMenu(context, provider, entry);
          } else {
            _showItemMenu(context, provider, tab, entry, d.globalPosition);
          }
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: AppSizes.tileHeight),
          padding: const EdgeInsets.symmetric(vertical: 8),
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
                _buildLeadingIcon(provider),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: AppSizes.fontBody)),
                      if (!entry.isDirectory || entry.isVirtual)
                        Text(
                          _entrySubtitle(entry),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: VsCodeColors.foregroundDim),
                        ),
                      if (entry.isVirtual) ...[
                        Builder(
                          builder: (context) {
                            final space = provider.getDiskSpace(entry.path);
                            final pctStr = space?['percent'];
                            final pct = pctStr != null ? int.tryParse(pctStr) : null;
                            if (pct != null) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    value: pct / 100,
                                    backgroundColor: Colors.white12,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      pct > 90 ? Colors.redAccent : VsCodeColors.accent,
                                    ),
                                    minHeight: 4,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
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

  void _showFtpServerContextMenu(BuildContext context, WorkspaceProvider provider, BrowserEntry entry) {
    final serverId = entry.path.substring(5);
    final server = provider.getFtpServer(serverId);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: VsCodeColors.tabBar,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (server != null)
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Chỉnh sửa cấu hình'),
                  onTap: () {
                    Navigator.pop(context);
                    _showFtpServerDialog(context, provider, existing: server);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                title: const Text('Xóa cấu hình máy chủ', style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(context);
                  provider.removeFtpServer(serverId);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFtpServerDialog(
    BuildContext context,
    WorkspaceProvider provider, {
    FtpServerConfig? existing,
  }) {
    final isEdit = existing != null;
    final nameCtrl = TextEditingController(text: existing?.name ?? 'My FTP Server');
    final hostCtrl = TextEditingController(text: existing?.host ?? '');
    final portCtrl = TextEditingController(text: '${existing?.port ?? 21}');
    final userCtrl = TextEditingController(text: existing?.username ?? 'anonymous');
    final passCtrl = TextEditingController(text: existing?.password ?? '');

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: VsCodeColors.tabBar,
          title: Text(isEdit ? 'Chỉnh sửa máy chủ FTP' : 'Thêm máy chủ FTP'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Tên gợi nhớ'),
                ),
                TextField(
                  controller: hostCtrl,
                  decoration: const InputDecoration(labelText: 'Địa chỉ IP / Host'),
                ),
                TextField(
                  controller: portCtrl,
                  decoration: const InputDecoration(labelText: 'Cổng (Port)'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: userCtrl,
                  decoration: const InputDecoration(labelText: 'Tên đăng nhập'),
                ),
                TextField(
                  controller: passCtrl,
                  decoration: const InputDecoration(labelText: 'Mật khẩu'),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                final host = hostCtrl.text.trim();
                if (host.isEmpty) return;
                final port = int.tryParse(portCtrl.text) ?? 21;
                final name = nameCtrl.text.trim().isEmpty ? host : nameCtrl.text.trim();
                final username = userCtrl.text.trim();
                final password = passCtrl.text;

                if (isEdit) {
                  provider.updateFtpServer(
                    existing.copyWith(
                      name: name,
                      host: host,
                      port: port,
                      username: username,
                      password: password,
                    ),
                  );
                } else {
                  provider.addFtpServer(
                    FtpServerConfig(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: name,
                      host: host,
                      port: port,
                      username: username,
                      password: password,
                    ),
                  );
                }
                Navigator.pop(context);
              },
              child: Text(isEdit ? 'Lưu' : 'Thêm'),
            ),
          ],
        );
      },
    );
  }
}

String _entrySubtitle(BrowserEntry entry) {
  if (entry.subtitle != null && entry.subtitle!.isNotEmpty) {
    return entry.subtitle!;
  }
  if (entry.path.startsWith('@ftp/')) {
    if (entry.isDirectory) return '';
    final sizeStr = entry.size != null ? _formatSize(entry.size!) : '';
    final extStr = p.extension(entry.path).replaceFirst('.', '').toUpperCase();
    if (sizeStr.isNotEmpty) {
      return '$sizeStr · $extStr';
    }
    return extStr;
  }
  if (entry.isVirtual) {
    return entry.subtitle ?? '';
  }
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

  if (tab.currentPath == '@home' || tab.currentPath == '@ftp' || tab.currentPath == '@apps' || AppPathUtils.isAppsList(tab.currentPath)) {
    _showMenu(context, position, [
      _menuItem('Làm mới', Icons.refresh, () => provider.refreshTab(tab.id)),
    ]);
    return;
  }

  if (tab.currentPath == '/') {
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

void _showAppMenu(
  BuildContext context,
  WorkspaceProvider provider,
  BrowserEntry entry,
  Offset? position,
) {
  final package = AppPathUtils.packageFromPath(entry.path);
  if (package == null) return;

  _showMenu(context, position, [
    _menuItem('Mở ứng dụng', Icons.launch, () => provider.openSelectedApp(package)),
    _menuItem('Thông tin ứng dụng', Icons.info_outline, () => provider.openAppInfo(package)),
    _menuItem('Sao chép APK', Icons.copy, () => provider.copyAppApk(package)),
    _menuItem('Chia sẻ APK', Icons.share, () => provider.shareAppApk(package)),
    _menuItem('Xem trên Play Store', Icons.shop_outlined, () => provider.openAppOnPlayStore(package)),
    _menuItem('Backup APK (Trích xuất)', Icons.save_alt_outlined, () => provider.extractAppApk(package)),
    _menuItem('Gỡ cài đặt', Icons.delete_outline, () => provider.uninstallSelectedApp(package)),
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
  if (AppPathUtils.isAppPackage(path)) {
    _showAppMenu(context, provider, entry, position);
    return;
  }
  final isArchiveFile = !isDir && !entry.isZipVirtual && FileTypeUtils.isArchive(path);
  final isZipFile = !isDir && !entry.isZipVirtual && FileTypeUtils.isZip(path);
  final hasClipboard = provider.clipboard != null && provider.clipboard!.paths.isNotEmpty;
  final pasteDir = tab.isZipViewer ? null : tab.currentPath;

  _showMenu(context, position, [
    if (tab.currentPath == '@recent' && !isDir)
      _menuItem('Xem vị trí file', Icons.place_outlined, () => provider.revealFileLocation(tab.id, path)),
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
    if (tab.isZipViewer && !isDir) ...[
      _menuItem('Mở file', Icons.edit_document, () => provider.openZipFile(tab.id, tab.zipArchivePath!, path, password: provider.getZipPassword(tab.zipArchivePath!))),
      _menuItem('Chia sẻ', Icons.share, () => provider.shareZipFile(tab.zipArchivePath!, path, password: provider.getZipPassword(tab.zipArchivePath!))),
    ],
    if (isZipFile)
      _menuItem('Xem nội dung ZIP', Icons.folder_zip, () => provider.openZipView(tab.id, path)),
    if (isDir && tab.isZipViewer)
      _menuItem('Mở', Icons.folder_open, () => provider.navigateZipInner(tab.id, path)),
    if (isDir && !tab.isZipViewer)
      _menuItem('Mở', Icons.folder_open, () => provider.navigateTo(tab.id, path)),
    if (!tab.isZipViewer)
      _menuItem('Nén ZIP', Icons.folder_zip_outlined, () => _handleZip(context, provider, tab.id, paths)),
    if (isArchiveFile)
      _menuItem('Giải nén', Icons.unarchive_outlined, () => _handleUnzip(context, provider, tab.id, path)),
    const PopupMenuDivider(),
    if (!tab.isZipViewer) ...[
      _menuItem('Copy', Icons.copy, () => provider.copyToClipboard(paths)),
      _menuItem('Cut', Icons.content_cut, () => provider.cutToClipboard(paths)),
      _menuItem('Paste', Icons.content_paste, () => provider.pasteTo(tab.id, pasteDir!), enabled: hasClipboard),
      _menuItem('Nhân đôi', Icons.control_point_duplicate, () => provider.duplicatePaths(tab.id, paths)),
      if (paths.length == 1)
        _menuItem('Đổi tên', Icons.drive_file_rename_outline, () => _renameItem(context, provider, tab.id, path)),
      _menuItem('Xóa', Icons.delete_outline, () => provider.deletePaths(tab.id, paths)),
    ] else ...[
      _menuItem('Copy', Icons.copy, () => provider.copyToClipboard(paths)),
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

Future<void> _handleZip(BuildContext context, WorkspaceProvider provider, String tabId, List<String> paths) async {
  final password = await _showZipCreateDialog(context);
  if (!context.mounted || password == null) return;
  await provider.zipPaths(tabId, paths, password: password.isEmpty ? null : password);
}

Future<void> _handleUnzip(BuildContext context, WorkspaceProvider provider, String tabId, String path) async {
  if (FileTypeUtils.isRar(path) || FileTypeUtils.is7z(path)) {
    final format = FileTypeUtils.archiveFormatName(path);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Định dạng $format chưa được hỗ trợ giải nén.')),
    );
    return;
  }
  
  if (FileTypeUtils.isTar(path)) {
    await provider.unzipFile(tabId, path);
    return;
  }
  
  final isProtected = await provider.isZipPasswordProtected(path);
  if (!context.mounted) return;
  String? password = provider.getZipPassword(path);
  if (isProtected && (password == null || password.isEmpty)) {
    password = await _showPasswordDialog(context, 'Giải nén file ZIP có mật khẩu');
    if (password == null) return;
  }
  await provider.unzipFile(tabId, path, password: password);
}


Future<String?> _showZipCreateDialog(BuildContext context) {
  return showDialog<String?>(
    context: context,
    builder: (context) => const _ZipPasswordDialog(
      title: 'Nén file ZIP',
      optional: true,
    ),
  );
}


Future<String?> _showPasswordDialog(BuildContext context, String title) {
  return showDialog<String>(
    context: context,
    builder: (context) => _ZipPasswordDialog(title: title),
  );
}

class _ZipPasswordDialog extends StatefulWidget {
  const _ZipPasswordDialog({
    required this.title,
    this.optional = false,
  });

  final String title;
  final bool optional;

  @override
  State<_ZipPasswordDialog> createState() => _ZipPasswordDialogState();
}

class _ZipPasswordDialogState extends State<_ZipPasswordDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: VsCodeColors.sidebar,
      title: Text(
        widget.title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      content: TextField(
        controller: _controller,
        obscureText: true,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: widget.optional ? 'Mật khẩu (tùy chọn)' : 'Mật khẩu',
          labelStyle: const TextStyle(color: Colors.white70),
          border: const OutlineInputBorder(),
          enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
          focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: VsCodeColors.accent)),
        ),
        autofocus: true,
        onSubmitted: (_) => Navigator.pop(context, _controller.text),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy', style: TextStyle(color: Colors.white70)),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          style: FilledButton.styleFrom(backgroundColor: VsCodeColors.accent),
          child: Text(widget.optional ? 'Nén' : 'Đồng ý'),
        ),
      ],
    );
  }
}

class _ZipUnlockView extends StatefulWidget {
  const _ZipUnlockView({
    required this.tab,
    required this.zipPath,
    required this.error,
  });

  final AppTab tab;
  final String zipPath;
  final String error;

  @override
  State<_ZipUnlockView> createState() => _ZipUnlockViewState();
}

class _ZipUnlockViewState extends State<_ZipUnlockView> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<WorkspaceProvider>();
    final isWrongPwd = widget.error.toLowerCase().contains('mật khẩu') ||
        widget.error.toLowerCase().contains('password') ||
        widget.error.toLowerCase().contains('bad crc');

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.lock_outline, size: 56, color: VsCodeColors.accent),
            const SizedBox(height: 16),
            Text(
              p.basename(widget.zipPath),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              isWrongPwd
                  ? 'Mật khẩu sai. Vui lòng nhập lại.'
                  : 'File nén được bảo vệ bằng mật khẩu.',
              style: const TextStyle(fontSize: 14, color: VsCodeColors.foregroundDim),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Mật khẩu',
                hintStyle: TextStyle(color: Colors.white38),
                filled: true,
                fillColor: VsCodeColors.sidebar,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderSide: BorderSide.none),
              ),
              onSubmitted: (_) {
                provider.unlockZip(widget.tab.id, widget.zipPath, _controller.text);
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => provider.navigateUp(widget.tab.id),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                    ),
                    child: const Text('Hủy'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      provider.unlockZip(widget.tab.id, widget.zipPath, _controller.text);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: VsCodeColors.accent,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Mở khóa'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
