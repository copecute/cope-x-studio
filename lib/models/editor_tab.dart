import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

enum EditorTabType { text, empty, pdf, media }

enum MediaOpenMode { image, video, audio }

class EditorTab extends Equatable {
  EditorTab({
    String? id,
    required this.type,
    this.filePath,
    this.title = 'Untitled',
    this.content = '',
    this.isModified = false,
    this.language = 'plaintext',
    this.localPath,
    this.forcedMediaMode,
  }) : id = id ?? const Uuid().v4();

  final String id;
  final EditorTabType type;
  final String? filePath;
  final String title;
  final String content;
  final bool isModified;
  final String language;
  final String? localPath;
  final MediaOpenMode? forcedMediaMode;

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
    String? localPath,
    MediaOpenMode? forcedMediaMode,
  }) {
    return EditorTab(
      id: id,
      type: type ?? this.type,
      filePath: filePath ?? this.filePath,
      title: title ?? this.title,
      content: content ?? this.content,
      isModified: isModified ?? this.isModified,
      language: language ?? this.language,
      localPath: localPath ?? this.localPath,
      forcedMediaMode: forcedMediaMode ?? this.forcedMediaMode,
    );
  }

  @override
  List<Object?> get props => [id, filePath, isModified, title, localPath, forcedMediaMode];
}
