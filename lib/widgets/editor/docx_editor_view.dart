import 'package:cope_x_studio/models/editor_tab.dart';
import 'package:cope_x_studio/providers/workspace_provider.dart';
import 'package:cope_x_studio/theme/vscode_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DocxEditorView extends StatefulWidget {
  const DocxEditorView({super.key, required this.tab});

  final EditorTab tab;

  @override
  State<DocxEditorView> createState() => _DocxEditorViewState();
}

class _DocxEditorViewState extends State<DocxEditorView> {
  late List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _bindControllers();
  }

  @override
  void didUpdateWidget(DocxEditorView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tab.id != widget.tab.id) {
      _disposeControllers();
      _bindControllers();
    }
  }

  void _bindControllers() {
    _controllers = widget.tab.docxParagraphs
        .map((p) => TextEditingController(text: p))
        .toList();
    for (final controller in _controllers) {
      controller.addListener(_onChanged);
    }
  }

  void _onChanged() {
    final appTabId = context.read<WorkspaceProvider>().activeTabId;
    if (appTabId == null) return;
    final paragraphs = _controllers.map((c) => c.text).toList();
    context.read<WorkspaceProvider>().updateDocxParagraphs(appTabId, paragraphs);
  }

  void _disposeControllers() {
    for (final controller in _controllers) {
      controller.removeListener(_onChanged);
      controller.dispose();
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _addParagraph() {
    setState(() {
      final controller = TextEditingController();
      controller.addListener(_onChanged);
      _controllers.add(controller);
    });
    _onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF2B2B2B),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: VsCodeColors.tabBar,
            child: Row(
              children: [
                const Icon(Icons.description_outlined, size: 16),
                const SizedBox(width: 8),
                const Text('Word Editor (đơn giản)'),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addParagraph,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Đoạn mới'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: _controllers.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    controller: _controllers[index],
                    maxLines: null,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Đoạn văn ${index + 1}',
                      filled: true,
                      fillColor: const Color(0xFF1E1E1E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(color: VsCodeColors.border),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
