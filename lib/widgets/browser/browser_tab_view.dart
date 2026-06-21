import 'dart:async';
import 'dart:io';

import 'package:cope_x_studio/l10n/model_l10n.dart';
import 'package:cope_x_studio/models/app_tab.dart';
import 'package:cope_x_studio/models/apps_list_watch_state.dart';
import 'package:cope_x_studio/models/browser_entry.dart';
import 'package:cope_x_studio/models/browser_view_mode.dart';
import 'package:cope_x_studio/models/file_open_as.dart';
import 'package:cope_x_studio/models/file_op_notice.dart';
import 'package:cope_x_studio/models/ftp_server_config.dart';
import 'package:cope_x_studio/models/recent_file_entry.dart';
import 'package:intl/intl.dart';
import 'package:cope_x_studio/providers/workspace_provider.dart';
import 'package:cope_x_studio/services/file_service.dart';
import 'package:cope_x_studio/services/shell_list_service.dart';
import 'package:cope_x_studio/theme/app_sizes.dart';
import 'package:cope_x_studio/theme/vscode_theme.dart';
import 'package:cope_x_studio/utils/app_path_utils.dart';
import 'package:cope_x_studio/utils/file_type_utils.dart';
import 'package:cope_x_studio/l10n/l10n_scope.dart';
import 'package:cope_x_studio/utils/l10n_extension.dart';
import 'package:cope_x_studio/utils/path_utils.dart';
import 'package:cope_x_studio/widgets/browser/entry_properties_dialog.dart';
import 'package:cope_x_studio/widgets/browser/file_thumbnail.dart';
import 'package:cope_x_studio/widgets/browser/rename_dialog.dart';
import 'package:cope_x_studio/widgets/browser/tree_browser_view.dart';
import 'package:cope_x_studio/widgets/shell/web_server_sheet.dart';
import 'package:cope_x_studio/widgets/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

class BrowserTabView extends StatelessWidget {
  const BrowserTabView({super.key, required this.tab});

  final AppTab tab;

