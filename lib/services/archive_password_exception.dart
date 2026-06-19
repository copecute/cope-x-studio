class ArchivePasswordException implements Exception {
  const ArchivePasswordException(this.message);
  final String message;
  @override
  String toString() => message;
}
