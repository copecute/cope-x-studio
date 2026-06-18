import 'package:cope_x_studio/models/editor_tab.dart';
import 'package:cope_x_studio/providers/workspace_provider.dart';
import 'package:cope_x_studio/theme/vscode_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ExcelEditorView extends StatefulWidget {
  const ExcelEditorView({super.key, required this.tab});

  final EditorTab tab;

  @override
  State<ExcelEditorView> createState() => _ExcelEditorViewState();
}

class _ExcelEditorViewState extends State<ExcelEditorView> {
  late List<List<TextEditingController>> _controllers;

  @override
  void initState() {
    super.initState();
    _bindControllers();
  }

  @override
  void didUpdateWidget(ExcelEditorView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tab.id != widget.tab.id) {
      _disposeControllers();
      _bindControllers();
    }
  }

  void _bindControllers() {
    _controllers = widget.tab.excelData
        .map(
          (row) => row
              .map((cell) {
                final c = TextEditingController(text: cell);
                c.addListener(_onChanged);
                return c;
              })
              .toList(),
        )
        .toList();
  }

  void _onChanged() {
    final appTabId = context.read<WorkspaceProvider>().activeTabId;
    if (appTabId == null) return;
    final data = _controllers.map((row) => row.map((c) => c.text).toList()).toList();
    context.read<WorkspaceProvider>().updateExcelData(appTabId, data);
  }

  void _disposeControllers() {
    for (final row in _controllers) {
      for (final controller in row) {
        controller.removeListener(_onChanged);
        controller.dispose();
      }
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _addRow() {
    setState(() {
      final colCount = _controllers.isNotEmpty ? _controllers.first.length : 1;
      _controllers.add(
        List.generate(colCount, (_) {
          final c = TextEditingController();
          c.addListener(_onChanged);
          return c;
        }),
      );
    });
    _onChanged();
  }

  void _addColumn() {
    setState(() {
      if (_controllers.isEmpty) {
        final c = TextEditingController();
        c.addListener(_onChanged);
        _controllers.add([c]);
      } else {
        for (final row in _controllers) {
          final c = TextEditingController();
          c.addListener(_onChanged);
          row.add(c);
        }
      }
    });
    _onChanged();
  }

  String _columnLabel(int index) {
    var label = '';
    var n = index;
    do {
      label = String.fromCharCode(65 + (n % 26)) + label;
      n = n ~/ 26 - 1;
    } while (n >= 0);
    return label;
  }

  @override
  Widget build(BuildContext context) {
    final colCount = _controllers.isNotEmpty ? _controllers.first.length : 0;

    return Container(
      color: VsCodeColors.editor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: VsCodeColors.tabBar,
            child: Row(
              children: [
                const Icon(Icons.table_chart_outlined, size: 16),
                const SizedBox(width: 8),
                Text('Sheet: ${widget.tab.excelSheetName ?? 'Sheet1'}'),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addRow,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Hàng'),
                ),
                TextButton.icon(
                  onPressed: _addColumn,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Cột'),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  headingRowHeight: 32,
                  dataRowMinHeight: 36,
                  dataRowMaxHeight: 48,
                  headingRowColor: const WidgetStatePropertyAll(
                    Color(0xFF333333),
                  ),
                  columns: [
                    const DataColumn(label: Text('#')),
                    for (var c = 0; c < colCount; c++)
                      DataColumn(label: Text(_columnLabel(c))),
                  ],
                  rows: [
                    for (var r = 0; r < _controllers.length; r++)
                      DataRow(
                        cells: [
                          DataCell(Text('${r + 1}',
                              style: const TextStyle(
                                color: VsCodeColors.foregroundDim,
                              ))),
                          for (var c = 0; c < colCount; c++)
                            DataCell(
                              SizedBox(
                                width: 120,
                                child: TextField(
                                  controller: _controllers[r][c],
                                  style: const TextStyle(fontSize: 13),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
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