  @override
  Widget build(BuildContext context) {
    final isAppsList = AppPathUtils.isAppsList(tab.currentPath);
    if (isAppsList) {
      context.select<WorkspaceProvider, AppsListWatchState>(
        (p) => p.appsListWatchState(tab.id, tab.currentPath),
      );
    } else {
      context.watch<WorkspaceProvider>();
    }
    final provider = context.read<WorkspaceProvider>();
    final l10n = context.l10n;

    if (!provider.storageGranted && provider.permissionChecked) {
      return _PermissionGate(provider: provider);
    }

    final hasZipError = tab.isZipViewer &&
        tab.zipArchivePath != null &&
        provider.getZipError(tab.zipArchivePath!) != null;

    return _FileOpNoticeHost(
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BrowserToolbar(tab: tab),
        if (provider.isFileOperationOverlayForTab(tab.id))
          LinearProgressIndicator(
            minHeight: 2,
            backgroundColor: Colors.transparent,
            value: provider.fileOperationIsRollingBackForTab(tab.id)
                ? null
                : (provider.archiveProgressForTab(tab.id) > 0
                    ? provider.archiveProgressForTab(tab.id)
                    : null),
            valueColor: AlwaysStoppedAnimation<Color>(VsCodeColors.accent),
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
                        constraints: const BoxConstraints(maxWidth: 360),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 260,
                              child: LinearProgressIndicator(
                                minHeight: 6,
                                borderRadius: BorderRadius.circular(3),
                                value: provider.fileOperationIsRollingBackForTab(tab.id)
                                    ? null
                                    : (provider.archiveProgressForTab(tab.id) > 0
                                        ? provider.archiveProgressForTab(tab.id)
                                        : null),
                                backgroundColor: Colors.white24,
                                valueColor: AlwaysStoppedAnimation<Color>(VsCodeColors.accent),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              provider.fileOperationOverlayTitleForTab(tab.id),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: _overlayProgressLabelHeight,
                              width: double.infinity,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  provider.fileOperationIsRollingBackForTab(tab.id)
                                      ? l10n.pleaseWait
                                      : (provider.archiveProgressLabelForTab(tab.id) ?? ''),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                  style: _overlayProgressLabelStyle,
                                ),
                              ),
                            ),
                            if (!provider.fileOperationIsRollingBackForTab(tab.id) &&
                                provider.archiveProgressForTab(tab.id) > 0) ...[
                              const SizedBox(height: 8),
                              Text(
                                '${(provider.archiveProgressForTab(tab.id) * 100).toStringAsFixed(0)}%',
                                style: TextStyle(
                                  color: VsCodeColors.accent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                            if (provider.fileOperationCanCancelForTab(tab.id)) ...[
                              const SizedBox(height: 24),
                              OutlinedButton.icon(
                                onPressed: () => provider.cancelFileOperation(tab.id),
                                icon: const Icon(Icons.close, size: 18),
                                label: Text(l10n.cancel),
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
    ),
    );
  }
}

class _FileOpNoticeHost extends StatefulWidget {
  const _FileOpNoticeHost({required this.child});

  final Widget child;

  @override
  State<_FileOpNoticeHost> createState() => _FileOpNoticeHostState();
}

class _FileOpNoticeHostState extends State<_FileOpNoticeHost> {
  late final WorkspaceProvider _workspace;

  @override
  void initState() {
    super.initState();
    _workspace = context.read<WorkspaceProvider>();
    _workspace.addListener(_onProviderChanged);
  }

  @override
  void dispose() {
    _workspace.removeListener(_onProviderChanged);
    super.dispose();
  }

  void _onProviderChanged() {
    if (!mounted) return;
    final notice = _workspace.pendingFileOpNotice;
    if (notice == null) return;

    _workspace.clearPendingFileOpNotice();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showFileOpNotice(context, notice);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

Future<void> _showFileOpNotice(BuildContext context, FileOpNotice notice) {
  final l10n = context.l10n;
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: VsCodeColors.tabBar,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: VsCodeColors.border),
      ),
      title: Row(
        children: [
          Icon(Icons.info_outline, color: VsCodeColors.accent, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              notice.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      content: Text(
        notice.message,
        style: TextStyle(color: VsCodeColors.foregroundDim, fontSize: 14, height: 1.4),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l10n.understood),
        ),
      ],
    ),
  );
}

class _PermissionGate extends StatelessWidget {
  const _PermissionGate({required this.provider});

  final WorkspaceProvider provider;
  
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sd_storage, size: 64, color: VsCodeColors.accent),
            const SizedBox(height: 16),
            Text(
              l10n.storagePermissionTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.storagePermissionBody,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: VsCodeColors.foregroundDim),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: provider.requestManageExternalStorage,
              icon: const Icon(Icons.admin_panel_settings),
              label: Text(l10n.grantPermission),
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
    final l10n = context.l10n;
    final webServerRunning = context.select<WorkspaceProvider, bool>((p) => p.isWebServerRunning);
    final isWritable = !tab.currentPath.startsWith('@') || tab.currentPath.startsWith('@ftp/');

    return Container(
      height: 50,
      color: VsCodeColors.tabBar,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_upward, size: AppSizes.iconMedium),
            tooltip: l10n.parentFolder,
            onPressed: _canGoUp() ? () => provider.navigateUp(tab.id) : null,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: AppSizes.iconMedium),
            tooltip: l10n.refresh,
            onPressed: () => provider.refreshTab(tab.id),
          ),
          if (tab.isZipViewer) ...[
            IconButton(
              icon: Icon(Icons.unarchive_outlined, size: AppSizes.iconMedium, color: VsCodeColors.accent),
              tooltip: l10n.extract,
              onPressed: () => _handleUnzip(context, provider, tab.id, tab.zipArchivePath!),
            ),
            Padding(
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
                      content: Text(l10n.pathCopied(path)),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              },
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  _displayPath(),
                  style: TextStyle(fontSize: AppSizes.fontSmall, color: VsCodeColors.foregroundDim),
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
            tooltip: l10n.search,
            onPressed: () => provider.toggleShowSearch(tab.id),
          ),
          if (!(tab.currentPath == '@photos' || tab.currentPath == '@photos/recent' || provider.isPhotoAlbumPath(tab.currentPath)))
            IconButton(
              icon: Icon(
                _viewModeIcon(provider.browserViewMode),
                size: AppSizes.iconMedium,
              ),
              tooltip: provider.browserViewMode.localizedLabel(l10n),
              onPressed: () {
                provider.toggleViewMode();
              },
            ),
          IconButton(
            icon: Icon(
              Icons.wifi_tethering,
              size: AppSizes.iconMedium,
              color: webServerRunning ? VsCodeColors.accent : null,
            ),
            tooltip: l10n.webServer,
            onPressed: () => WebServerSheet.show(context),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: AppSizes.iconMedium),
            tooltip: l10n.add,
            onSelected: (value) {
              switch (value) {
                case 'new_file':
                  _createNew(context, provider, isFile: true);
                case 'new_folder':
                  _createNew(context, provider, isFile: false);
                case 'zip_clip':
                  final clipPaths = provider.clipboard?.paths;
                  if (clipPaths != null && clipPaths.isNotEmpty) {
                    unawaited(_handleZip(context, provider, tab.id, clipPaths));
                  }
                case 'zip_folder':
                  if (PathUtils.canZipCurrentFolder(
                    tab.currentPath,
                    isZipViewer: tab.isZipViewer,
                  )) {
                    final zipPaths = tab.currentPath == '@recent'
                        ? provider.recentFilePaths
                        : [tab.currentPath];
                    if (zipPaths.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.noFilesToZip)),
                      );
                    } else {
                      unawaited(_handleZip(context, provider, tab.id, zipPaths));
                    }
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
            itemBuilder: (context) {
              final menuL10n = context.l10n;
              return [
              if (!tab.isZipViewer && isWritable) ...[
                PopupMenuItem(
                  value: 'new_file',
                  child: Row(
                    children: [
                      Icon(Icons.note_add_outlined, size: 20),
                      SizedBox(width: 10),
                      Text(menuL10n.newFile),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'new_folder',
                  child: Row(
                    children: [
                      Icon(Icons.create_new_folder_outlined, size: 20),
                      SizedBox(width: 10),
                      Text(menuL10n.newFolder),
                    ],
                  ),
                ),
              ],
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, size: 20),
                    SizedBox(width: 10),
                    Text(menuL10n.settings),
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
                    SizedBox(width: 10),
                    Text(provider.showHidden ? menuL10n.hideHiddenFilesToggle : menuL10n.showHiddenFilesToggle),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'web_server',
                child: Row(
                  children: [
                    Icon(Icons.wifi_tethering, size: 20),
                    SizedBox(width: 10),
                    Text(menuL10n.webServer),
                  ],
                ),
              ),
              if (PathUtils.canZipCurrentFolder(
                tab.currentPath,
                isZipViewer: tab.isZipViewer,
              ))
                PopupMenuItem(
                  value: 'zip_folder',
                  child: Row(
                    children: [
                      Icon(Icons.folder_zip_outlined, size: 20),
                      SizedBox(width: 10),
                      Text(
                        tab.currentPath == '@recent'
                            ? menuL10n.zipRecentFiles
                            : menuL10n.zipCurrentFolder,
                      ),
                    ],
                  ),
                ),
              if (provider.clipboard != null && provider.clipboard!.paths.isNotEmpty)
                PopupMenuItem(
                  value: 'zip_clip',
                  child: Row(
                    children: [
                      Icon(Icons.folder_zip_outlined, size: 20),
                      SizedBox(width: 10),
                      Text(menuL10n.zipCopiedItems),
                    ],
                  ),
                ),
              if (tab.hasSelection)
                PopupMenuItem(
                  value: 'clear_selection',
                  child: Row(
                    children: [
                      Icon(Icons.deselect, size: 20),
                      SizedBox(width: 10),
                      Text(menuL10n.deselectAll),
                    ],
                  ),
                ),
            ];
            },
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
    final l10n = context.l10n;

    return Container(
      height: 44,
      color: VsCodeColors.tabBar,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: TextField(
        controller: _controller,
        style: const TextStyle(fontSize: AppSizes.fontSmall),
        decoration: InputDecoration(
          hintText: l10n.searchInFolder,
          hintStyle: TextStyle(color: VsCodeColors.foregroundDim, fontSize: AppSizes.fontSmall),
          prefixIcon: Icon(Icons.search, size: 20, color: VsCodeColors.foregroundDim),
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
          fillColor: VsCodeColors.hover,
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
    final l10n = context.l10n;
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
            tooltip: l10n.close,
            onPressed: () => provider.clearSelection(tab.id),
          ),
          VerticalDivider(width: 8, color: VsCodeColors.border, indent: 8, endIndent: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const SizedBox(width: 4),
                  Text(l10n.selectedCount(count), style: const TextStyle(fontSize: AppSizes.fontSmall, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    tooltip: l10n.copy,
                    onPressed: () => provider.copyToClipboard(paths),
                  ),
                  IconButton(
                    icon: const Icon(Icons.content_cut, size: 20),
                    tooltip: l10n.cut,
                    onPressed: () => provider.cutToClipboard(paths),
                  ),
                  if (!tab.isZipViewer)
                    IconButton(
                      icon: const Icon(Icons.control_point_duplicate, size: 20),
                      tooltip: l10n.duplicate,
                      onPressed: () => provider.duplicatePaths(tab.id, paths),
                    ),
                  if (count == 1)
                    IconButton(
                      icon: const Icon(Icons.drive_file_rename_outline, size: 20),
                      tooltip: l10n.rename,
                      onPressed: () => _renameItem(context, provider, tab.id, paths.first),
                    ),
                  IconButton(
                    icon: const Icon(Icons.folder_zip_outlined, size: 20),
                    tooltip: l10n.zipFileTitle,
                    onPressed: () => _handleZip(context, provider, tab.id, paths),
                  ),
                  IconButton(
                    icon: const Icon(Icons.share, size: 20),
                    tooltip: l10n.share,
                    onPressed: () => provider.sharePaths(tab.id, paths),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    tooltip: l10n.delete,
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

List<String> _shareableLocalPaths(List<String> paths) {
  return paths.where((path) {
    if (path.startsWith('@') || path.startsWith('zip://')) return false;
    final entity = FileSystemEntity.typeSync(path, followLinks: true);
    return entity == FileSystemEntityType.file || entity == FileSystemEntityType.directory;
  }).toList();
}

class _FileListArea extends StatelessWidget {
  const _FileListArea({required this.tab});

  final AppTab tab;

  @override
  Widget build(BuildContext context) {
    final isAppsList = AppPathUtils.isAppsList(tab.currentPath);
    if (isAppsList) {
      context.select<WorkspaceProvider, AppsListWatchState>(
        (p) => p.appsListWatchState(tab.id, tab.currentPath),
      );
    } else {
      context.watch<WorkspaceProvider>();
    }
    final provider = context.read<WorkspaceProvider>();
    final l10n = context.l10n;
    final liveTab = provider.tabs.where((t) => t.id == tab.id).firstOrNull ?? tab;
    final accessNote = provider.getDirectoryAccessNote(liveTab.currentPath);
    final usesShell = ShellListService.shouldUseShell(liveTab.currentPath, mode: provider.rootAccessMode);

    List<BrowserEntry> entries;
    try {
      entries = provider.listEntriesForTab(liveTab.id);
    } on FileAccessException catch (e) {
      return _wrapWithAccessBanner(
        accessNote ?? (ShellListService.isRootFilesystemPath(tab.currentPath) ? l10n.accessDenied : null),
        _EmptyGestureArea(
          tab: tab,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('${l10n.cannotReadFolder}:\n${e.message}', textAlign: TextAlign.center),
            ),
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
                  Text('${l10n.ftpConnectionError}:\n$error', textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.refreshTab(tab.id),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      if (provider.isFtpLoading(tab.currentPath) && entries.isEmpty && accessNote == null) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                l10n.loadingFtp,
                style: TextStyle(color: VsCodeColors.foregroundDim),
              ),
            ],
          ),
        );
      }
    }

    if (tab.isZipViewer && provider.isZipListing && entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              l10n.loadingZip,
              style: TextStyle(color: VsCodeColors.foregroundDim),
            ),
          ],
        ),
      );
    }

    if (usesShell && provider.isShellLoading(tab.currentPath)) {
      return _wrapWithAccessBanner(
        accessNote,
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                l10n.loadingDirectory,
                style: TextStyle(color: VsCodeColors.foregroundDim),
              ),
            ],
          ),
        ),
      );
    }

    if (tab.currentPath == '/' || usesShell) {
      final shellError = provider.getShellError(tab.currentPath);
      if (shellError != null && entries.isEmpty && accessNote == null) {
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
                    '${l10n.cannotReadPath(PathUtils.displayName(tab.currentPath))}:\n$shellError',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.refreshTab(tab.id),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    if (AppPathUtils.isAppsList(tab.currentPath) && provider.isAppsListLoading(tab.currentPath) && entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              l10n.loadingApps,
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
                    '${l10n.cannotLoadApps}:\n$appsError',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.refreshTab(tab.id),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    if (tab.currentPath == '@home' && provider.isHomeLoading && entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              l10n.scanningStorage,
              style: TextStyle(color: VsCodeColors.foregroundDim),
            ),
          ],
        ),
      );
    }

    if (tab.currentPath == '@recent' && provider.isRecentLoading && entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              l10n.scanningRecent,
              style: TextStyle(color: VsCodeColors.foregroundDim),
            ),
          ],
        ),
      );
    }

    if (tab.currentPath == '@photos') {
      return _PhotosHomeView(tab: tab, entries: entries, isLoading: provider.isPhotosLoading);
    }

    if (tab.currentPath == '@photos/recent') {
      return _PhotoRecentView(
        tab: tab,
        recentFiles: provider.photoRecentFiles,
        isLoading: provider.isPhotoRecentLoading,
      );
    }

    if (provider.isPhotoAlbumPath(liveTab.currentPath)) {
      return _PhotoGalleryView(tab: tab, entries: entries);
    }

    if (entries.isEmpty &&
        !(provider.isTreeView && provider.supportsTreeView(tab))) {
      if (accessNote != null) {
        return _wrapWithAccessBanner(
          accessNote,
          _EmptyGestureArea(
            tab: tab,
            child: Center(
              child: Icon(Icons.lock_outline, size: 48, color: VsCodeColors.foregroundDim),
            ),
          ),
        );
      }
      final emptyText = tab.searchQuery.isNotEmpty
          ? l10n.noSearchResults
          : (tab.currentPath == '@recent'
              ? l10n.noRecentFiles
              : (AppPathUtils.isAppsList(tab.currentPath)
                  ? l10n.noApps
                  : (tab.isZipViewer ? l10n.emptyZip : l10n.emptyFolder)));
      return _EmptyGestureArea(
        tab: tab,
        child: Center(child: Text(emptyText, style: const TextStyle(fontSize: 16))),
      );
    }

    final isFtpLoading = tab.currentPath.startsWith('@ftp/') && provider.isFtpLoading(tab.currentPath);
    final isZipOpening = tab.isZipViewer &&
        tab.zipArchivePath != null &&
        provider.isZipOpening(tab.zipArchivePath!);

    return _wrapWithAccessBanner(
      accessNote,
      GestureDetector(
        behavior: HitTestBehavior.translucent,
        onLongPress: () => _showBackgroundMenu(context, provider, tab),
        onSecondaryTapDown: (d) => _showBackgroundMenu(context, provider, tab, d.globalPosition),
        child: Stack(
          children: [
            provider.browserViewMode == BrowserViewMode.tree &&
                    provider.supportsTreeView(tab)
                ? TreeBrowserView(
                    tab: tab,
                    onEntryTap: (ctx, entry) => _onTreeEntryTap(ctx, provider, tab, entry),
                    onEntryLongPress: (ctx, entry, pos) => _showTreeEntryMenu(ctx, provider, tab, entry, pos),
                    onBackgroundMenu: (ctx, pos) => _showBackgroundMenu(ctx, provider, tab, pos),
                  )
                : provider.isGridView
                ? GridView.builder(
                    padding: const EdgeInsets.all(10),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 110,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.83,
                    ),
                    itemCount: entries.length,
                    itemBuilder: (context, index) => _GridFileTile(
                      key: isAppsList ? ValueKey(entries[index].path) : null,
                      tab: liveTab,
                      entry: entries[index],
                    ),
                  )
                : ListView.builder(
                    addAutomaticKeepAlives: false,
                    addRepaintBoundaries: true,
                    cacheExtent: isAppsList ? 1200 : 250,
                    itemCount: entries.length,
                    itemBuilder: (context, index) => _FileTile(
                      key: isAppsList ? ValueKey(entries[index].path) : null,
                      tab: liveTab,
                      entry: entries[index],
                    ),
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
                          l10n.extractingAndOpening,
                          style: TextStyle(color: VsCodeColors.foregroundDim, fontSize: 15),
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
      ),
    );
  }
}

