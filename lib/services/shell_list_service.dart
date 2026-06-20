import 'dart:io';

import 'package:cope_x_studio/models/root_access_mode.dart';
import 'package:cope_x_studio/services/file_service.dart';
import 'package:cope_x_studio/services/platform_bridge.dart';
import 'package:path/path.dart' as p;
import 'package:cope_x_studio/l10n/l10n_scope.dart';

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

  static bool shouldUseShell(String dirPath, {required RootAccessMode mode}) {
    if (!Platform.isAndroid || mode == RootAccessMode.disabled) return false;
    final normalized = p.normalize(dirPath.isEmpty ? '/' : dirPath);
    if (normalized == '/') return true;
    if (mode.usesSuperuser && isRootFilesystemPath(normalized)) return true;
    return false;
  }

  static bool isRootFilesystemPath(String dirPath) {
    if (!dirPath.startsWith('/')) return false;
    final normalized = p.normalize(dirPath);
    if (normalized == '/storage/emulated/0' || normalized.startsWith('/storage/emulated/0/')) {
      return false;
    }
    return true;
  }

  Future<List<ListedEntry>> listDirectory(
    String dirPath, {
    bool showHidden = false,
    RootAccessMode rootMode = RootAccessMode.normal,
  }) async {
    if (Platform.isAndroid) {
      try {
        return await _platform.listDirectoryShell(
          dirPath,
          showHidden: showHidden,
          rootMode: rootMode,
        );
      } catch (e) {
        if (rootMode.usesSuperuser) rethrow;
        return _listWithDart(dirPath, showHidden: showHidden);
      }
    }
    return _listWithDart(dirPath, showHidden: showHidden);
  }

  Future<RootAccessCheckResult> checkRootAccess(RootAccessMode mode) {
    if (!mode.usesSuperuser) {
      return Future.value(const RootAccessCheckResult(granted: true));
    }
    return _platform.checkRootAccess(mountWritable: mode.mountWritable);
  }

  static List<ListedEntry> _listWithDart(String dirPath, {bool showHidden = false}) {
    final normalized = p.normalize(dirPath.isEmpty ? '/' : dirPath);
    final dir = Directory(normalized);
    if (!dir.existsSync()) {
      if (normalized == '/') {
        return _listRootFallback(showHidden: showHidden);
      }
      throw FileAccessException(normalized, L10nScope.current.errDirectoryNotExists);
    }

    try {
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

      if (entries.isEmpty && normalized == '/') {
        return _listRootFallback(showHidden: showHidden);
      }

      entries.sort((a, b) {
        if (a.isDirectory != b.isDirectory) return a.isDirectory ? -1 : 1;
        return p.basename(a.path).toLowerCase().compareTo(p.basename(b.path).toLowerCase());
      });
      return entries;
    } catch (_) {
      if (normalized == '/') {
        return _listRootFallback(showHidden: showHidden);
      }
      rethrow;
    }
  }

  static const _rootFallbackNames = [
    'acct', 'apex', 'bin', 'cache', 'config', 'd', 'data', 'dev', 'etc',
    'linkerconfig', 'mnt', 'odm', 'oem', 'opt', 'proc', 'product', 'sbin',
    'sdcard', 'storage', 'sys', 'system', 'vendor',
  ];

  static List<ListedEntry> _listRootFallback({bool showHidden = false}) {
    final entries = <ListedEntry>[];
    for (final name in _rootFallbackNames) {
      if (!showHidden && name.startsWith('.')) continue;
      final path = '/$name';
      final entity = FileSystemEntity.typeSync(path);
      if (entity == FileSystemEntityType.notFound) continue;
      entries.add(
        ListedEntry(
          path: path,
          isDirectory: entity == FileSystemEntityType.directory,
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
