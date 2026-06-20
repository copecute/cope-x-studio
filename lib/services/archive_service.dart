import 'dart:io';

import 'package:archive/archive.dart';
import 'package:cope_x_studio/models/browser_entry.dart';
import 'package:cope_x_studio/models/zip_entry_meta.dart';
import 'package:cope_x_studio/services/archive_cancel_token.dart';
import 'package:cope_x_studio/services/archive_password_exception.dart';
import 'package:cope_x_studio/services/zip_central_directory_reader.dart';
import 'package:cope_x_studio/utils/entry_progress_tracker.dart';
import 'package:cope_x_studio/services/zip_shell_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_archive/flutter_archive.dart' as fa;
import 'package:path/path.dart' as p;

class ArchiveService {
  ArchiveService({
    ZipCentralDirectoryReader? centralDirectoryReader,
  }) : _centralDirectoryReader = centralDirectoryReader ?? ZipCentralDirectoryReader();

  final ZipCentralDirectoryReader _centralDirectoryReader;

  final Map<String, List<ZipEntryMeta>> _entryCache = {};

  static const _legacyMaxBytes = 48 * 1024 * 1024;

  static double normalizeProgress(double progress) {
    final value = progress > 1.0 ? progress / 100.0 : progress;
    return value.clamp(0.0, 1.0);
  }

  Future<void> abortExtraction() => ZipShellService.abortActiveExtraction();

  void clearZipCache([String? zipPath]) {
    if (zipPath == null) {
      _entryCache.clear();
    } else {
      _entryCache.remove(zipPath);
    }
  }

  /// Liệt kê nội dung ZIP (metadata) — không giải nén, RAM thấp.
  /// Danh sách file có thể đọc được mà không cần mật khẩu.
  Future<List<BrowserEntry>> listZipContents(
    String zipPath,
    String innerPath, {
    String? password,
  }) async {
    final entries = await _loadZipEntries(zipPath);
    return _mapToBrowserEntries(entries, innerPath);
  }

  /// Alias tương thích code cũ.
  Future<List<BrowserEntry>> listZipDirectory(
    String zipPath,
    String innerPath, {
    String? password,
  }) =>
      listZipContents(zipPath, innerPath, password: password);

  Future<List<ZipEntryMeta>> _loadZipEntries(String zipPath) async {
    final cached = _entryCache[zipPath];
    if (cached != null && cached.isNotEmpty) return cached;

    List<ZipEntryMeta>? entries;

    try {
      entries = await _centralDirectoryReader.readEntries(zipPath);
      if (entries.isEmpty) entries = null;
    } catch (_) {
      entries = null;
    }

    if (entries == null && ZipShellService.isAvailable) {
      try {
        entries = await ZipShellService.listContents(zipPath);
      } catch (_) {}
    }

    if (entries == null || entries.isEmpty) {
      throw const FormatException('Không đọc được danh sách file trong ZIP');
    }

    _entryCache[zipPath] = entries;
    return entries;
  }

  Future<bool> isPasswordProtected(String zipPath) async {
    try {
      final entries = await _loadZipEntries(zipPath);
      return entries.any((e) => e.isEncrypted);
    } catch (_) {
      return false;
    }
  }

  Future<bool> _usesAesEncryption(String zipPath) async {
    try {
      final entries = await _loadZipEntries(zipPath);
      return entries.any((e) => e.isAesEncrypted);
    } catch (_) {
      return false;
    }
  }

  /// Xác minh mật khẩu bằng shell test (RAM thấp) hoặc decode mẫu nhỏ.
  Future<void> verifyZipPassword(String zipPath, String password) async {
    if (password.isEmpty) {
      throw const ArchivePasswordException('Vui lòng nhập mật khẩu');
    }

    if (ZipShellService.isAvailable) {
      try {
        await ZipShellService.testArchive(zipPath, password);
        return;
      } on ArchivePasswordException {
        rethrow;
      } catch (_) {}
    }

    final size = await File(zipPath).length();
    if (size > _legacyMaxBytes) {
      throw ArchivePasswordException(
        'ZIP quá lớn (${(size / (1024 * 1024)).toStringAsFixed(0)} MB). '
        'Không thể xác minh mật khẩu trong bộ nhớ.',
      );
    }

    await _verifyPasswordWithLegacyDecode(zipPath, password);
  }