Widget _wrapWithAccessBanner(String? accessNote, Widget child) {
  if (accessNote == null || accessNote.isEmpty) return child;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(child: child),
      Material(
        color: Colors.redAccent.withValues(alpha: 0.12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.lock_outline, size: 18, color: Colors.redAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  accessNote,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
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

class _PhotosHomeView extends StatelessWidget {
  const _PhotosHomeView({
    required this.tab,
    required this.entries,
    required this.isLoading,
  });

  final AppTab tab;
  final List<BrowserEntry> entries;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<WorkspaceProvider>();
    final l10n = context.l10n;
    final recentEntry = entries.firstWhere(
      (entry) => entry.path == '@photos/recent',
      orElse: () => BrowserEntry(
        name: l10n.shortcutAllImages,
        path: '@photos/recent',
        isDirectory: true,
        isVirtual: true,
        subtitle: l10n.shortcutAllImagesSubtitle,
      ),
    );
    final albumEntries = entries.where((entry) => entry.path != '@photos/recent').toList();

    if (isLoading && entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              l10n.scanningStorage,
              style: TextStyle(color: VsCodeColors.foregroundDim),
            ),
          ],
        ),
      );
    }

    final recentPhotos = provider.photoRecentFiles;
    final hasRecentPhotos = recentPhotos.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.shortcutPhotos,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Material(
            color: VsCodeColors.tabBar,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => provider.navigateTo(tab.id, recentEntry.path),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.photo_library_outlined, size: 28, color: VsCodeColors.accent),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                recentEntry.name,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                recentEntry.subtitle ?? l10n.shortcutAllImagesSubtitle,
                                style: TextStyle(color: VsCodeColors.foregroundDim),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: VsCodeColors.foregroundDim),
                      ],
                    ),
                    if (hasRecentPhotos) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 90,
                        child: GridView.count(
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1,
                          children: recentPhotos
                              .take(6)
                              .map(
                                                  (photo) => Builder(builder: (ctx) {
                                                    final sel = ctx.select<WorkspaceProvider, bool>((p) => p.isSelected(tab.id, photo.path));
                                                    return SizedBox(
                                                      width: 90,
                                                      child: Stack(
                                                        children: [
                                                          InkWell(
                                                            borderRadius: BorderRadius.circular(6),
                                                            onTap: () {
                                                              if (tab.hasSelection) {
                                                                provider.toggleSelection(tab.id, photo.path);
                                                              } else {
                                                                provider.openFileInTab(tab.id, photo.path);
                                                              }
                                                            },
                                                            onLongPress: () {
                                                              final box = ctx.findRenderObject() as RenderBox?;
                                                              final pos = box?.localToGlobal(Offset.zero) ?? Offset.zero;
                                                              final entry = BrowserEntry(name: p.basename(photo.path), path: photo.path, isDirectory: false);
                                                              _showItemMenu(ctx, provider, tab, entry, pos);
                                                            },
                                                            onSecondaryTapDown: (d) {
                                                              final entry = BrowserEntry(name: p.basename(photo.path), path: photo.path, isDirectory: false);
                                                              _showItemMenu(ctx, provider, tab, entry, d.globalPosition);
                                                            },
                                                            child: ClipRRect(
                                                              borderRadius: BorderRadius.circular(6),
                                                              child: FileThumbnail(
                                                                path: photo.path,
                                                                isDirectory: false,
                                                                size: 90,
                                                              ),
                                                            ),
                                                          ),
                                                          if (sel)
                                                            Positioned(
                                                              top: 6,
                                                              right: 6,
                                                              child: Icon(Icons.check_circle, color: VsCodeColors.accent, size: 18),
                                                            ),
                                                        ],
                                                      ),
                                                    );
                                                  }),
                              )
                              .toList(),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 12),
                      Text(
                        l10n.noRecentFiles,
                        style: TextStyle(color: VsCodeColors.foregroundDim),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Albums',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Text(
                albumEntries.isEmpty ? '' : '${albumEntries.length}',
                style: TextStyle(color: VsCodeColors.foregroundDim),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (albumEntries.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 36),
                child: Text(
                  l10n.emptyFolder,
                  style: const TextStyle(fontSize: 15, color: Colors.grey),
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 180,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.95,
              ),
              itemCount: albumEntries.length,
              itemBuilder: (context, index) {
                final entry = albumEntries[index];
                final coverPath = provider.photoAlbumCoverPath(entry.path);
                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => provider.navigateTo(tab.id, entry.path),
                  child: Container(
                    decoration: BoxDecoration(
                      color: VsCodeColors.tabBar,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: coverPath != null
                                ? FileThumbnail(
                                    path: coverPath,
                                    isDirectory: false,
                                    size: 140,
                                  )
                                : Container(
                                    color: VsCodeColors.hover,
                                    child: const Center(
                                      child: Icon(Icons.photo_library_outlined, size: 36),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          entry.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry.childrenCount != null ? '${entry.childrenCount} ảnh' : entry.subtitle ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: VsCodeColors.foregroundDim, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _PhotoRecentView extends StatelessWidget {
  const _PhotoRecentView({
    required this.tab,
    required this.recentFiles,
    required this.isLoading,
  });

  final AppTab tab;
  final List<RecentFileEntry> recentFiles;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (isLoading && recentFiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              l10n.scanningRecent,
              style: TextStyle(color: VsCodeColors.foregroundDim),
            ),
          ],
        ),
      );
    }

    final existingFiles = recentFiles.where((file) => File(file.path).existsSync()).toList();

    if (existingFiles.isEmpty) {
      return Center(
        child: Text(
          l10n.noRecentFiles,
          style: const TextStyle(fontSize: 16),
        ),
      );
    }

    final locale = Localizations.localeOf(context).toString();
    final grouped = <String, List<RecentFileEntry>>{};
    for (final file in existingFiles) {
      final dateKey = DateFormat('dd MMMMM yyyy', locale).format(file.modifiedAt);
      grouped.putIfAbsent(dateKey, () => []).add(file);
    }

    final provider = context.read<WorkspaceProvider>();

    return ListView(
      padding: const EdgeInsets.all(10),
      children: grouped.entries.map((group) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                group.key,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: group.value.map((file) {
                return SizedBox(
                  width: 110,
                  child: Builder(builder: (ctx) {
                    final sel = ctx.select<WorkspaceProvider, bool>((p) => p.isSelected(tab.id, file.path));
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () {
                                if (tab.hasSelection) {
                                  provider.toggleSelection(tab.id, file.path);
                                } else {
                                  provider.openFileInTab(tab.id, file.path);
                                }
                              },
                              onLongPress: () {
                                final box = ctx.findRenderObject() as RenderBox?;
                                final pos = box?.localToGlobal(Offset.zero) ?? Offset.zero;
                                final entry = BrowserEntry(name: p.basename(file.path), path: file.path, isDirectory: false);
                                _showItemMenu(ctx, provider, tab, entry, pos);
                              },
                              onSecondaryTapDown: (d) {
                                final entry = BrowserEntry(name: p.basename(file.path), path: file.path, isDirectory: false);
                                _showItemMenu(ctx, provider, tab, entry, d.globalPosition);
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: FileThumbnail(
                                  path: file.path,
                                  isDirectory: false,
                                  size: 110,
                                ),
                              ),
                            ),
                            if (sel)
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Icon(Icons.check_circle, color: VsCodeColors.accent, size: 20),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          p.basename(file.path),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    );
                  }),
                );
              }).toList(),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _PhotoGalleryView extends StatelessWidget {
  const _PhotoGalleryView({
    required this.tab,
    required this.entries,
  });

  final AppTab tab;
  final List<BrowserEntry> entries;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final imageEntries = entries.where((entry) => !entry.isDirectory && FileTypeUtils.isImage(entry.path) && File(entry.path).existsSync()).toList();
    if (imageEntries.isEmpty) {
      return _EmptyGestureArea(
        tab: tab,
        child: Center(
          child: Text(
            l10n.emptyFolder,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    final items = imageEntries.map((entry) {
      final modifiedAt = File(entry.path).statSync().modified;
      return _PhotoGalleryItem(path: entry.path, modifiedAt: modifiedAt);
    }).toList()
      ..sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));

    final locale = Localizations.localeOf(context).toString();
    final groups = <String, List<_PhotoGalleryItem>>{};
    for (final item in items) {
      final dateKey = DateFormat('dd MMMMM yyyy', locale).format(item.modifiedAt);
      groups.putIfAbsent(dateKey, () => []).add(item);
    }

    return ListView(
      padding: const EdgeInsets.all(10),
      children: groups.entries.map((group) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                group.key,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: group.value.map((item) {
                return SizedBox(
                  width: 110,
                  child: Builder(builder: (ctx) {
                    final sel = ctx.select<WorkspaceProvider, bool>((p) => p.isSelected(tab.id, item.path));
                    return Stack(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            if (tab.hasSelection) {
                              context.read<WorkspaceProvider>().toggleSelection(tab.id, item.path);
                            } else {
                              context.read<WorkspaceProvider>().openFileInTab(tab.id, item.path);
                            }
                          },
                          onLongPress: () {
                            final box = ctx.findRenderObject() as RenderBox?;
                            final pos = box?.localToGlobal(Offset.zero) ?? Offset.zero;
                            final entry = BrowserEntry(name: p.basename(item.path), path: item.path, isDirectory: false);
                            _showItemMenu(ctx, context.read<WorkspaceProvider>(), tab, entry, pos);
                          },
                          onSecondaryTapDown: (d) {
                            final entry = BrowserEntry(name: p.basename(item.path), path: item.path, isDirectory: false);
                            _showItemMenu(ctx, context.read<WorkspaceProvider>(), tab, entry, d.globalPosition);
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: FileThumbnail(
                              path: item.path,
                              isDirectory: false,
                              size: 110,
                            ),
                          ),
                        ),
                        if (sel)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Icon(Icons.check_circle, color: VsCodeColors.accent, size: 20),
                          ),
                      ],
                    );
                  }),
                );
              }).toList(),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _PhotoGalleryItem {
  const _PhotoGalleryItem({required this.path, required this.modifiedAt});

  final String path;
  final DateTime modifiedAt;
}

class _AppIconTile extends StatefulWidget {
  const _AppIconTile({required this.packageName, this.size = AppSizes.thumbSize});

  final String packageName;
  final double size;

  @override
  State<_AppIconTile> createState() => _AppIconTileState();
}

class _AppIconTileState extends State<_AppIconTile> {
  Uint8List? _bytes;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_AppIconTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.packageName != widget.packageName) {
      _bytes = null;
      _loading = false;
      _load();
    }
  }

  Future<void> _load() async {
    final provider = context.read<WorkspaceProvider>();
    final cached = provider.appIcon(widget.packageName);
    if (cached != null) {
      if (mounted) setState(() => _bytes = cached);
      return;
    }
    if (_loading) return;
    _loading = true;
    final bytes = await provider.loadAppIcon(widget.packageName);
    _loading = false;
    if (mounted && bytes != null) {
      setState(() => _bytes = bytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.memory(
          _bytes!,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        ),
      );
    }
    return Icon(Icons.android, size: widget.size, color: VsCodeColors.accent);
  }
}

IconData _getVirtualIcon(String path) {
  if (path == '/storage/emulated/0') return Icons.phone_android_outlined;
  if (path == '/') return Icons.storage_outlined;
  if (path == '@recent') return Icons.access_time_outlined;
  if (path == '@apps') return Icons.apps_outlined;
  if (path == AppPathUtils.systemListPath) return Icons.settings_system_daydream_outlined;
  if (path == AppPathUtils.userListPath) return Icons.install_mobile_outlined;
  if (path == '@ftp') return Icons.settings_ethernet;
  if (path == '@photos') return Icons.photo_library_outlined;
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
  if (path == '@photos') return Colors.pinkAccent;
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

Widget _buildLeadingIcon(WorkspaceProvider provider, BrowserEntry entry, double size) {
  if (AppPathUtils.isAppPackage(entry.path)) {
    final package = AppPathUtils.packageFromPath(entry.path);
    if (package != null) {
      return _AppIconTile(packageName: package, size: size);
    }
    return Icon(Icons.android, size: size, color: VsCodeColors.accent);
  }
  if (entry.isVirtual && _isServerOrHomePath(entry.path)) {
    return Icon(
      _getVirtualIcon(entry.path),
      size: size,
      color: _getVirtualIconColor(entry.path),
    );
  }
  if (entry.isZipVirtual) {
    return Icon(
      entry.isDirectory ? Icons.folder : Icons.insert_drive_file,
      size: size,
      color: entry.isDirectory ? VsCodeColors.accent : VsCodeColors.foregroundDim,
    );
  }
  return FileThumbnail(
    path: entry.path,
    isDirectory: entry.isDirectory,
    size: size,
  );
}

class _FileTile extends StatelessWidget {
  const _FileTile({super.key, required this.tab, required this.entry});

  final AppTab tab;
  final BrowserEntry entry;

  @override
  Widget build(BuildContext context) {
    final selected = context.select<WorkspaceProvider, bool>(
      (p) => p.isSelected(tab.id, entry.path),
    );
    final provider = context.read<WorkspaceProvider>();
    final isSelectable = provider.isSelectable(tab.id, entry);

    return Material(
      color: selected ? VsCodeColors.selection : Colors.transparent,
      child: InkWell(
        onTap: () {
          if (tab.hasSelection && isSelectable) {
            provider.toggleSelection(tab.id, entry.path);
            return;
          }
          if (entry.path == '@add_ftp_server') {
            _showFtpServerDialog(context, provider);
          } else if (entry.path == '@display') {
            Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const SettingsScreen()));
          } else {
            provider.handleItemTap(tab.id, entry);
          }
        },
        onLongPress: () {
          final box = context.findRenderObject() as RenderBox?;
          final pos = box?.localToGlobal(Offset.zero) ?? Offset.zero;
          if (AppPathUtils.isAppPackage(entry.path)) {
            _showAppMenu(context, provider, tab, entry, pos);
            return;
          }
          if (tab.currentPath == '@ftp' && entry.path.startsWith('@ftp/') && entry.path != '@add_ftp_server') {
            _showFtpServerContextMenu(context, provider, entry);
            return;
          }
          if (entry.isVirtual && _isServerOrHomePath(entry.path)) return;
          _showItemMenu(context, provider, tab, entry, pos);
        },
        onSecondaryTapDown: (d) {
          if (AppPathUtils.isAppPackage(entry.path)) {
            _showAppMenu(context, provider, tab, entry, d.globalPosition);
            return;
          }
          if (tab.currentPath == '@ftp' && entry.path.startsWith('@ftp/') && entry.path != '@add_ftp_server') {
            _showFtpServerContextMenu(context, provider, entry);
            return;
          }
          if (entry.isVirtual && _isServerOrHomePath(entry.path)) return;
          _showItemMenu(context, provider, tab, entry, d.globalPosition);
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: AppSizes.tileHeight),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                if (tab.hasSelection && isSelectable)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Icon(
                      selected ? Icons.check_circle : Icons.circle_outlined,
                      size: 22,
                      color: selected ? VsCodeColors.accent : VsCodeColors.foregroundDim,
                    ),
                  ),
                _buildLeadingIcon(provider, entry, AppSizes.thumbSize),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.name,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        style: const TextStyle(fontSize: AppSizes.fontBody, height: 1.3),
                      ),
                      if (_entryShowsSubtitle(entry))
                        Text(
                          _entrySubtitle(context, entry),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: _entrySubtitleColor(entry)),
                        ),
                      if (entry.isVirtual) ...[
                        Builder(
                          builder: (context) {
                            final space = provider.getDiskSpace(provider.diskSpacePathFor(entry.path));
                            final pctStr = space?['percent'];
                            final pct = pctStr != null ? int.tryParse(pctStr) : null;
                            if (pct != null) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    value: pct / 100,
                                    backgroundColor: VsCodeColors.border,
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
                if (entry.isDirectory) Icon(Icons.chevron_right, color: VsCodeColors.foregroundDim),
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
    final l10n = context.l10n;
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
                  title: Text(l10n.editFtpConfig),
                  onTap: () {
                    Navigator.pop(context);
                    _showFtpServerDialog(context, provider, existing: server);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                title: Text(l10n.deleteFtpServer, style: const TextStyle(color: Colors.redAccent)),
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
    final l10n = context.l10n;
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
          title: Text(isEdit ? l10n.editFtpServer : l10n.addFtpServer),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(labelText: l10n.displayName),
                ),
                TextField(
                  controller: hostCtrl,
                  decoration: InputDecoration(labelText: l10n.hostAddress),
                ),
                TextField(
                  controller: portCtrl,
                  decoration: InputDecoration(labelText: l10n.port),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: userCtrl,
                  decoration: InputDecoration(labelText: l10n.username),
                ),
                TextField(
                  controller: passCtrl,
                  decoration: InputDecoration(labelText: l10n.passwordLabel),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
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
              child: Text(isEdit ? l10n.save : l10n.add),
            ),
          ],
        );
      },
    );
  }
}

