import 'package:cope_x_studio/models/editor_tab.dart';
import 'package:equatable/equatable.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

enum TabMode { browser, editor, zipViewer }

/// Mỗi tab = 1 pane duyệt file độc lập (kiểu X-plore).
class AppTab extends Equatable {
  AppTab({
    String? id,
    required this.currentPath,
    this.selectedPaths = const {},
    this.searchQuery = '',
    this.mode = TabMode.browser,
    this.editor,
    this.zipArchivePath,
    this.zipInnerPath = '',
    this.listRevision = 0,
    this.showSearch = false,
  }) : id = id ?? const Uuid().v4();

  final String id;
  final String currentPath;
  final Set<String> selectedPaths;
  final String searchQuery;
  final TabMode mode;
  final EditorTab? editor;
  final String? zipArchivePath;
  final String zipInnerPath;
  final int listRevision;
  final bool showSearch;

  bool get isBrowsing => mode == TabMode.browser;
  bool get isEditing => mode == TabMode.editor && editor != null;
  bool get isZipViewer => mode == TabMode.zipViewer && zipArchivePath != null;
  bool get hasSelection => selectedPaths.isNotEmpty;

  String get displayName {
    if (isEditing && editor != null) return editor!.displayName;
    if (isZipViewer) {
      final zipName = p.basename(zipArchivePath!);
      if (zipInnerPath.isEmpty) return zipName;
      return '${p.basename(zipInnerPath)} [$zipName]';
    }
    final name = p.basename(currentPath);
    return name.isEmpty ? currentPath : name;
  }

  AppTab copyWith({
    String? currentPath,
    Set<String>? selectedPaths,
    String? searchQuery,
    TabMode? mode,
    EditorTab? editor,
    String? zipArchivePath,
    String? zipInnerPath,
    int? listRevision,
    bool? showSearch,
    bool clearEditor = false,
    bool clearSelection = false,
    bool clearZip = false,
  }) {
    return AppTab(
      id: id,
      currentPath: currentPath ?? this.currentPath,
      selectedPaths: clearSelection ? {} : (selectedPaths ?? this.selectedPaths),
      searchQuery: searchQuery ?? this.searchQuery,
      mode: mode ?? this.mode,
      editor: clearEditor ? null : (editor ?? this.editor),
      zipArchivePath: clearZip ? null : (zipArchivePath ?? this.zipArchivePath),
      zipInnerPath: clearZip ? '' : (zipInnerPath ?? this.zipInnerPath),
      listRevision: listRevision ?? this.listRevision,
      showSearch: showSearch ?? this.showSearch,
    );
  }

  AppTab bumpList() => copyWith(listRevision: listRevision + 1);

  @override
  List<Object?> get props => [
        id,
        currentPath,
        selectedPaths,
        searchQuery,
        mode,
        editor?.isModified,
        zipArchivePath,
        zipInnerPath,
        listRevision,
        showSearch,
      ];
}
