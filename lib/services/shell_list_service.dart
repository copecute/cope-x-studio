import 'dart:io';

import 'package:cope_x_studio/services/file_service.dart';
import 'package:cope_x_studio/services/platform_bridge.dart';
import 'package:path/path.dart' as p;

class ListedEntry {
  const ListedEntry({
    required this.path,
    required this.isDirectory,
    this.size,
  });

  final String path;
  final bool isDirectory;
  final int? size;
}

/// Liệt kê thư mục qua shell native (Android) hoặc API Dart.
class ShellListService {
  ShellListService({PlatformBridge? platform})
      : _platform = platform ?? PlatformBridge();

  final PlatformBridge _platform;

  static bool shouldUseShell(String dirPath) {
    if (!Platform.isAndroid) return false;
    final normalized = p.normalize(dirPath.isEmpty ? '/' : dirPath);
    return normalized == '/';
  }

  Future<List<ListedEntry>> listDirectory(String dirPath, {bool showHidden = false}) {
    if (Platform.isAndroid) {
      return _platform.listDirectoryShell(dirPath, showHidden: showHidden);
    }
    return Future.value(_listWithDart(dirPath, showHidden: showHidden));
  }

  static List<ListedEntry> _listWithDart(String dirPath, {bool showHidden = false}) {
    final normalized = p.normalize(dirPath.isEmpty ? '/' : dirPath);
    final dir = Directory(normalized);
    if (!dir.existsSync()) {
      throw FileAccessException(normalized, 'Thư mục không tồn tại');
    }

    final entries = <ListedEntry>[];
    for (final entity in dir.listSync(followLinks: false)) {
      final name = p.basename(entity.path);
      if (!showHidden && name.startsWith('.')) continue;
      entries.add(
        ListedEntry(
          path: entity.path,
          isDirectory: entity is Directory,
        ),
      );
    }

    entries.sort((a, b) {
      if (a.isDirectory != b.isDirectory) return a.isDirectory ? -1 : 1;
      return p.basename(a.path).toLowerCase().compareTo(p.basename(b.path).toLowerCase());
    });
    return entries;
  }
}