class _GridFileTile extends StatelessWidget {
  const _GridFileTile({super.key, required this.tab, required this.entry});

  final AppTab tab;
  final BrowserEntry entry;

  @override
  Widget build(BuildContext context) {
    final selected = context.select<WorkspaceProvider, bool>(
      (p) => p.isSelected(tab.id, entry.path),
    );
    final provider = context.read<WorkspaceProvider>();
    final isSelectable = provider.isSelectable(tab.id, entry);

    return Material(
      color: selected ? VsCodeColors.selection : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () {
          if (tab.hasSelection && isSelectable) {
            provider.toggleSelection(tab.id, entry.path);
            return;
          }
          if (entry.path == '@add_ftp_server') {
            _showFtpServerDialog(context, provider);
          } else if (entry.path == '@display') {
            Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const SettingsScreen()));
          } else {
            provider.handleItemTap(tab.id, entry);
          }
        },
        onLongPress: () {
          final box = context.findRenderObject() as RenderBox?;
          final pos = box?.localToGlobal(Offset.zero) ?? Offset.zero;
          if (AppPathUtils.isAppPackage(entry.path)) {
            _showAppMenu(context, provider, tab, entry, pos);
            return;
          }
          if (tab.currentPath == '@ftp' && entry.path.startsWith('@ftp/') && entry.path != '@add_ftp_server') {
            _showFtpServerContextMenu(context, provider, entry);
            return;
          }
          if (entry.isVirtual && _isServerOrHomePath(entry.path)) return;
          _showItemMenu(context, provider, tab, entry, pos);
        },
        onSecondaryTapDown: (d) {
          if (AppPathUtils.isAppPackage(entry.path)) {
            _showAppMenu(context, provider, tab, entry, d.globalPosition);
            return;
          }
          if (tab.currentPath == '@ftp' && entry.path.startsWith('@ftp/') && entry.path != '@add_ftp_server') {
            _showFtpServerContextMenu(context, provider, entry);
            return;
          }
          if (entry.isVirtual && _isServerOrHomePath(entry.path)) return;
          _showItemMenu(context, provider, tab, entry, d.globalPosition);
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildLeadingIcon(provider, entry, 40),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 30,
                    child: Text(
                      entry.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, height: 1.25),
                    ),
                  ),
                  SizedBox(
                    height: 14,
                    child: Text(
                      _entryShowsSubtitle(entry) ? _entrySubtitle(context, entry) : '',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10, color: _entrySubtitleColor(entry)),
                    ),
                  ),
                ],
              ),
            ),
            if (tab.hasSelection && isSelectable)
              Positioned(
                top: 4,
                right: 4,
                child: Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  size: 18,
                  color: selected ? VsCodeColors.accent : VsCodeColors.foregroundDim,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showFtpServerContextMenu(BuildContext context, WorkspaceProvider provider, BrowserEntry entry) {
    final serverId = entry.path.substring(5);
    final server = provider.getFtpServer(serverId);
    final l10n = context.l10n;
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
                  title: Text(l10n.editFtpConfig),
                  onTap: () {
                    Navigator.pop(context);
                    _showFtpServerDialog(context, provider, existing: server);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                title: Text(l10n.deleteFtpServer, style: const TextStyle(color: Colors.redAccent)),
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
    final l10n = context.l10n;
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
          title: Text(isEdit ? l10n.editFtpServer : l10n.addFtpServer),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(labelText: l10n.displayName),
                ),
                TextField(
                  controller: hostCtrl,
                  decoration: InputDecoration(labelText: l10n.hostAddress),
                ),
                TextField(
                  controller: portCtrl,
                  decoration: InputDecoration(labelText: l10n.port),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: userCtrl,
                  decoration: InputDecoration(labelText: l10n.username),
                ),
                TextField(
                  controller: passCtrl,
                  decoration: InputDecoration(labelText: l10n.passwordLabel),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
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
              child: Text(isEdit ? l10n.save : l10n.add),
            ),
          ],
        );
      },
    );
  }
}

