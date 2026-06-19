import 'dart:typed_data';

class BrowserEntry {
  const BrowserEntry({
    required this.name,
    required this.path,
    required this.isDirectory,
    this.size,
    this.isZipVirtual = false,
    this.subtitle,
    this.isVirtual = false,
    this.iconBytes,
  });

  final String name;
  final String path;
  final bool isDirectory;
  final int? size;
  final bool isZipVirtual;
  final String? subtitle;
  final bool isVirtual;
  final Uint8List? iconBytes;
}

