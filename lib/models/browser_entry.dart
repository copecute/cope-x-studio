class BrowserEntry {
  const BrowserEntry({
    required this.name,
    required this.path,
    required this.isDirectory,
    this.size,
    this.isZipVirtual = false,
  });

  final String name;
  final String path;
  final bool isDirectory;
  final int? size;
  final bool isZipVirtual;
}
