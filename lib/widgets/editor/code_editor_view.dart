import 'dart:async';
import 'package:cope_x_studio/models/editor_tab.dart';
import 'package:cope_x_studio/providers/workspace_provider.dart';
import 'package:cope_x_studio/services/language_detector.dart';
import 'package:cope_x_studio/theme/vscode_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final FocusNode _editorFocusNode = FocusNode();

  // Undo / Redo history
  final List<TextEditingValue> _undoStack = [];
  final List<TextEditingValue> _redoStack = [];
  TextEditingValue? _lastRecordedValue;
  Timer? _historyTimer;
  bool _isUndoingOrRedoing = false;

  // Search & Replace
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _replaceController = TextEditingController();
  List<RegExpMatch> _matches = [];
  int _currentMatchIndex = -1;

  @override
  void initState() {
    super.initState();
    _initController();
    _searchController.addListener(_updateMatches);
  }

  @override
  void didUpdateWidget(CodeEditorView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tab.id != widget.tab.id) {
      _historyTimer?.cancel();
      _undoStack.clear();
      _redoStack.clear();
      _lastRecordedValue = null;
      _controller.removeListener(_onTextChanged);
      _controller.dispose();
      _initController();
      _updateMatches();
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
    _lastRecordedValue = _controller.value;
  }

  void _onTextChanged() {
    final appTabId = context.read<WorkspaceProvider>().activeTabId;
    if (appTabId == null) return;
    context.read<WorkspaceProvider>().updateTabContent(appTabId, _controller.text);

    if (!_isUndoingOrRedoing) {
      if (_controller.value.text != _lastRecordedValue?.text) {
        _historyTimer?.cancel();
        _historyTimer = Timer(const Duration(milliseconds: 600), () {
          if (_controller.value.text != _lastRecordedValue?.text) {
            if (_lastRecordedValue != null) {
              _undoStack.add(_lastRecordedValue!);
              if (_undoStack.length > 100) _undoStack.removeAt(0);
              _redoStack.clear();
            }
            _lastRecordedValue = _controller.value;
            if (mounted) setState(() {});
          }
        });
      }
    }

    if (_showSearch) {
      _updateMatches();
    }
    setState(() {});
  }

  void _pushUndoState() {
    _historyTimer?.cancel();
    _undoStack.add(_controller.value);
    if (_undoStack.length > 100) _undoStack.removeAt(0);
    _redoStack.clear();
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    setState(() {
      _isUndoingOrRedoing = true;
      _redoStack.add(_controller.value);
      final prev = _undoStack.removeLast();
      _controller.value = prev;
      _lastRecordedValue = prev;
      _isUndoingOrRedoing = false;
    });
    _editorFocusNode.requestFocus();
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    setState(() {
      _isUndoingOrRedoing = true;
      _undoStack.add(_controller.value);
      final next = _redoStack.removeLast();
      _controller.value = next;
      _lastRecordedValue = next;
      _isUndoingOrRedoing = false;
    });
    _editorFocusNode.requestFocus();
  }

  Future<void> _copy() async {
    final selection = _controller.selection;
    if (selection.isValid && !selection.isCollapsed) {
      final selectedText = selection.textInside(_controller.text);
      await Clipboard.setData(ClipboardData(text: selectedText));
    }
  }

  Future<void> _cut() async {
    final selection = _controller.selection;
    if (selection.isValid && !selection.isCollapsed) {
      final selectedText = selection.textInside(_controller.text);
      await Clipboard.setData(ClipboardData(text: selectedText));
      
      _pushUndoState();
      
      final newText = _controller.text.replaceRange(selection.start, selection.end, '');
      _isUndoingOrRedoing = true;
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start),
      );
      _lastRecordedValue = _controller.value;
      _isUndoingOrRedoing = false;
      setState(() {});
    }
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null) {
      final selection = _controller.selection;
      final insertText = data.text!;
      
      _pushUndoState();
      
      final int start = selection.isValid ? selection.start : _controller.text.length;
      final int end = selection.isValid ? selection.end : _controller.text.length;
      final newText = _controller.text.replaceRange(start, end, insertText);
      
      _isUndoingOrRedoing = true;
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start + insertText.length),
      );
      _lastRecordedValue = _controller.value;
      _isUndoingOrRedoing = false;
      setState(() {});
    }
  }

  void _updateMatches() {
    final query = _searchController.text;
    final text = _controller.text;
    if (query.isEmpty) {
      setState(() {
        _matches = [];
        _currentMatchIndex = -1;
      });
      return;
    }

    try {
      final queryEscaped = RegExp.escape(query);
      final regex = RegExp(queryEscaped, caseSensitive: false);
      final allMatches = regex.allMatches(text).toList();
      setState(() {
        _matches = allMatches;
        if (allMatches.isEmpty) {
          _currentMatchIndex = -1;
        } else if (_currentMatchIndex >= allMatches.length) {
          _currentMatchIndex = 0;
        } else if (_currentMatchIndex < 0) {
          _currentMatchIndex = 0;
        }
      });
    } catch (_) {
      setState(() {
        _matches = [];
        _currentMatchIndex = -1;
      });
    }
  }

  void _findNext() {
    if (_matches.isEmpty) return;
    setState(() {
      _currentMatchIndex = (_currentMatchIndex + 1) % _matches.length;
      final match = _matches[_currentMatchIndex];
      _controller.selection = TextSelection(
        baseOffset: match.start,
        extentOffset: match.end,
      );
    });
    _editorFocusNode.requestFocus();
  }

  void _findPrev() {
    if (_matches.isEmpty) return;
    setState(() {
      _currentMatchIndex = (_currentMatchIndex - 1 + _matches.length) % _matches.length;
      final match = _matches[_currentMatchIndex];
      _controller.selection = TextSelection(
        baseOffset: match.start,
        extentOffset: match.end,
      );
    });
    _editorFocusNode.requestFocus();
  }

  void _replace() {
    if (_matches.isEmpty || _currentMatchIndex < 0 || _currentMatchIndex >= _matches.length) return;
    
    _pushUndoState();
    
    final match = _matches[_currentMatchIndex];
    final replaceText = _replaceController.text;
    final newText = _controller.text.replaceRange(match.start, match.end, replaceText);
    
    _isUndoingOrRedoing = true;
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: match.start + replaceText.length),
    );
    _lastRecordedValue = _controller.value;
    _isUndoingOrRedoing = false;
    
    _updateMatches();
    _editorFocusNode.requestFocus();
  }

  void _replaceAll() {
    final query = _searchController.text;
    if (query.isEmpty) return;

    _pushUndoState();

    final replaceText = _replaceController.text;
    final queryEscaped = RegExp.escape(query);
    final regex = RegExp(queryEscaped, caseSensitive: false);
    final newText = _controller.text.replaceAll(regex, replaceText);

    _isUndoingOrRedoing = true;
    _controller.value = TextEditingValue(
      text: newText,
      selection: const TextSelection.collapsed(offset: 0),
    );
    _lastRecordedValue = _controller.value;
    _isUndoingOrRedoing = false;

    _updateMatches();
    _editorFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _editorFocusNode.dispose();
    _searchController.dispose();
    _replaceController.dispose();
    _historyTimer?.cancel();
    super.dispose();
  }

  Widget _buildToolbar() {
    final hasSelection = _controller.selection.isValid && !_controller.selection.isCollapsed;
    return Container(
      height: 38,
      decoration: const BoxDecoration(
        color: VsCodeColors.tabBar,
        border: Border(
          bottom: BorderSide(color: VsCodeColors.border, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.undo, size: 18),
            tooltip: 'Hoàn tác',
            onPressed: _undoStack.isNotEmpty ? _undo : null,
            color: _undoStack.isNotEmpty ? Colors.white : VsCodeColors.foregroundDim,
          ),
          IconButton(
            icon: const Icon(Icons.redo, size: 18),
            tooltip: 'Làm lại',
            onPressed: _redoStack.isNotEmpty ? _redo : null,
            color: _redoStack.isNotEmpty ? Colors.white : VsCodeColors.foregroundDim,
          ),
          const VerticalDivider(width: 16, indent: 8, endIndent: 8, color: VsCodeColors.border),
          IconButton(
            icon: const Icon(Icons.content_cut, size: 18),
            tooltip: 'Cắt',
            onPressed: hasSelection ? _cut : null,
            color: hasSelection ? Colors.white : VsCodeColors.foregroundDim,
          ),
          IconButton(
            icon: const Icon(Icons.content_copy, size: 18),
            tooltip: 'Sao chép',
            onPressed: hasSelection ? _copy : null,
            color: hasSelection ? Colors.white : VsCodeColors.foregroundDim,
          ),
          IconButton(
            icon: const Icon(Icons.content_paste, size: 18),
            tooltip: 'Dán',
            onPressed: _paste,
            color: Colors.white,
          ),
          const VerticalDivider(width: 16, indent: 8, endIndent: 8, color: VsCodeColors.border),
          IconButton(
            icon: const Icon(Icons.search, size: 18),
            tooltip: 'Tìm kiếm & Thay thế',
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (_showSearch) {
                  _updateMatches();
                }
              });
            },
            color: _showSearch ? VsCodeColors.accent : Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchPanel() {
    final matchText = _matches.isEmpty
        ? 'Không tìm thấy'
        : '${_currentMatchIndex + 1} / ${_matches.length}';

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF252526),
        border: Border(
          bottom: BorderSide(color: VsCodeColors.border, width: 1),
        ),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(fontSize: 13, color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm...',
                      hintStyle: const TextStyle(color: VsCodeColors.foregroundDim, fontSize: 13),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      fillColor: const Color(0xFF3C3C3C),
                      filled: true,
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: VsCodeColors.border),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: VsCodeColors.accent),
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                matchText,
                style: const TextStyle(color: VsCodeColors.foregroundDim, fontSize: 12),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.arrow_upward, size: 18),
                tooltip: 'Trước đó',
                onPressed: _matches.isNotEmpty ? _findPrev : null,
                color: _matches.isNotEmpty ? Colors.white : VsCodeColors.foregroundDim,
              ),
              IconButton(
                icon: const Icon(Icons.arrow_downward, size: 18),
                tooltip: 'Tiếp theo',
                onPressed: _matches.isNotEmpty ? _findNext : null,
                color: _matches.isNotEmpty ? Colors.white : VsCodeColors.foregroundDim,
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                tooltip: 'Đóng',
                onPressed: () {
                  setState(() {
                    _showSearch = false;
                  });
                },
                color: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: TextField(
                    controller: _replaceController,
                    style: const TextStyle(fontSize: 13, color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Thay thế...',
                      hintStyle: const TextStyle(color: VsCodeColors.foregroundDim, fontSize: 13),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      fillColor: const Color(0xFF3C3C3C),
                      filled: true,
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: VsCodeColors.border),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: VsCodeColors.accent),
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _matches.isNotEmpty ? _replace : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: VsCodeColors.border,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  minimumSize: const Size(0, 32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: const Text('Thay thế', style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 4),
              ElevatedButton(
                onPressed: _searchController.text.isNotEmpty ? _replaceAll : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: VsCodeColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  minimumSize: const Size(0, 32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: const Text('Tất cả', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lineCount = _controller.text.split('\n').length;
    final maxDigits = lineCount.toString().length;
    final double gutterWidth = (44 + maxDigits * 8).toDouble().clamp(64.0, 200.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildToolbar(),
        if (_showSearch) _buildSearchPanel(),
        Expanded(
          child: Container(
            color: VsCodeColors.editor,
            child: CodeTheme(
              data: CodeThemeData(styles: vs2015Theme),
              child: SingleChildScrollView(
                child: CodeField(
                  controller: _controller,
                  focusNode: _editorFocusNode,
                  textStyle: const TextStyle(
                    fontFamily: 'Consolas',
                    fontSize: 14,
                    height: 1.4,
                  ),
                  gutterStyle: GutterStyle(
                    width: gutterWidth,
                    margin: 8,
                    textStyle: const TextStyle(
                      color: VsCodeColors.foregroundDim,
                      fontSize: 12,
                      fontFamily: 'Consolas',
                    ),
                  ),
                  wrap: false,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