  Future<void> _verifyPasswordWithLegacyDecode(String zipPath, String password) async {
    final size = await File(zipPath).length();
    if (size > _legacyMaxBytes) {
      throw ArchivePasswordException(
        'ZIP mã hóa AES quá lớn (${(size / (1024 * 1024)).toStringAsFixed(0)} MB). '
        'Giới hạn ${(_legacyMaxBytes / (1024 * 1024)).toStringAsFixed(0)} MB.',
      );
    }

    final bytes = await File(zipPath).readAsBytes();
    try {
      ZipDecoder().decodeBytes(bytes, password: password);
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('password') ||
          msg.contains('bad crc') ||
          msg.contains('decrypt') ||
          msg.contains('password error')) {
        throw const ArchivePasswordException('Sai mật khẩu');
      }
      rethrow;
    }
  }

  List<BrowserEntry> _mapToBrowserEntries(List<ZipEntryMeta> entries, String innerPath) {
    final prefix = innerPath.isEmpty ? '' : '${innerPath.replaceAll('\\', '/')}/';
    final children = <String, BrowserEntry>{};

    final parentToChildren = <String, Set<String>>{};
    for (final entry in entries) {
      final name = entry.normalizedName;
      final cleanName = name.endsWith('/') ? name.substring(0, name.length - 1) : name;
      final parts = cleanName.split('/');
      for (var i = 0; i < parts.length; i++) {
        final parent = parts.sublist(0, i).join('/');
        final child = parts[i];
        parentToChildren.putIfAbsent(parent, () => {}).add(child);
      }
    }

    for (final entry in entries) {
      var name = entry.normalizedName;
      if (prefix.isNotEmpty) {
        if (!name.startsWith(prefix)) continue;
        name = name.substring(prefix.length);
      }
      if (name.isEmpty) continue;

      final parts = name.split('/');
      final childName = parts.first;
      if (childName.isEmpty) continue;

      final childInner = innerPath.isEmpty ? childName : '$innerPath/$childName';
      final childInnerNormalized = childInner.replaceAll('\\', '/');

      if (parts.length == 1) {
        children[childName] = BrowserEntry(
          name: childName,
          path: childInner,
          isDirectory: entry.isDirectory,
          size: entry.isDirectory ? null : entry.uncompressedSize,
          isZipVirtual: true,
          childrenCount: entry.isDirectory ? (parentToChildren[childInnerNormalized]?.length ?? 0) : null,
        );
      } else if (!children.containsKey(childName)) {
        children[childName] = BrowserEntry(
          name: childName,
          path: childInner,
          isDirectory: true,
          isZipVirtual: true,
          childrenCount: parentToChildren[childInnerNormalized]?.length ?? 0,
        );
      }
    }

    final list = children.values.toList();
    list.sort((a, b) {
      if (a.isDirectory != b.isDirectory) return a.isDirectory ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return list;
  }

  /// Giải nén ZIP theo đường dẫn file — native / shell, có tiến độ.
  Future<void> unzipTo(
    String zipPath,
    String destinationDir, {
    String? password,
    ArchiveProgressCallback? onProgress,
    ArchiveCancelToken? cancelToken,
  }) async {
    _ensureWritableDest(destinationDir);
    if (cancelToken?.isCancelled == true) {
      throw const ArchiveCancelledException();
    }

    final hasPassword = password != null && password.isNotEmpty;
    if (!hasPassword) {
      final protected = await isPasswordProtected(zipPath);
      if (protected) {
        throw const ArchivePasswordException('File ZIP được bảo vệ bằng mật khẩu');
      }

      try {
        await _unzipWithFlutterArchive(
          zipPath,
          destinationDir,
          onProgress: onProgress,
          cancelToken: cancelToken,
        );
        return;
      } catch (_) {
        if (ZipShellService.isAvailable) {
          await _unzipWithShell(
            zipPath,
            destinationDir,
            onProgress: onProgress,
            cancelToken: cancelToken,
          );
          return;
        }
        rethrow;
      }
    }

    await _unzipPasswordProtected(
      zipPath,
      destinationDir,
      password,
      onProgress: onProgress,
      cancelToken: cancelToken,
    );
  }

  Future<void> _unzipPasswordProtected(
    String zipPath,
    String destinationDir,
    String password, {
    ArchiveProgressCallback? onProgress,
    ArchiveCancelToken? cancelToken,
  }) async {
    if (cancelToken?.isCancelled == true) throw const ArchiveCancelledException();

    if (ZipShellService.isAvailable) {
      try {
        await _unzipWithShell(
          zipPath,
          destinationDir,
          password: password,
          onProgress: onProgress,
          cancelToken: cancelToken,
        );
        return;
      } on ArchivePasswordException {
        rethrow;
      } on ArchiveCancelledException {
        rethrow;
      } catch (_) {}
    }

    final size = await File(zipPath).length();
    if (size > _legacyMaxBytes) {
      throw ArchivePasswordException(
        'ZIP quá lớn (${(size / (1024 * 1024)).toStringAsFixed(0)} MB). '
        'Cần lệnh unzip/7z trên thiết bị.',
      );
    }

    await _unzipLegacyInMemory(zipPath, destinationDir, password: password);
    onProgress?.call(1.0, null);
  }

  Future<int> _countAllZipEntries(String zipPath) async {
    try {
      final entries = await _loadZipEntries(zipPath);
      return entries.length;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _unzipWithFlutterArchive(
    String zipPath,
    String destinationDir, {
    ArchiveProgressCallback? onProgress,
    ArchiveCancelToken? cancelToken,
  }) async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      throw UnsupportedError('flutter_archive không khả dụng trên nền tảng này');
    }

    if (cancelToken?.isCancelled == true) throw const ArchiveCancelledException();

    final totalEntries = await _countAllZipEntries(zipPath);
    final tracker = EntryProgressTracker(totalEntries > 0 ? totalEntries : 1);

    final zipFile = File(zipPath);
    final dest = Directory(destinationDir);
    if (!dest.existsSync()) {
      await dest.create(recursive: true);
    }

    try {
      await fa.ZipFile.extractToDirectory(
        zipFile: zipFile,
        destinationDir: dest,
        zipFileCharset: 'UTF-8',
        onExtracting: (zipEntry, progress) {
          if (cancelToken?.isCancelled == true) {
            return fa.ZipFileOperation.cancel;
          }
          onProgress?.call(
            tracker.advance(zipEntry.name),
            zipEntry.name,
          );
          return fa.ZipFileOperation.includeItem;
        },
      );
    } catch (e) {
      if (cancelToken?.isCancelled == true) {
        throw const ArchiveCancelledException();
      }
      rethrow;
    }

    if (cancelToken?.isCancelled == true) {
      throw const ArchiveCancelledException();
    }
    onProgress?.call(1.0, null);
  }

  Future<void> _unzipWithShell(
    String zipPath,
    String destinationDir, {
    String? password,
    ArchiveProgressCallback? onProgress,
    ArchiveCancelToken? cancelToken,
  }) async {
    if (!ZipShellService.isAvailable) {
      await _unzipLegacyInMemory(zipPath, destinationDir, password: password);
      return;
    }

    final totalFiles = await _countAllZipEntries(zipPath);

    await ZipShellService.extractTo(
      zipPath: zipPath,
      destDir: destinationDir,
      password: password,
      totalFiles: totalFiles,
      cancelToken: cancelToken,
      onProgress: onProgress,
    );
  }

  Future<void> extractEntry(
    String zipPath,
    String innerPath,
    String destDir, {
    String? password,
  }) async {
    _ensureWritableDest(destDir);

    final hasPassword = password != null && password.isNotEmpty;
    if (hasPassword && await _usesAesEncryption(zipPath)) {
      await _extractEntryLegacy(zipPath, innerPath, destDir, password: password);
      return;
    }

    if (ZipShellService.isAvailable) {
      final path = await ZipShellService.extractEntryToDir(
        zipPath: zipPath,
        innerPath: innerPath,
        destDir: destDir,
        password: password,
      );
      if (path != null) return;
    }

    await _extractEntryLegacy(zipPath, innerPath, destDir, password: password);
  }

  Future<String> extractEntryToTemp(
    String zipPath,
    String innerPath, {
    String? password,
  }) async {
    final tempDir = await Directory.systemTemp.createTemp('cope_zip_open_');
    final hasPassword = password != null && password.isNotEmpty;

    if (hasPassword && await _usesAesEncryption(zipPath)) {
      await _extractEntryLegacy(zipPath, innerPath, tempDir.path, password: password);
      final norm = innerPath.replaceAll('\\', '/');
      final out = p.join(tempDir.path, p.basename(norm));
      if (!File(out).existsSync()) {
        throw FileSystemException('Không trích xuất được mục ZIP', innerPath);
      }
      return out;
    }

    if (ZipShellService.isAvailable) {
      final path = await ZipShellService.extractEntryToDir(
        zipPath: zipPath,
        innerPath: innerPath,
        destDir: tempDir.path,
        password: password,
      );
      if (path != null && File(path).existsSync()) return path;
    }

    await _extractEntryLegacy(zipPath, innerPath, tempDir.path, password: password);
    final norm = innerPath.replaceAll('\\', '/');
    final out = p.join(tempDir.path, p.basename(norm));
    if (!File(out).existsSync()) {
      throw FileSystemException('Không trích xuất được mục ZIP', innerPath);
    }
    return out;
  }

  Future<void> extractTar(String tarPath, String destDir) async {
    final dest = Directory(destDir);
    if (!dest.existsSync()) {
      await dest.create(recursive: true);
    }

    final commands = [
      ['/system/bin/tar', 'xf', tarPath, '-C', destDir],
      ['/system/bin/toybox', 'tar', 'xf', tarPath, '-C', destDir],
      ['tar', 'xf', tarPath, '-C', destDir],
    ];

    var lastError = 'Không thể giải nén TAR';
    for (final cmd in commands) {
      try {
        final result = await Process.run(cmd.first, cmd.sublist(1));
        if (result.exitCode == 0) return;
        if ((result.stderr as String).isNotEmpty) {
          lastError = result.stderr as String;
        }
      } catch (_) {}
    }
    throw Exception(lastError);
  }

  Future<void> zipPaths(
    List<String> sources,
    String zipPath, {
    String? password,
    ArchiveProgressCallback? onProgress,
    ArchiveCancelToken? cancelToken,
  }) async {
    if (onProgress != null || cancelToken != null) {
      await _zipWithProgress(
        sources,
        zipPath,
        password: password,
        onProgress: onProgress,
        cancelToken: cancelToken,
      );
      return;
    }

    final hasPassword = password != null && password.isNotEmpty;
    if (hasPassword || kIsWeb || !(Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      await _zipLegacyInMemory(sources, zipPath, password: password);
      return;
    }
    await _zipWithFlutterArchive(sources, zipPath);
  }

  void _checkZipCancel(ArchiveCancelToken? cancelToken) {
    if (cancelToken?.isCancelled == true) throw const ArchiveCancelledException();
  }

  Future<List<({String archivePath, String filePath})>> _collectZipFileEntries(
    List<String> sources,
  ) async {
    final entries = <({String archivePath, String filePath})>[];
    for (final source in sources) {
      final type = FileSystemEntity.typeSync(source);
      if (type == FileSystemEntityType.directory) {
        await _collectDirectoryZipEntries(Directory(source), p.basename(source), entries);
      } else if (type == FileSystemEntityType.file) {
        entries.add((archivePath: p.basename(source), filePath: source));
      }
    }
    return entries;
  }

  Future<void> _collectDirectoryZipEntries(
    Directory dir,
    String basePath,
    List<({String archivePath, String filePath})> entries,
  ) async {
    await for (final entity in dir.list(recursive: false, followLinks: false)) {
      final name = p.basename(entity.path);
      final archivePath = basePath.isEmpty ? name : '$basePath/$name';

      if (entity is Directory) {
        await _collectDirectoryZipEntries(entity, archivePath, entries);
      } else if (entity is File) {
        entries.add((archivePath: archivePath, filePath: entity.path));
      }
    }
  }

  Future<void> _zipWithProgress(
    List<String> sources,
    String zipPath, {
    String? password,
    ArchiveProgressCallback? onProgress,
    ArchiveCancelToken? cancelToken,
  }) async {
    _checkZipCancel(cancelToken);

    final hasPassword = password != null && password.isNotEmpty;

    if (ZipShellService.isAvailable) {
      try {
        await ZipShellService.createFromPaths(
          sources: sources,
          zipPath: zipPath,
          password: password,
          cancelToken: cancelToken,
          onProgress: onProgress,
        );
        return;
      } on ArchiveCancelledException {
        rethrow;
      } catch (_) {
        if (hasPassword) rethrow;
      }
    }

    if (!hasPassword &&
        !kIsWeb &&
        (Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      await _zipWithFlutterArchiveProgress(
        sources,
        zipPath,
        onProgress: onProgress,
        cancelToken: cancelToken,
      );
      return;
    }

    final totalBytes = await _estimateZipSourcesBytes(sources);
    if (totalBytes > _legacyMaxBytes) {
      throw Exception(
        'Dữ liệu quá lớn (${(totalBytes / (1024 * 1024)).toStringAsFixed(0)} MB). '
        'Không thể nén trong bộ nhớ.',
      );
    }

    await _zipLegacyInMemoryWithProgress(
      sources,
      zipPath,
      password: password,
      onProgress: onProgress,
      cancelToken: cancelToken,
    );
  }

  Future<void> _zipWithFlutterArchiveProgress(
    List<String> sources,
    String zipPath, {
    ArchiveProgressCallback? onProgress,
    ArchiveCancelToken? cancelToken,
  }) async {
    _checkZipCancel(cancelToken);

    final out = File(zipPath);
    if (!out.parent.existsSync()) {
      await out.parent.create(recursive: true);
    }

    fa.OnZipping? onZipping;
    if (onProgress != null || cancelToken != null) {
      onZipping = (filePath, isDirectory, progress) {
        if (cancelToken?.isCancelled == true) return fa.ZipFileOperation.cancel;
        onProgress?.call(normalizeProgress(progress), p.basename(filePath));
        return fa.ZipFileOperation.includeItem;
      };
    }

    if (sources.length == 1 && Directory(sources.first).existsSync()) {
      await fa.ZipFile.createFromDirectory(
        sourceDir: Directory(sources.first),
        zipFile: out,
        includeBaseDirectory: true,
        recurseSubDirs: true,
        onZipping: onZipping,
      );
      _checkZipCancel(cancelToken);
      onProgress?.call(1.0, p.basename(zipPath));
      return;
    }

    final hasDirectory = sources.any((s) => Directory(s).existsSync());
    if (hasDirectory) {
      throw Exception('Không thể nén nhiều thư mục — thiếu lệnh zip trên thiết bị');
    }

    final commonParent = _commonParentDir(sources);
    final files = sources.map(File.new).where((f) => f.existsSync()).toList();
    if (files.isEmpty) {
      throw Exception('Không có file hợp lệ để nén');
    }

    onProgress?.call(0, p.basename(files.first.path));
    await fa.ZipFile.createFromFiles(
      sourceDir: Directory(commonParent),
      files: files,
      zipFile: out,
    );
    _checkZipCancel(cancelToken);
    onProgress?.call(1.0, p.basename(zipPath));
  }

  Future<int> _estimateZipSourcesBytes(List<String> sources) async {
    var total = 0;
    for (final source in sources) {
      final type = FileSystemEntity.typeSync(source);
      if (type == FileSystemEntityType.file) {
        total += await File(source).length();
      } else if (type == FileSystemEntityType.directory) {
        total += await _directoryBytes(Directory(source));
      }
    }
    return total;
  }

  Future<int> _directoryBytes(Directory dir) async {
    var total = 0;
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    return total;
  }

  Future<void> _zipLegacyInMemoryWithProgress(
    List<String> sources,
    String zipPath, {
    String? password,
    ArchiveProgressCallback? onProgress,
    ArchiveCancelToken? cancelToken,
  }) async {
    _checkZipCancel(cancelToken);

    final fileEntries = await _collectZipFileEntries(sources);
    final tracker = EntryProgressTracker(fileEntries.length + 1);
    final archive = Archive();

    for (final entry in fileEntries) {
      _checkZipCancel(cancelToken);
      final data = await File(entry.filePath).readAsBytes();
      archive.addFile(ArchiveFile(entry.archivePath, data.length, data));
      onProgress?.call(tracker.advance(), p.basename(entry.filePath));
    }

    _checkZipCancel(cancelToken);
    onProgress?.call(tracker.advance(), 'Đang ghi ZIP');

    final encoder = password != null && password.isNotEmpty
        ? ZipEncoder(password: password)
        : ZipEncoder();
    final bytes = encoder.encode(archive);
    if (bytes == null) throw Exception('Không thể tạo file ZIP');

    _checkZipCancel(cancelToken);

    final out = File(zipPath);
    if (!out.parent.existsSync()) {
      await out.parent.create(recursive: true);
    }
    await out.writeAsBytes(bytes);
    onProgress?.call(1.0, p.basename(zipPath));
  }

  Future<void> _zipWithFlutterArchive(List<String> sources, String zipPath) async {
    final out = File(zipPath);
    if (!out.parent.existsSync()) {
      await out.parent.create(recursive: true);
    }

    if (sources.length == 1 && Directory(sources.first).existsSync()) {
      await fa.ZipFile.createFromDirectory(
        sourceDir: Directory(sources.first),
        zipFile: out,
        includeBaseDirectory: true,
        recurseSubDirs: true,
      );
      return;
    }

    final commonParent = _commonParentDir(sources);
    final files = sources.map(File.new).where((f) => f.existsSync()).toList();
    await fa.ZipFile.createFromFiles(
      sourceDir: Directory(commonParent),
      files: files,
      zipFile: out,
    );
  }

  String _commonParentDir(List<String> paths) {
    if (paths.isEmpty) return Directory.current.path;
    var common = p.normalize(p.dirname(paths.first));
    for (final path in paths.skip(1)) {
      final parent = p.normalize(p.dirname(path));
      while (!p.isWithin(common, parent) && common != parent) {
        final next = p.dirname(common);
        if (next == common) return Directory.current.path;
        common = next;
      }
    }
    return common;
  }

  void _ensureWritableDest(String destinationDir) {
    try {
      final dir = Directory(destinationDir);
      if (!dir.parent.existsSync() && destinationDir != '/') {
        throw FileSystemException('Thư mục cha không tồn tại', destinationDir);
      }
    } on FileSystemException {
      rethrow;
    } catch (e) {
      throw FileSystemException('Không thể ghi vào thư mục đích', destinationDir);
    }
  }

  Future<void> _unzipLegacyInMemory(
    String zipPath,
    String destinationDir, {
    String? password,
  }) async {
    final size = await File(zipPath).length();
    if (size > _legacyMaxBytes) {
      throw Exception(
        'File ZIP quá lớn (${(size / (1024 * 1024)).toStringAsFixed(0)} MB). '
        'Cần giải nén native hoặc lệnh unzip.',
      );
    }

    final bytes = await File(zipPath).readAsBytes();
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(
        bytes,
        password: password != null && password.isNotEmpty ? password : null,
      );
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('password') ||
          msg.contains('bad crc') ||
          msg.contains('decrypt') ||
          msg.contains('password error')) {
        throw const ArchivePasswordException('Sai mật khẩu hoặc file bị lỗi');
      }
      rethrow;
    }

    final dest = Directory(destinationDir);
    if (!dest.existsSync()) {
      await dest.create(recursive: true);
    }

    for (final file in archive.files) {
      if (!file.isFile) continue;
      final outPath = p.join(destinationDir, file.name);
      final outFile = File(outPath);
      if (!outFile.parent.existsSync()) {
        await outFile.parent.create(recursive: true);
      }
      await outFile.writeAsBytes(file.content as List<int>);
    }
  }

  Future<void> _extractEntryLegacy(
    String zipPath,
    String innerPath,
    String destDir, {
    String? password,
  }) async {
    final size = await File(zipPath).length();
    if (size > _legacyMaxBytes) {
      throw Exception('File ZIP quá lớn để trích xuất mục đơn lẻ trong RAM');
    }

    final bytes = await File(zipPath).readAsBytes();
    Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(
        bytes,
        password: password != null && password.isNotEmpty ? password : null,
      );
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('password') ||
          msg.contains('bad crc') ||
          msg.contains('decrypt') ||
          msg.contains('password error')) {
        throw const ArchivePasswordException('Sai mật khẩu');
      }
      rethrow;
    }

    final normInner = innerPath.replaceAll('\\', '/');
    for (final file in archive.files) {
      final normName = file.name.replaceAll('\\', '/');
      if (normName == normInner && file.isFile) {
        final outPath = p.join(destDir, p.basename(normName));
        await File(outPath).writeAsBytes(file.content as List<int>);
        return;
      }
    }
    throw FileSystemException('Không tìm thấy mục trong ZIP', innerPath);
  }

  Future<void> _zipLegacyInMemory(List<String> sources, String zipPath, {String? password}) async {
    final archive = Archive();
    for (final source in sources) {
      final type = FileSystemEntity.typeSync(source);
      if (type == FileSystemEntityType.directory) {
        await _addDirectoryToArchive(archive, Directory(source), p.basename(source));
      } else if (type == FileSystemEntityType.file) {
        final data = await File(source).readAsBytes();
        archive.addFile(ArchiveFile(p.basename(source), data.length, data));
      }
    }

    final encoder = password != null && password.isNotEmpty
        ? ZipEncoder(password: password)
        : ZipEncoder();
    final bytes = encoder.encode(archive);
    if (bytes == null) throw Exception('Không thể tạo file ZIP');

    final out = File(zipPath);
    if (!out.parent.existsSync()) {
      await out.parent.create(recursive: true);
    }
    await out.writeAsBytes(bytes);
  }

  Future<void> _addDirectoryToArchive(
    Archive archive,
    Directory dir,
    String basePath,
  ) async {
    await for (final entity in dir.list(recursive: false, followLinks: false)) {
      final name = p.basename(entity.path);
      final archivePath = basePath.isEmpty ? name : '$basePath/$name';

      if (entity is Directory) {
        await _addDirectoryToArchive(archive, entity, archivePath);
      } else if (entity is File) {
        final data = await entity.readAsBytes();
        archive.addFile(ArchiveFile(archivePath, data.length, data));
      }
    }
  }
}

typedef ArchiveProgressCallback = void Function(double progress, String? currentFile);