String _entrySubtitle(BuildContext context, BrowserEntry entry) {
  final l10n = context.l10n;
  if (entry.accessDenied) {
    return l10n.accessDenied;
  }
  if (entry.subtitle != null && entry.subtitle!.isNotEmpty) {
    return entry.subtitle!;
  }
  if (entry.isDirectory && entry.childrenCount != null) {
    return l10n.itemCount(entry.childrenCount!);
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
    if (entry.isDirectory) return l10n.accessDenied;
    return p.extension(entry.path).replaceFirst('.', '').toUpperCase();
  }
}

bool _entryShowsSubtitle(BrowserEntry entry) {
  return !entry.isDirectory ||
      entry.isVirtual ||
      entry.childrenCount != null ||
      entry.accessDenied ||
      (entry.subtitle != null && entry.subtitle!.isNotEmpty);
}

Color _entrySubtitleColor(BrowserEntry entry) {
  return entry.accessDenied ? Colors.redAccent : VsCodeColors.foregroundDim;
}

String _formatSize(int size) {
  if (size < 1024) return '$size B';
  if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
  if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}

final _overlayProgressLabelStyle = TextStyle(
  color: VsCodeColors.foregroundDim,
  fontSize: 14,
  height: 1.35,
);
const _overlayProgressLabelHeight = 14.0 * 1.35 * 2;

