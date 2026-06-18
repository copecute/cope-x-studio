import 'package:cope_x_studio/models/app_tab.dart';
import 'package:cope_x_studio/models/editor_tab.dart';
import 'package:cope_x_studio/providers/workspace_provider.dart';
import 'package:cope_x_studio/theme/app_sizes.dart';
import 'package:cope_x_studio/theme/vscode_theme.dart';
import 'package:cope_x_studio/widgets/browser/browser_tab_view.dart';
import 'package:cope_x_studio/widgets/editor/code_editor_view.dart';
import 'package:cope_x_studio/widgets/editor/pdf_viewer_view.dart';
import 'package:cope_x_studio/widgets/editor/media_viewer_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TabContentView extends StatelessWidget {
  const TabContentView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkspaceProvider>();
    final tab = provider.activeTab;

    if (tab == null) {
      return const _NoTabPlaceholder();
    }

    if (tab.isEditing && tab.editor != null) {
      return _EditorInTab(tab: tab, editor: tab.editor!);
    }

    return BrowserTabView(tab: tab);
  }
}

class _EditorInTab extends StatelessWidget {
  const _EditorInTab({required this.tab, required this.editor});

  final AppTab tab;
  final EditorTab editor;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<WorkspaceProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 48,
          color: VsCodeColors.tabBar,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, size: AppSizes.iconMedium),
                tooltip: 'Quay lại duyệt file',
                onPressed: () => provider.closeEditorInTab(tab.id),
              ),
              Expanded(
                child: Text(
                  editor.title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: AppSizes.fontBody, fontWeight: FontWeight.w500),
                ),
              ),
              if (editor.type == EditorTabType.text)
                TextButton.icon(
                  onPressed: () => provider.saveTab(tab.id),
                  icon: const Icon(Icons.save_outlined, size: 20),
                  label: const Text('Lưu'),
                ),
            ],
          ),
        ),
        Expanded(child: _buildEditor(editor)),
      ],
    );
  }

  Widget _buildEditor(EditorTab editor) {
    return switch (editor.type) {
      EditorTabType.text => CodeEditorView(tab: editor),
      EditorTabType.pdf => PdfReaderView(tab: editor),
      EditorTabType.media => MediaViewerView(tab: editor),
      EditorTabType.empty => const SizedBox.shrink(),
    };
  }
}

class _NoTabPlaceholder extends StatelessWidget {
  const _NoTabPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton.icon(
        onPressed: context.read<WorkspaceProvider>().newTab,
        icon: const Icon(Icons.add),
        label: const Text('Tạo tab duyệt file'),
      ),
    );
  }
}
