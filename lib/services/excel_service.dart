import 'dart:io';

import 'package:excel/excel.dart';

class ExcelSheetData {
  const ExcelSheetData({
    required this.name,
    required this.rows,
  });

  final String name;
  final List<List<String>> rows;
}

class ExcelService {
  Future<ExcelSheetData> loadFirstSheet(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    return loadFirstSheetFromBytes(bytes);
  }

  ExcelSheetData loadFirstSheetFromBytes(List<int> bytes) {
    final excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) {
      return const ExcelSheetData(name: 'Sheet1', rows: [['']]);
    }

    final sheetName = excel.tables.keys.first;
    final sheet = excel.tables[sheetName]!;
    final rows = <List<String>>[];

    for (var r = 0; r < sheet.maxRows; r++) {
      final row = <String>[];
      for (var c = 0; c < sheet.maxColumns; c++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r),
        );
        row.add(_cellToString(cell));
      }
      rows.add(row);
    }

    if (rows.isEmpty) {
      rows.add(['']);
    }

    return ExcelSheetData(name: sheetName, rows: rows);
  }

  Future<void> saveSheet(
    String filePath,
    String sheetName,
    List<List<String>> rows, {
    List<int>? originalBytes,
  }) async {
    final Excel excel;
    if (originalBytes != null) {
      excel = Excel.decodeBytes(originalBytes);
    } else {
      excel = Excel.createExcel();
      final defaultSheet = excel.tables.keys.first;
      excel.rename(defaultSheet, sheetName);
    }

    final effectiveSheet =
        excel.tables.containsKey(sheetName) ? sheetName : excel.tables.keys.first;
    final sheet = excel[effectiveSheet];
    for (var r = 0; r < rows.length; r++) {
      for (var c = 0; c < rows[r].length; c++) {
        final value = rows[r][c];
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r),
        );
        if (value.startsWith('=')) {
          cell.value = FormulaCellValue(value);
        } else {
          final number = num.tryParse(value);
          cell.value = number != null
              ? DoubleCellValue(number.toDouble())
              : TextCellValue(value);
        }
      }
    }

    final encoded = excel.encode();
    if (encoded == null) {
      throw Exception('Failed to encode Excel file');
    }
    await File(filePath).writeAsBytes(encoded);
  }

  String _cellToString(Data? cell) {
    if (cell == null || cell.value == null) return '';
    final value = cell.value!;
    return switch (value) {
      TextCellValue() => value.value.toString(),
      IntCellValue() => value.value.toString(),
      DoubleCellValue() => value.value.toString(),
      BoolCellValue() => value.value.toString(),
      FormulaCellValue() => value.formula,
      DateCellValue() => value.asDateTimeLocal().toString(),
      DateTimeCellValue() => value.asDateTimeLocal().toString(),
      TimeCellValue() => value.asDuration().toString(),
    };
  }
}