bool _isSpecialVirtualEntry(String path) =>
    path == '@add_ftp_server' || path == '@display';

void _openEntryInNewTab(WorkspaceProvider provider, AppTab tab, BrowserEntry entry) {
  if (tab.isZipViewer && tab.zipArchivePath != null) {
    provider.openZipInNewTab(tab.zipArchivePath!, innerPath: entry.path);
  } else {
    provider.newTab(path: entry.path);
  }
}

IconData _viewModeIcon(BrowserViewMode mode) {
  return switch (mode) {
    BrowserViewMode.list => Icons.view_list,
    BrowserViewMode.grid => Icons.grid_view,
    BrowserViewMode.tree => Icons.account_tree_outlined,
  };
}

void _onTreeEntryTap(
  BuildContext context,
  WorkspaceProvider provider,
  AppTab tab,
  BrowserEntry entry,
) {
  if (entry.isDirectory) {
    final wasExpanded = provider.isTreeExpanded(tab.id, entry.path);
    unawaited(provider.toggleTreeNode(tab.id, entry.path, true).then((_) {
      if (!wasExpanded) {
        if (tab.isZipViewer) {
          provider.navigateZipInner(tab.id, entry.path);
        } else {
          unawaited(provider.navigateTo(tab.id, entry.path));
        }
      }
    }));
    return;
  }
  if (tab.isZipViewer && tab.zipArchivePath != null) {
    unawaited(provider.openZipFile(
      tab.id,
      tab.zipArchivePath!,
      entry.path,
      password: provider.getZipPassword(tab.zipArchivePath!),
    ));
  } else {
    unawaited(provider.handleItemTap(tab.id, entry));
  }
}

