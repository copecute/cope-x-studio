import 'dart:io';

import 'package:cope_x_studio/models/recent_file_entry.dart';
import 'package:cope_x_studio/utils/file_type_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// Quét ổ đĩa và trả về [maxResults] tệp có thời gian sửa đổi mới nhất.
class RecentFilesScanner {
  RecentFilesScanner._();

  static const maxResults = 50;

  static Future<List<RecentFileEntry>> scan({
    required List<String> roots,
    required bool showHidden,
    int? maxResults = 50,
    bool imageOnly = false,
  }) {
    final options = _ScanOptions(
      roots: roots,
      showHidden: showHidden,
      maxResults: maxResults,
      imageOnly: imageOnly,
    );
    return compute(_scan, options);
  }

  static List<RecentFileEntry> _scan(_ScanOptions options) {
    final tracker = options.maxResults != null ? _TopKTracker(options.maxResults!) : null;
    final allHits = <_Hit>[];
    final seen = <String>{};

    for (final root in options.roots) {
      final dir = Directory(root);
      if (!dir.existsSync()) continue;
      _walkDirectory(
        dir,
        options: options,
        tracker: tracker,
        allHits: allHits,
        seen: seen,
      );
    }

    if (tracker != null) {
      return tracker.toEntries();
    } else {
      allHits.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
      return allHits
          .map((hit) => RecentFileEntry(path: hit.path, modifiedAt: hit.modifiedAt, size: hit.size))
          .toList();
    }
  }

  static void _walkDirectory(
    Directory root, {
    required _ScanOptions options,
    required _TopKTracker? tracker,
    required List<_Hit> allHits,
    required Set<String> seen,
  }) {
    final stack = <Directory>[root];

    while (stack.isNotEmpty) {
      final dir = stack.removeLast();
      final List<FileSystemEntity> children;
      try {
        children = dir.listSync(followLinks: false);
      } catch (_) {
        continue;
      }

      for (final entity in children) {
        final name = p.basename(entity.path);
        if (!options.showHidden && name.startsWith('.')) continue;

        if (entity is Directory) {
          if (_shouldSkipDirectory(entity.path, name)) continue;
          stack.add(entity);
          continue;
        }

        if (entity is! File) continue;
        if (options.imageOnly && !FileTypeUtils.isImage(entity.path)) continue;

        final key = _dedupeKey(entity.path);
        if (seen.contains(key)) continue;
        seen.add(key);

        try {
          final stat = entity.statSync();
          if (stat.type != FileSystemEntityType.file) continue;
          
          if (tracker != null) {
            tracker.consider(
              path: entity.path,
              modifiedAt: stat.modified,
              size: stat.size,
            );
          } else {
            allHits.add(_Hit(
              path: entity.path,
              modifiedAt: stat.modified,
              size: stat.size,
            ));
          }
        } catch (_) {}
      }
    }
  }

  static bool _shouldSkipDirectory(String path, String name) {
    if (!Platform.isAndroid || name != 'Android') return false;
    final parent = p.normalize(p.dirname(path));
    return parent == '/storage/emulated/0' ||
        parent == '/sdcard' ||
        RegExp(r'^/storage/[^/]+$').hasMatch(parent);
  }

  static String _dedupeKey(String path) {
    final normalized = p.normalize(path);
    return Platform.isWindows ? normalized.toLowerCase() : normalized;
  }
}

class _ScanOptions {
  const _ScanOptions({
    required this.roots,
    required this.showHidden,
    this.maxResults,
    this.imageOnly = false,
  });

  final List<String> roots;
  final bool showHidden;
  final int? maxResults;
  final bool imageOnly;
}

class _TopKTracker {
  _TopKTracker(this.capacity);

  final int capacity;
  final List<_Hit> _hits = [];

  void consider({
    required String path,
    required DateTime modifiedAt,
    required int size,
  }) {
    if (_hits.length < capacity) {
      _insert(_Hit(path: path, modifiedAt: modifiedAt, size: size));
      return;
    }

    final oldest = _hits.last;
    if (!modifiedAt.isAfter(oldest.modifiedAt)) return;
    _hits.removeLast();
    _insert(_Hit(path: path, modifiedAt: modifiedAt, size: size));
  }

  void _insert(_Hit hit) {
    var i = 0;
    while (i < _hits.length && !hit.modifiedAt.isAfter(_hits[i].modifiedAt)) {
      i++;
    }
    _hits.insert(i, hit);
    if (_hits.length > capacity) {
      _hits.removeLast();
    }
  }

  List<RecentFileEntry> toEntries() {
    return _hits
        .map(
          (hit) => RecentFileEntry(
            path: hit.path,
            modifiedAt: hit.modifiedAt,
            size: hit.size,
          ),
        )
        .toList();
  }
}

class _Hit {
  const _Hit({
    required this.path,
    required this.modifiedAt,
    required this.size,
  });

  final String path;
  final DateTime modifiedAt;
  final int size;
}
