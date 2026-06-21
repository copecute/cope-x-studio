import 'package:cope_x_studio/l10n/generated/app_localizations.dart';
import 'package:cope_x_studio/models/app_tab.dart';
import 'package:cope_x_studio/models/browser_entry.dart';
import 'package:cope_x_studio/models/tree_browser_node.dart';
import 'package:cope_x_studio/providers/workspace_provider.dart';
import 'package:cope_x_studio/theme/app_sizes.dart';
import 'package:cope_x_studio/theme/vscode_theme.dart';
import 'package:cope_x_studio/utils/file_type_utils.dart';
import 'package:cope_x_studio/utils/l10n_extension.dart';
import 'package:cope_x_studio/widgets/browser/file_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

typedef TreeEntryTap = void Function(BuildContext context, BrowserEntry entry);
typedef TreeEntryMenu = void Function(BuildContext context, BrowserEntry entry, Offset position);

class TreeBrowserView extends StatelessWidget {
  const TreeBrowserView({
    super.key,
    required this.tab,
    required this.onEntryTap,
    required this.onEntryLongPress,
    required this.onBackgroundMenu,
  });

  final AppTab tab;
  final TreeEntryTap onEntryTap;
  final TreeEntryMenu onEntryLongPress;
  final void Function(BuildContext context, Offset? position) onBackgroundMenu;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = context.watch<WorkspaceProvider>();
    final nodes = provider.listTreeNodes(tab.id);

    if (nodes.isEmpty) {
      final loading = provider.isTreeLoading(tab.id);
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onLongPress: () => onBackgroundMenu(context, null),
        onSecondaryTapDown: (d) => onBackgroundMenu(context, d.globalPosition),
        child: Center(
          child: loading
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(height: 12),
                    Text(
                      l10n.treeLoading,
                      style: TextStyle(color: VsCodeColors.foregroundDim, fontSize: 15),
                    ),
                  ],
                )
              : Text(
                  l10n.emptyFolder,
                  style: TextStyle(color: VsCodeColors.foregroundDim, fontSize: 16),
                ),
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPress: () => onBackgroundMenu(context, null),
      onSecondaryTapDown: (d) => onBackgroundMenu(context, d.globalPosition),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: nodes.length,
        itemBuilder: (context, index) => _TreeRow(
          tab: tab,
          node: nodes[index],
          onEntryTap: onEntryTap,
          onEntryLongPress: onEntryLongPress,
        ),
      ),
    );
  }
}

class _TreeRow extends StatelessWidget {
  const _TreeRow({
    required this.tab,
    required this.node,
    required this.onEntryTap,
    required this.onEntryLongPress,
  });

  final AppTab tab;
  final TreeBrowserNode node;
  final TreeEntryTap onEntryTap;
  final TreeEntryMenu onEntryLongPress;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final entry = node.entry;
    final selected = context.select<WorkspaceProvider, bool>(
      (p) => p.isSelected(tab.id, entry.path),
    );
    final provider = context.read<WorkspaceProvider>();
    final isSelectable = provider.isSelectable(tab.id, entry);

    Color? bg;
    if (selected) {
      bg = VsCodeColors.selection;
    } else if (node.isCurrent) {
      bg = VsCodeColors.hover;
    }

    return Material(
      color: bg ?? Colors.transparent,
      child: InkWell(
        onTap: () => onEntryTap(context, entry),
        onLongPress: () {
          final box = context.findRenderObject() as RenderBox?;
          final pos = box?.localToGlobal(Offset.zero) ?? Offset.zero;
          onEntryLongPress(context, entry, pos);
        },
        onSecondaryTapDown: (d) => onEntryLongPress(context, entry, d.globalPosition),
        child: Container(
          constraints: const BoxConstraints(minHeight: AppSizes.tileHeight),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Row(
              children: [
                SizedBox(width: 8 + node.depth * AppSizes.indentPerLevel),
                if (node.depth > 0)
                  Container(
                    width: 1,
                    margin: const EdgeInsets.only(right: 6),
                    color: VsCodeColors.border.withValues(alpha: 0.7),
                  ),
                SizedBox(
                  width: AppSizes.iconMedium,
                  height: AppSizes.iconMedium,
                  child: entry.isDirectory
                      ? (node.isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(2),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              node.isExpanded ? Icons.expand_more : Icons.chevron_right,
                              size: AppSizes.iconMedium,
                              color: node.hasChildren
                                  ? VsCodeColors.foregroundDim
                                  : Colors.transparent,
                            ))
                      : null,
                ),
                if (tab.hasSelection && isSelectable)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Icon(
                      selected ? Icons.check_circle : Icons.circle_outlined,
                      size: AppSizes.iconMedium,
                      color: selected ? VsCodeColors.accent : VsCodeColors.foregroundDim,
                    ),
                  ),
                if (entry.isZipVirtual)
                  Icon(
                    entry.isDirectory ? Icons.folder : Icons.insert_drive_file,
                    size: AppSizes.thumbSize,
                    color: entry.isDirectory ? VsCodeColors.accent : VsCodeColors.foregroundDim,
                  )
                else if (FileTypeUtils.isApk(entry.path))
                  FileThumbnail(
                    path: entry.path,
                    isDirectory: entry.isDirectory,
                    size: AppSizes.thumbSize,
                  )
                else if (FileTypeUtils.isArchive(entry.path))
                  Icon(
                    Icons.folder_zip_outlined,
                    size: AppSizes.thumbSize,
                    color: const Color(0xFFE8B84A),
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
                      Text(
                        entry.name,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        style: TextStyle(
                          fontSize: AppSizes.fontBody,
                          height: 1.3,
                          fontWeight: node.isCurrent ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      if (_showsSubtitle(entry))
                        Text(
                          _entrySubtitle(l10n, entry),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: AppSizes.fontCaption,
                            color: _entrySubtitleColor(entry),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _showsSubtitle(BrowserEntry entry) {
    if (entry.isDirectory && entry.childrenCount != null) return true;
    if (!entry.isDirectory && entry.size != null) return true;
    return false;
  }

  String _entrySubtitle(AppLocalizations l10n, BrowserEntry entry) {
    if (entry.isDirectory && entry.childrenCount != null) {
      return l10n.itemCount(entry.childrenCount!);
    }
    if (entry.size != null) return _formatSize(entry.size!);
    return '';
  }

  Color _entrySubtitleColor(BrowserEntry entry) {
    if (entry.accessDenied) return Colors.redAccent;
    return VsCodeColors.foregroundDim;
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