void _showTreeEntryMenu(
  BuildContext context,
  WorkspaceProvider provider,
  AppTab tab,
  BrowserEntry entry,
  Offset position,
) {
  if (AppPathUtils.isAppPackage(entry.path)) {
    _showAppMenu(context, provider, tab, entry, position);
    return;
  }
  if (entry.isVirtual && _isServerOrHomePath(entry.path)) return;
  _showItemMenu(context, provider, tab, entry, position);
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
  final l10n = context.l10n;
  if (tab.isZipViewer) {
    _showMenu(context, position, [
      _menuItem(l10n.refresh, Icons.refresh, () => provider.refreshTab(tab.id)),
    ]);
    return;
  }

  if (tab.currentPath == '@home' || tab.currentPath == '@ftp' || tab.currentPath == '@apps' || AppPathUtils.isAppsList(tab.currentPath)) {
    _showMenu(context, position, [
      _menuItem(l10n.refresh, Icons.refresh, () => provider.refreshTab(tab.id)),
    ]);
    return;
  }

  if (tab.currentPath == '/') {
    _showMenu(context, position, [
      _menuItem(l10n.refresh, Icons.refresh, () => provider.refreshTab(tab.id)),
    ]);
    return;
  }

  final hasClipboard = provider.clipboard != null && provider.clipboard!.paths.isNotEmpty;
  _showMenu(context, position, [
    _menuItem(l10n.paste, Icons.content_paste, () => provider.pasteTo(tab.id, tab.currentPath), enabled: hasClipboard),
    _menuItem(l10n.newFile, Icons.note_add_outlined, () async {
      final path = await provider.createNewFile(tabId: tab.id);
      if (path != null && context.mounted) {
        final name = await RenameDialog.showForPath(context, path);
        if (name != null && context.mounted) await provider.renamePath(tab.id, path, name);
      }
    }),
    _menuItem(l10n.newFolder, Icons.create_new_folder_outlined, () async {
      final path = await provider.createNewFolder(tabId: tab.id);
      if (path != null && context.mounted) {
        final name = await RenameDialog.showForPath(context, path);
        if (name != null && context.mounted) await provider.renamePath(tab.id, path, name);
      }
    }),
    _menuItem(l10n.refresh, Icons.refresh, () => provider.refreshTab(tab.id)),
  ]);
}

void _showAppMenu(
  BuildContext context,
  WorkspaceProvider provider,
  AppTab tab,
  BrowserEntry entry,
  Offset? position,
) {
  final package = AppPathUtils.packageFromPath(entry.path);
  if (package == null) return;
  final l10n = context.l10n;

  _showMenu(context, position, [
    _menuItem(l10n.select, Icons.check_circle_outlined, () => provider.toggleSelection(tab.id, entry.path)),
    _menuItem(l10n.selectAll, Icons.select_all, () => provider.selectAll(tab.id)),
    const PopupMenuDivider(),
    _menuItem(l10n.openApp, Icons.launch, () => provider.openSelectedApp(package)),
    _menuItem(l10n.appInfo, Icons.info_outline, () => provider.openAppInfo(package)),
    _menuItem(l10n.copyApk, Icons.copy, () => provider.copyAppApk(package)),
    _menuItem(l10n.shareApk, Icons.share, () => provider.shareAppApk(package)),
    _menuItem(l10n.viewPlayStore, Icons.shop_outlined, () => provider.openAppOnPlayStore(package)),
    _menuItem(l10n.backupApk, Icons.save_alt_outlined, () => provider.extractAppApk(package)),
    _menuItem(l10n.uninstall, Icons.delete_outline, () => provider.uninstallSelectedApp(package)),
  ]);
}

void _openFileAs(
  WorkspaceProvider provider,
  AppTab tab,
  String path,
  FileOpenAs openAs,
) {
  if (tab.isZipViewer) {
    provider.openZipFileAs(
      tab.id,
      tab.zipArchivePath!,
      path,
      openAs,
      password: provider.getZipPassword(tab.zipArchivePath!),
    );
  } else {
    provider.openFileAs(tab.id, path, openAs);
  }
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
    _showAppMenu(context, provider, tab, entry, position);
    return;
  }
  final isArchiveFile = !isDir && !entry.isZipVirtual && FileTypeUtils.isArchive(path);
  final isApkFile = !isDir && !entry.isZipVirtual && FileTypeUtils.isApk(path);
  final hasClipboard = provider.clipboard != null && provider.clipboard!.paths.isNotEmpty;
  final pasteDir = tab.isZipViewer ? null : tab.currentPath;

  final isSelectable = provider.isSelectable(tab.id, entry);
  final shareablePaths = _shareableLocalPaths(paths);
  final multiSelected = paths.length > 1;
  final showCompressZip = !tab.isZipViewer && (multiSelected || !isArchiveFile);
  final showExtractArchive = isArchiveFile && !multiSelected;
  final l10n = context.l10n;

  _showMenu(context, position, [
    if (isSelectable) ...[
      _menuItem(l10n.select, Icons.check_circle_outlined, () => provider.toggleSelection(tab.id, path)),
      _menuItem(l10n.selectAll, Icons.select_all, () => provider.selectAll(tab.id)),
      const PopupMenuDivider(),
    ],
    if (!_isSpecialVirtualEntry(path)) ...[
      _menuItem(l10n.details, Icons.info_outline, () => EntryPropertiesDialog.show(context, tab: tab, entry: entry)),
      if (isDir)
        _menuItem(l10n.openInNewTab, Icons.open_in_new, () => _openEntryInNewTab(provider, tab, entry)),
    ],
    if (tab.currentPath == '@recent' && !isDir)
      _menuItem(l10n.revealLocation, Icons.place_outlined, () => provider.revealFileLocation(tab.id, path)),
    if (!isDir) ...[
      const PopupMenuDivider(),
      _openAsMenuItem(context, provider, tab, path, position),
    ],
    if (!tab.isZipViewer && !isDir)
      _menuItem(l10n.openWithSystem, Icons.open_in_browser, () => provider.openWithSystem(path)),
    if (tab.isZipViewer && !isDir)
      _menuItem(l10n.share, Icons.share, () => provider.shareZipFile(tab.zipArchivePath!, path, password: provider.getZipPassword(tab.zipArchivePath!))),
    if (!tab.isZipViewer && shareablePaths.isNotEmpty)
      _menuItem(l10n.share, Icons.share, () => provider.sharePaths(tab.id, shareablePaths)),
    if (isApkFile && provider.openApkAsZip)
      _menuItem(l10n.installApk, Icons.install_mobile, () => provider.installApkFile(path)),
    if (showCompressZip)
      _menuItem(l10n.zipFileTitle, Icons.folder_zip_outlined, () => _handleZip(context, provider, tab.id, paths)),
    if (showExtractArchive)
      _menuItem(
        '${l10n.extract} ${FileTypeUtils.archiveFormatName(path)}',
        Icons.unarchive_outlined,
        () => _handleUnzip(context, provider, tab.id, path),
      ),
    const PopupMenuDivider(),
    if (!tab.isZipViewer) ...[
      _menuItem(l10n.copy, Icons.copy, () => provider.copyToClipboard(paths)),
      _menuItem(l10n.cut, Icons.content_cut, () => provider.cutToClipboard(paths)),
      _menuItem(l10n.paste, Icons.content_paste, () => provider.pasteTo(tab.id, pasteDir!), enabled: hasClipboard),
      _menuItem(l10n.duplicate, Icons.control_point_duplicate, () => provider.duplicatePaths(tab.id, paths)),
      if (paths.length == 1)
        _menuItem(l10n.rename, Icons.drive_file_rename_outline, () => _renameItem(context, provider, tab.id, path)),
      _menuItem(l10n.delete, Icons.delete_outline, () => provider.deletePaths(tab.id, paths)),
    ] else ...[
      _menuItem(l10n.copy, Icons.copy, () => provider.copyToClipboard(paths)),
    ],
  ]);
}

