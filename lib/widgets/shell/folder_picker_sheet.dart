import 'dart:io';

import 'package:cope_x_studio/providers/workspace_provider.dart';
import 'package:cope_x_studio/theme/app_sizes.dart';
import 'package:cope_x_studio/theme/vscode_theme.dart';
import 'package:cope_x_studio/utils/path_utils.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

/// Duyệt thư mục bằng giao diện app để chọn thư mục chia sẻ Web Server.
class FolderPickerSheet extends StatefulWidget {
  const FolderPickerSheet({super.key, this.initialPath});

  final String? initialPath;

  static Future<String?> pick(BuildContext context, {String? initialPath}) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: VsCodeColors.sidebar,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (_) => FolderPickerSheet(initialPath: initialPath),
    );
  }

  @override
  State<FolderPickerSheet> createState() => _FolderPickerSheetState();
}

class _FolderPickerSheetState extends State<FolderPickerSheet> {
  late String _currentPath;
  String? _error;

  @override
  void initState() {
    super.initState();
    final workspace = context.read<WorkspaceProvider>();
    _currentPath = widget.initialPath ?? workspace.defaultBrowsePath;
    if (!Directory(_currentPath).existsSync()) {
      _currentPath = workspace.defaultBrowsePath;
    }
  }

  bool get _canGoUp {
    final parent = PathUtils.parentPath(_currentPath);
    return parent != null && parent != _currentPath;
  }

  void _goUp() {
    final parent = PathUtils.parentPath(_currentPath);
    if (parent == null || parent == _currentPath) return;
    setState(() {
      _currentPath = parent;
      _error = null;
    });
  }

  void _enterFolder(String path) {
    setState(() {
      _currentPath = path;
      _error = null;
    });
  }

  List<Directory> _listFolders(WorkspaceProvider workspace) {
    try {
      return workspace
          .listDirectory(_currentPath)
          .whereType<Directory>()
          .toList()
        ..sort((a, b) => p.basename(a.path).toLowerCase().compareTo(p.basename(b.path).toLowerCase()));
    } catch (e) {
      _error = '$e';
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final workspace = context.watch<WorkspaceProvider>();
    final folders = _listFolders(workspace);
    final height = MediaQuery.sizeOf(context).height * 0.82;

    return SizedBox(
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Chọn thư mục chia sẻ',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Container(
            height: 48,
            color: VsCodeColors.tabBar,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_upward, size: AppSizes.iconMedium),
                  onPressed: _canGoUp ? _goUp : null,
                ),
                Expanded(
                  child: Text(
                    _currentPath,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: VsCodeColors.foregroundDim),
                  ),
                ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ),
          Expanded(
            child: folders.isEmpty
                ? Center(
                    child: Text(
                      _error != null ? 'Không thể đọc thư mục' : 'Không có thư mục con',
                      style: const TextStyle(color: VsCodeColors.foregroundDim),
                    ),
                  )
                : ListView.builder(
                    itemCount: folders.length,
                    itemBuilder: (context, index) {
                      final dir = folders[index];
                      final name = p.basename(dir.path);
                      return ListTile(
                        leading: const Icon(Icons.folder, color: VsCodeColors.accent),
                        title: Text(name),
                        onTap: () => _enterFolder(dir.path),
                      );
                    },
                  ),
          ),
          const Divider(height: 1, color: VsCodeColors.border),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: FilledButton.icon(
              onPressed: () => Navigator.pop(context, _currentPath),
              icon: const Icon(Icons.check),
              label: const Text('Chọn thư mục này'),
            ),
          ),
        ],
      ),
    );
  }
}
