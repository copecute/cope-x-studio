class RecentFileEntry {
  const RecentFileEntry({
    required this.path,
    required this.modifiedAt,
    required this.size,
  });

  final String path;
  final DateTime modifiedAt;
  final int size;
}
