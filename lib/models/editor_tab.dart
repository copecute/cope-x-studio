import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

enum EditorTabType { text, docx, excel, pptx, empty }

class EditorTab extends Equatable {
  EditorTab({
    String? id,
    required this.type,
    this.filePath,
    this.title = 'Untitled',
    this.content = '',
    this.isModified = false,
    this.language = 'plaintext',
    this.docxParagraphs = const [],
    this.excelSheetName,
    this.excelData = const [],
    this.pptxSlides = const [],
    this.originalBytes,
  }) : id = id ?? const Uuid().v4();

  final String id;
  final EditorTabType type;
  final String? filePath;
  final String title;
  final String content;
  final bool isModified;
  final String language;
  final List<String> docxParagraphs;
  final String? excelSheetName;
  final List<List<String>> excelData;
  final List<PptxSlideData> pptxSlides;
  final List<int>? originalBytes;

  String get displayName {
    final name = title.isNotEmpty ? title : 'Untitled';
    return isModified ? '$name •' : name;
  }

  EditorTab copyWith({
    EditorTabType? type,
    String? filePath,
    String? title,
    String? content,
    bool? isModified,
    String? language,
    List<String>? docxParagraphs,
    String? excelSheetName,
    List<List<String>>? excelData,
    List<PptxSlideData>? pptxSlides,
    List<int>? originalBytes,
  }) {
    return EditorTab(
      id: id,
      type: type ?? this.type,
      filePath: filePath ?? this.filePath,
      title: title ?? this.title,
      content: content ?? this.content,
      isModified: isModified ?? this.isModified,
      language: language ?? this.language,
      docxParagraphs: docxParagraphs ?? this.docxParagraphs,
      excelSheetName: excelSheetName ?? this.excelSheetName,
      excelData: excelData ?? this.excelData,
      pptxSlides: pptxSlides ?? this.pptxSlides,
      originalBytes: originalBytes ?? this.originalBytes,
    );
  }

  @override
  List<Object?> get props => [id, filePath, isModified, title];
}

class PptxSlideData {
  const PptxSlideData({
    required this.index,
    required this.texts,
    this.imageBytes,
  });

  final int index;
  final List<String> texts;
  final List<int>? imageBytes;
}
