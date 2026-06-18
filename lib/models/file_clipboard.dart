enum ClipboardOperation { copy, cut }

class FileClipboardEntry {
  const FileClipboardEntry({
    required this.paths,
    required this.operation,
  });

  final List<String> paths;
  final ClipboardOperation operation;
}
