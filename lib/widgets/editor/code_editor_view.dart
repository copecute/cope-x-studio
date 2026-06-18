import 'package:cope_x_studio/models/editor_tab.dart';
import 'package:cope_x_studio/providers/workspace_provider.dart';
import 'package:cope_x_studio/services/language_detector.dart';
import 'package:cope_x_studio/theme/vscode_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/vs2015.dart';
import 'package:provider/provider.dart';

class CodeEditorView extends StatefulWidget {
  const CodeEditorView({super.key, required this.tab});

  final EditorTab tab;

  @override
  State<CodeEditorView> createState() => _CodeEditorViewState();
}

class _CodeEditorViewState extends State<CodeEditorView> {
  late CodeController _controller;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  @override
  void didUpdateWidget(CodeEditorView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tab.id != widget.tab.id) {
      _controller.dispose();
      _initController();
    }
  }

  void _initController() {
    final language = widget.tab.language;
    final mode = LanguageDetector.modeFor(language);
    _controller = CodeController(
      text: widget.tab.content,
      language: mode,
    );
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final appTabId = context.read<WorkspaceProvider>().activeTabId;
    if (appTabId == null) return;
    context.read<WorkspaceProvider>().updateTabContent(appTabId, _controller.text);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: VsCodeColors.editor,
      child: CodeTheme(
        data: CodeThemeData(styles: vs2015Theme),
        child: SingleChildScrollView(
          child: CodeField(
            controller: _controller,
            textStyle: const TextStyle(
              fontFamily: 'Consolas',
              fontSize: 14,
              height: 1.4,
            ),
            gutterStyle: const GutterStyle(
              width: 48,
              textStyle: TextStyle(
                color: VsCodeColors.foregroundDim,
                fontSize: 12,
                fontFamily: 'Consolas',
              ),
            ),
            wrap: false,
          ),
        ),
      ),
    );
  }
}
