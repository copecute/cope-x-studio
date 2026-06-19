import 'dart:io';

import 'package:path/path.dart' as p;

class PathGuardException implements Exception {
  PathGuardException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Web server: toàn quyền truy cập file hệ thống (theo quyền app).
class PathGuard {
  PathGuard({
    required String defaultRoot,
    List<String>? knownRoots,
    bool restrictToRoots = false,
  })  : defaultRoot = p.normalize(defaultRoot),
        knownRoots = (knownRoots ?? [defaultRoot]).map(p.normalize).toList(),
        restrictToRoots = restrictToRoots;

  final String defaultRoot;
  final List<String> knownRoots;
  final bool restrictToRoots;

  String resolve(String? pathParam) {
    if (pathParam == null || pathParam.trim().isEmpty) return defaultRoot;

    final decoded = pathParam.trim();
    final resolved = p.isAbsolute(decoded)
        ? p.normalize(decoded)
        : p.normalize(p.join(defaultRoot, decoded));

    if (resolved.contains('\u0000')) {
      throw PathGuardException('Đường dẫn không hợp lệ');
    }

    if (restrictToRoots && !_isWithinKnownRoots(resolved)) {
      throw PathGuardException('Ngoài thư mục chia sẻ');
    }
    return resolved;
  }

  bool _isWithinKnownRoots(String path) {
    final normalized = p.normalize(path);
    for (final root in knownRoots) {
      final r = p.normalize(root);
      if (normalized == r || normalized.startsWith('$r${p.separator}')) {
        return true;
      }
    }
    return false;
  }

  bool existsOrParentExists(String path) {
    if (FileSystemEntity.typeSync(path) != FileSystemEntityType.notFound) {
      return true;
    }
    final parent = p.dirname(path);
    return parent != path && Directory(parent).existsSync();
  }
}
