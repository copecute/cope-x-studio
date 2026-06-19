class ZipEntryMeta {
  const ZipEntryMeta({
    required this.name,
    required this.uncompressedSize,
    required this.isDirectory,
    this.isEncrypted = false,
    this.isAesEncrypted = false,
  });

  final String name;
  final int uncompressedSize;
  final bool isDirectory;
  final bool isEncrypted;
  final bool isAesEncrypted;

  String get normalizedName => name.replaceAll('\\', '/');
}

typedef ArchiveProgressCallback = void Function(double progress, String? currentEntry);
