import 'dart:async';
import 'package:cope_x_studio/models/editor_tab.dart';
import 'package:cope_x_studio/providers/workspace_provider.dart';
import 'package:cope_x_studio/services/language_detector.dart';
import 'package:cope_x_studio/theme/vscode_theme.dart';
import 'package:cope_x_studio/utils/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/vs.dart';
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
  final ScrollController _editorScrollController = ScrollController();

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
  void dispose() {
    _historyTimer?.cancel();
    _editorScrollController.dispose();
    _editorFocusNode.dispose();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _searchController.dispose();
    _replaceController.dispose();
    super.dispose();
  }

  static const _codeFieldLeftPad = 8.0;
  static const _gutterMargin = 4.0;

  double _lineHeightFor(double fontSize) => fontSize * 1.4;

  double _charWidthFor(double fontSize) => fontSize * 0.6;

  double _gutterStyleWidth(double fontSize, int lineCount) {
    final maxDigits = lineCount.toString().length;
    final digitWidth = fontSize * 0.65;
    const foldingColumn = 16.0;
    const innerPad = 6.0;
    final numbersWidth = maxDigits * digitWidth + innerPad + _gutterMargin;
    return numbersWidth + foldingColumn;
  }

  double _textAreaLeftFor(double gutterWidth, bool showLineNumbers) {
    if (!showLineNumbers) return _codeFieldLeftPad;
    return _codeFieldLeftPad + gutterWidth;
  }

  int _offsetForLine(int lineIndex, List<String> lines) {
    var offset = 0;
    for (var i = 0; i < lineIndex && i < lines.length; i++) {
      offset += lines[i].length + 1;
    }
    return offset;
  }

  void _setCursorOffset(int offset) {
    final clamped = offset.clamp(0, _controller.text.length);
    _controller.selection = TextSelection.collapsed(offset: clamped);
  }

  void _handleEditorPointerDown(
    PointerDownEvent event,
    double fontSize,
    double gutterWidth,
    bool showLineNumbers,
  ) {
    _editorFocusNode.requestFocus();

    final lineHeight = _lineHeightFor(fontSize);
    final textAreaLeft = _textAreaLeftFor(gutterWidth, showLineNumbers);
    final charWidth = _charWidthFor(fontSize);
    final scrollOffset =
        _editorScrollController.hasClients ? _editorScrollController.offset : 0.0;
    final tapY = event.localPosition.dy + scrollOffset;
    final tapX = event.localPosition.dx;

    final text = _controller.text;
    final lines = text.isEmpty ? <String>[''] : text.split('\n');
    final contentHeight = lines.length * lineHeight;

    if (tapY >= contentHeight) {
      _setCursorOffset(text.length);
      return;
    }

    final lineIndex = (tapY / lineHeight).floor().clamp(0, lines.length - 1);
    final lineText = lines[lineIndex];

    if (tapX < textAreaLeft) {
      _setCursorOffset(_offsetForLine(lineIndex, lines));
      return;
    }

    final textWidth = lineText.length * charWidth;
    if (tapX > textAreaLeft + textWidth) {
      _setCursorOffset(_offsetForLine(lineIndex, lines) + lineText.length);
      return;
    }

    final col = ((tapX - textAreaLeft) / charWidth).round().clamp(0, lineText.length);
    _setCursorOffset(_offsetForLine(lineIndex, lines) + col);
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

  Widget _buildToolbar(WorkspaceProvider workspace) {
    final l10n = context.l10n;
    final hasSelection = _controller.selection.isValid && !_controller.selection.isCollapsed;
    final fontSize = workspace.editorFontSize;
    final showLineNumbers = workspace.editorShowLineNumbers;
    final wordWrap = workspace.editorWordWrap;
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: VsCodeColors.tabBar,
        border: Border(
          bottom: BorderSide(color: VsCodeColors.border, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
          IconButton(
            icon: const Icon(Icons.undo, size: 18),
            tooltip: l10n.undo,
            onPressed: _undoStack.isNotEmpty ? _undo : null,
            color: _undoStack.isNotEmpty ? VsCodeColors.foreground : VsCodeColors.foregroundDim,
          ),
          IconButton(
            icon: const Icon(Icons.redo, size: 18),
            tooltip: l10n.redo,
            onPressed: _redoStack.isNotEmpty ? _redo : null,
            color: _redoStack.isNotEmpty ? VsCodeColors.foreground : VsCodeColors.foregroundDim,
          ),
          VerticalDivider(width: 16, indent: 8, endIndent: 8, color: VsCodeColors.border),
          IconButton(
            icon: const Icon(Icons.content_cut, size: 18),
            tooltip: l10n.cut,
            onPressed: hasSelection ? _cut : null,
            color: hasSelection ? VsCodeColors.foreground : VsCodeColors.foregroundDim,
          ),
          IconButton(
            icon: const Icon(Icons.content_copy, size: 18),
            tooltip: l10n.copy,
            onPressed: hasSelection ? _copy : null,
            color: hasSelection ? VsCodeColors.foreground : VsCodeColors.foregroundDim,
          ),
          IconButton(
            icon: const Icon(Icons.content_paste, size: 18),
            tooltip: l10n.paste,
            onPressed: _paste,
            color: VsCodeColors.foreground,
          ),
          VerticalDivider(width: 16, indent: 8, endIndent: 8, color: VsCodeColors.border),
          IconButton(
            icon: const Icon(Icons.search, size: 18),
            tooltip: l10n.findReplace,
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (_showSearch) {
                  _updateMatches();
                }
              });
            },
            color: _showSearch ? VsCodeColors.accent : VsCodeColors.foreground,
          ),
          VerticalDivider(width: 12, indent: 8, endIndent: 8, color: VsCodeColors.border),
          IconButton(
            icon: Icon(
              Icons.format_list_numbered,
              size: 18,
              color: showLineNumbers ? VsCodeColors.accent : VsCodeColors.foregroundDim,
            ),
            tooltip: showLineNumbers ? l10n.hideLineNumbers : l10n.showLineNumbersToggle,
            onPressed: () => workspace.setEditorShowLineNumbers(!showLineNumbers),
          ),
          IconButton(
            icon: Icon(
              Icons.wrap_text,
              size: 18,
              color: wordWrap ? VsCodeColors.accent : VsCodeColors.foregroundDim,
            ),
            tooltip: wordWrap ? l10n.disableWordWrap : l10n.enableWordWrap,
            onPressed: () => workspace.setEditorWordWrap(!wordWrap),
          ),
          IconButton(
            icon: const Icon(Icons.text_decrease, size: 18),
            tooltip: l10n.decreaseFontSize,
            onPressed: fontSize > 10 ? () => workspace.adjustEditorFontSize(-1) : null,
            color: fontSize > 10 ? VsCodeColors.foreground : VsCodeColors.foregroundDim,
          ),
          SizedBox(
            width: 28,
            child: Text(
              '${fontSize.toInt()}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: VsCodeColors.foreground,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.text_increase, size: 18),
            tooltip: l10n.increaseFontSize,
            onPressed: fontSize < 28 ? () => workspace.adjustEditorFontSize(1) : null,
            color: fontSize < 28 ? VsCodeColors.foreground : VsCodeColors.foregroundDim,
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchPanel() {
    final l10n = context.l10n;
    final matchText = _matches.isEmpty
        ? l10n.notFound
        : '${_currentMatchIndex + 1} / ${_matches.length}';

    return Container(
      decoration: BoxDecoration(
        color: VsCodeColors.tabBar,
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
                    style: TextStyle(fontSize: 13, color: VsCodeColors.foreground),
                    decoration: InputDecoration(
                      hintText: l10n.findHint,
                      hintStyle: TextStyle(color: VsCodeColors.foregroundDim, fontSize: 13),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      fillColor: VsCodeColors.hover,
                      filled: true,
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: VsCodeColors.border),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      focusedBorder: OutlineInputBorder(
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
                style: TextStyle(color: VsCodeColors.foregroundDim, fontSize: 12),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.arrow_upward, size: 18),
                tooltip: l10n.previous,
                onPressed: _matches.isNotEmpty ? _findPrev : null,
                color: _matches.isNotEmpty ? VsCodeColors.foreground : VsCodeColors.foregroundDim,
              ),
              IconButton(
                icon: const Icon(Icons.arrow_downward, size: 18),
                tooltip: l10n.next,
                onPressed: _matches.isNotEmpty ? _findNext : null,
                color: _matches.isNotEmpty ? VsCodeColors.foreground : VsCodeColors.foregroundDim,
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                tooltip: l10n.close,
                onPressed: () {
                  setState(() {
                    _showSearch = false;
                  });
                },
                color: VsCodeColors.foreground,
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
                    style: TextStyle(fontSize: 13, color: VsCodeColors.foreground),
                    decoration: InputDecoration(
                      hintText: l10n.replaceHint,
                      hintStyle: TextStyle(color: VsCodeColors.foregroundDim, fontSize: 13),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      fillColor: VsCodeColors.hover,
                      filled: true,
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: VsCodeColors.border),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      focusedBorder: OutlineInputBorder(
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
                  foregroundColor: VsCodeColors.foreground,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  minimumSize: const Size(0, 32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: Text(l10n.replace, style: TextStyle(fontSize: 12)),
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
                child: Text(l10n.replaceAll, style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final workspace = context.watch<WorkspaceProvider>();
    final fontSize = workspace.editorFontSize;
    final showLineNumbers = workspace.editorShowLineNumbers;
    final wordWrap = workspace.editorWordWrap;
    final lineCount = _controller.text.split('\n').length;
    final gutterWidth = showLineNumbers ? _gutterStyleWidth(fontSize, lineCount) : 0.0;

    final syntaxStyles =
        Theme.of(context).brightness == Brightness.dark ? vs2015Theme : vsTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildToolbar(workspace),
        if (_showSearch) _buildSearchPanel(),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (event) => _handleEditorPointerDown(
                  event,
                  fontSize,
                  gutterWidth,
                  showLineNumbers,
                ),
                child: Stack(
                  children: [
                    if (showLineNumbers)
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: _codeFieldLeftPad + gutterWidth,
                        child: ColoredBox(color: VsCodeColors.editorGutter),
                      ),
                    ColoredBox(
                      color: VsCodeColors.editor,
                      child: CodeTheme(
                        data: CodeThemeData(styles: syntaxStyles),
                        child: SingleChildScrollView(
                          controller: _editorScrollController,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: CodeField(
                              controller: _controller,
                              focusNode: _editorFocusNode,
                              textStyle: TextStyle(
                                fontFamily: 'Consolas',
                                fontSize: fontSize,
                                height: 1.4,
                              ),
                              gutterStyle: showLineNumbers
                                  ? GutterStyle(
                                      width: gutterWidth,
                                      margin: _gutterMargin,
                                      background: VsCodeColors.editorGutter,
                                      showLineNumbers: true,
                                      showErrors: false,
                                      showFoldingHandles: true,
                                      textStyle: TextStyle(
                                        color: VsCodeColors.foregroundDim,
                                        fontSize: (fontSize - 1).clamp(9.0, 26.0),
                                        fontFamily: 'Consolas',
                                      ),
                                    )
                                  : GutterStyle.none,
                              wrap: wordWrap,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
