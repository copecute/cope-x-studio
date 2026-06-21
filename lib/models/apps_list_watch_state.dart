import 'package:equatable/equatable.dart';

/// Narrow rebuild token for apps list views (excludes icon cache updates).
class AppsListWatchState extends Equatable {
  const AppsListWatchState({
    required this.listRevision,
    required this.loading,
    required this.error,
    required this.count,
    required this.searchQuery,
    required this.selectionCount,
    required this.showSearch,
    required this.hasSelection,
  });

  final int listRevision;
  final bool loading;
  final String? error;
  final int count;
  final String searchQuery;
  final int selectionCount;
  final bool showSearch;
  final bool hasSelection;

  @override
  List<Object?> get props => [
        listRevision,
        loading,
        error,
        count,
        searchQuery,
        selectionCount,
        showSearch,
        hasSelection,
      ];
}