void _showOpenAsMenu(
  BuildContext context,
  WorkspaceProvider provider,
  AppTab tab,
  String path,
  Offset anchor,
) {
  final l10n = context.l10n;
  final offset = Offset(anchor.dx + 180, anchor.dy);
  _showMenu(context, offset, [
    _menuItem(l10n.openAsText, Icons.article_outlined, () => _openFileAs(provider, tab, path, FileOpenAs.text)),
    _menuItem(l10n.openAsImage, Icons.image_outlined, () => _openFileAs(provider, tab, path, FileOpenAs.image)),
    _menuItem(l10n.openAsAudio, Icons.audiotrack_outlined, () => _openFileAs(provider, tab, path, FileOpenAs.audio)),
    _menuItem(l10n.video, Icons.movie_outlined, () => _openFileAs(provider, tab, path, FileOpenAs.video)),
    _menuItem(l10n.pdf, Icons.picture_as_pdf_outlined, () => _openFileAs(provider, tab, path, FileOpenAs.pdf)),
    _menuItem(l10n.openAsArchive, Icons.folder_zip_outlined, () => _openFileAs(provider, tab, path, FileOpenAs.archive)),
  ]);
}

PopupMenuItem<void> _openAsMenuItem(
  BuildContext context,
  WorkspaceProvider provider,
  AppTab tab,
  String path,
  Offset anchor,
) {
  return PopupMenuItem<void>(
    onTap: () {
      Future.microtask(() {
        if (context.mounted) {
          _showOpenAsMenu(context, provider, tab, path, anchor);
        }
      });
    },
    child: Row(
      children: [
        Icon(Icons.open_in_new, size: 20),
        SizedBox(width: 10),
        Expanded(child: Text(context.l10n.openAs, style: TextStyle(fontSize: 15))),
        Icon(Icons.chevron_right, size: 18, color: VsCodeColors.foregroundDim),
      ],
    ),
  );
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

Future<void> _handleZip(
  BuildContext context,
  WorkspaceProvider provider,
  String tabId,
  List<String> paths,
) async {
  final defaultName = paths.length == 1
      ? '${p.basenameWithoutExtension(paths.first)}.zip'
      : 'archive.zip';
  final options = await _showZipCreateDialog(context, defaultName: defaultName);
  if (!context.mounted || options == null) return;
  await provider.zipPaths(
    tabId,
    paths,
    zipName: options.fileName,
    password: options.password,
  );
}

Future<void> _handleUnzip(BuildContext context, WorkspaceProvider provider, String tabId, String path) async {
  final l10n = context.l10n;
  if (FileTypeUtils.isRar(path) || FileTypeUtils.is7z(path)) {
    final format = FileTypeUtils.archiveFormatName(path);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.formatNotSupportedExtract(format))),
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
    password = await _showPasswordDialog(context, l10n.zipPasswordExtractTitle);
    if (password == null) return;
  }
  await provider.unzipFile(tabId, path, password: password);
}


class _ZipCreateResult {
  const _ZipCreateResult({required this.fileName, this.password});

  final String fileName;
  final String? password;
}

Future<_ZipCreateResult?> _showZipCreateDialog(
  BuildContext context, {
  required String defaultName,
}) {
  return showDialog<_ZipCreateResult>(
    context: context,
    builder: (context) => _ZipCreateDialog(defaultName: defaultName),
  );
}


Future<String?> _showPasswordDialog(BuildContext context, String title) {
  return showDialog<String>(
    context: context,
    builder: (context) => _ZipPasswordDialog(title: title),
  );
}

class _ZipCreateDialog extends StatefulWidget {
  const _ZipCreateDialog({required this.defaultName});

  final String defaultName;

  @override
  State<_ZipCreateDialog> createState() => _ZipCreateDialogState();
}

class _ZipCreateDialogState extends State<_ZipCreateDialog> {
  late final TextEditingController _nameController;
  final _passwordController = TextEditingController();
  bool _usePassword = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.defaultName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final password = _usePassword ? _passwordController.text : null;
    Navigator.pop(
      context,
      _ZipCreateResult(
        fileName: name,
        password: password != null && password.isNotEmpty ? password : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      backgroundColor: VsCodeColors.sidebar,
      title: Text(
        l10n.zipFileTitle,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _nameController,
            style: TextStyle(color: VsCodeColors.foreground),
            decoration: InputDecoration(
              labelText: l10n.fileName,
              labelStyle: TextStyle(color: VsCodeColors.foregroundDim),
              border: const OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: VsCodeColors.border)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: VsCodeColors.accent)),
            ),
            autofocus: true,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.passwordProtect),
            value: _usePassword,
            onChanged: (v) => setState(() => _usePassword = v),
          ),
          if (_usePassword)
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: TextStyle(color: VsCodeColors.foreground),
              decoration: InputDecoration(
                labelText: l10n.passwordLabel,
                labelStyle: TextStyle(color: VsCodeColors.foregroundDim),
                border: const OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: VsCodeColors.border)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: VsCodeColors.accent)),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: VsCodeColors.foregroundDim,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              onSubmitted: (_) => _submit(),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel, style: TextStyle(color: VsCodeColors.foregroundDim)),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(backgroundColor: VsCodeColors.accent),
          child: Text(l10n.compress),
        ),
      ],
    );
  }
}

class _ZipPasswordDialog extends StatefulWidget {
  const _ZipPasswordDialog({
    required this.title,
    // ignore: unused_element_parameter
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
    final l10n = context.l10n;
    return AlertDialog(
      backgroundColor: VsCodeColors.sidebar,
      title: Text(
        widget.title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      content: TextField(
        controller: _controller,
        obscureText: true,
        style: TextStyle(color: VsCodeColors.foreground),
        decoration: InputDecoration(
          labelText: widget.optional ? l10n.passwordOptional : l10n.passwordLabel,
          labelStyle: TextStyle(color: VsCodeColors.foregroundDim),
          border: const OutlineInputBorder(),
          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: VsCodeColors.border)),
          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: VsCodeColors.accent)),
        ),
        autofocus: true,
        onSubmitted: (_) => Navigator.pop(context, _controller.text),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel, style: TextStyle(color: VsCodeColors.foregroundDim)),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          style: FilledButton.styleFrom(backgroundColor: VsCodeColors.accent),
          child: Text(widget.optional ? l10n.compress : l10n.ok),
        ),
      ],
    );
  }
}

bool _isWrongZipPasswordError(String error) {
  if (error.toLowerCase().contains('bad crc')) return true;
  final l10n = L10nScope.current;
  if (error == l10n.wrongPassword) return true;
  return error.contains('Sai mật khẩu') ||
      error.toLowerCase().contains('wrong password');
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
    final l10n = context.l10n;
    final isWrongPwd = _isWrongZipPasswordError(widget.error);

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.lock_outline, size: 56, color: VsCodeColors.accent),
            const SizedBox(height: 16),
            Text(
              p.basename(widget.zipPath),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              isWrongPwd ? l10n.wrongPasswordRetry : l10n.zipPasswordProtected,
              style: TextStyle(fontSize: 14, color: VsCodeColors.foregroundDim),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              obscureText: true,
              style: TextStyle(color: VsCodeColors.foreground),
              decoration: InputDecoration(
                hintText: l10n.passwordLabel,
                hintStyle: TextStyle(color: VsCodeColors.foregroundDim),
                filled: true,
                fillColor: VsCodeColors.sidebar,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderSide: BorderSide(color: VsCodeColors.border)),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: VsCodeColors.border)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: VsCodeColors.accent)),
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
                      foregroundColor: VsCodeColors.foreground,
                      side: BorderSide(color: VsCodeColors.border),
                    ),
                    child: Text(l10n.cancel),
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
                    child: Text(l10n.unlock),
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
