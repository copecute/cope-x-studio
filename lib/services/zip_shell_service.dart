import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cope_x_studio/models/zip_entry_meta.dart';
import 'package:cope_x_studio/services/archive_cancel_token.dart';
import 'package:cope_x_studio/services/archive_password_exception.dart';
import 'package:cope_x_studio/utils/entry_progress_tracker.dart';
import 'package:path/path.dart' as p;

/// Giải nén / liệt kê ZIP qua lệnh `unzip` hệ thống (Android/Linux).
class ZipShellService {
  static bool get isAvailable => Platform.isAndroid || Platform.isLinux;

  static Process? _activeProcess;

  static Future<void> abortActiveExtraction() async {
    final process = _activeProcess;
    _activeProcess = null;
    if (process != null) {
      try {
        process.kill(ProcessSignal.sigkill);
      } catch (_) {}
    }
  }

  static bool _isWrongPassword(String stderr, [String stdout = '']) {
    final s = '$stderr $stdout'.toLowerCase();
    return s.contains('bad password') ||
        s.contains('wrong password') ||
        s.contains('incorrect password') ||
        s.contains('bad crc');
  }

  static bool _needsPassword(String stderr, [String stdout = '']) {
    final s = '$stderr $stdout'.toLowerCase();
    return s.contains('need password') || s.contains('no password');
  }

  /// Kiểm tra mật khẩu ZIP (unzip -t, hoặc 7z nếu có).
  static Future<void> testArchive(String zipPath, String password) async {
    if (!isAvailable) {
      throw const ArchivePasswordException('Không thể kiểm tra mật khẩu trên nền tảng này');
    }

    final unzipArgs = ['-t', '-P', password, zipPath];
    final unzipCommands = [
      ['/system/bin/unzip', ...unzipArgs],
      ['unzip', ...unzipArgs],
    ];

    for (final cmd in unzipCommands) {
      try {
        final result = await Process.run(cmd.first, cmd.sublist(1));
        if (result.exitCode == 0) return;
        if (_isWrongPassword(result.stderr as String, result.stdout as String)) {
          throw const ArchivePasswordException('Sai mật khẩu');
        }
        if (_needsPassword(result.stderr as String, result.stdout as String)) {
          throw const ArchivePasswordException('Cần mật khẩu');
        }
      } catch (e) {
        if (e is ArchivePasswordException) rethrow;
      }
    }

    final sevenZArgs = ['t', '-p$password', '-y', zipPath];
    final sevenZCommands = [
      ['/system/bin/7z', ...sevenZArgs],
      ['/system/bin/7za', ...sevenZArgs],
      ['7z', ...sevenZArgs],
      ['7za', ...sevenZArgs],
    ];

    for (final cmd in sevenZCommands) {
      try {
        final result = await Process.run(cmd.first, cmd.sublist(1));
        if (result.exitCode == 0) return;
        if (_isWrongPassword(result.stderr as String, result.stdout as String)) {
          throw const ArchivePasswordException('Sai mật khẩu');
        }
        if (_needsPassword(result.stderr as String, result.stdout as String)) {
          throw const ArchivePasswordException('Cần mật khẩu');
        }
      } catch (e) {
        if (e is ArchivePasswordException) rethrow;
      }
    }

    throw Exception('Shell không hỗ trợ định dạng mã hóa ZIP này');
  }

  static Future<List<ZipEntryMeta>?> listContents(String zipPath) async {
    if (!isAvailable) return null;

    final commands = [
      ['/system/bin/unzip', '-l', zipPath],
      ['unzip', '-l', zipPath],
    ];

    for (final cmd in commands) {
      try {
        final result = await Process.run(cmd.first, cmd.sublist(1));
        if (result.exitCode == 0) {
          return _parseListOutput(result.stdout as String);
        }
      } catch (_) {}
    }
    return null;
  }

  static Future<void> extractTo({
    required String zipPath,
    required String destDir,
    String? password,
    int totalFiles = 0,
    ArchiveCancelToken? cancelToken,
    void Function(double progress, String? currentFile)? onProgress,
  }) async {
    if (cancelToken?.isCancelled == true) {
      throw const ArchiveCancelledException();
    }

    final dest = Directory(destDir);
    if (!dest.existsSync()) {
      await dest.create(recursive: true);
    }

    var total = totalFiles;
    if (total <= 0) {
      total = (await listContents(zipPath))?.length ?? 0;
    }
    final tracker = EntryProgressTracker(total > 0 ? total : 1);

    final args = <String>['-o', zipPath, '-d', destDir];
    if (password != null && password.isNotEmpty) {
      args.insertAll(0, ['-P', password]);
    }

    final commands = [
      ['/system/bin/unzip', ...args],
      ['unzip', ...args],
    ];

    Object? lastError = 'Không thể chạy lệnh unzip';
    for (final cmd in commands) {
      Process? process;
      try {
        process = await Process.start(cmd.first, cmd.sublist(1));
        _activeProcess = process;
        final stderr = StringBuffer();

        process.stderr.transform(utf8.decoder).listen(stderr.write);

        await for (final line in process.stdout.transform(utf8.decoder).transform(const LineSplitter())) {
          if (cancelToken?.isCancelled == true) {
            process.kill(ProcessSignal.sigkill);
            throw const ArchiveCancelledException();
          }

          final trimmed = line.trim();
          final file = _parseExtractedFileLine(trimmed);
          if (file != null) {
            onProgress?.call(tracker.advance(file), file);
          }
        }

        final code = await process.exitCode;
        _activeProcess = null;
        if (cancelToken?.isCancelled == true) {
          throw const ArchiveCancelledException();
        }
        if (code == 0) {
          onProgress?.call(1.0, null);
          return;
        }
        final errText = stderr.toString().trim();
        if (_isWrongPassword(errText)) {
          throw const ArchivePasswordException('Sai mật khẩu');
        }
        lastError = errText.isEmpty ? 'unzip exit $code' : errText;
      } on ArchiveCancelledException {
        _activeProcess = null;
        rethrow;
      } on ArchivePasswordException {
        _activeProcess = null;
        rethrow;
      } catch (e) {
        _activeProcess = null;
        if (e is ArchivePasswordException || e is ArchiveCancelledException) rethrow;
        if (process != null) {
          try {
            process.kill(ProcessSignal.sigkill);
          } catch (_) {}
        }
        lastError = e;
      }
    }

    if (cancelToken?.isCancelled == true) {
      throw const ArchiveCancelledException();
    }

    if (password != null && password.isNotEmpty) {
      await _extractWith7z(
        zipPath: zipPath,
        destDir: destDir,
        password: password,
        cancelToken: cancelToken,
        onProgress: onProgress,
      );
      return;
    }

    throw Exception(lastError);
  }

  static String? _parseExtractedFileLine(String line) {
    const prefixes = [
      'inflating:',
      'extracting:',
      '  inflating:',
      '  extracting:',
      'creating:',
      '  creating:',
    ];
    for (final prefix in prefixes) {
      if (line.startsWith(prefix)) {
        final file = line.substring(prefix.length).trim();
        return file.isEmpty ? null : file;
      }
    }
    return null;
  }

  static Future<void> _extractWith7z({
    required String zipPath,
    required String destDir,
    required String password,
    ArchiveCancelToken? cancelToken,
    void Function(double progress, String? currentFile)? onProgress,
  }) async {
    if (cancelToken?.isCancelled == true) {
      throw const ArchiveCancelledException();
    }

    final args = ['x', '-p$password', '-o$destDir', '-y', zipPath];
    final commands = [
      ['/system/bin/7z', ...args],
      ['/system/bin/7za', ...args],
      ['7z', ...args],
      ['7za', ...args],
    ];

    Object? lastError = 'Không tìm thấy lệnh 7z';
    for (final cmd in commands) {
      try {
        final result = await Process.run(cmd.first, cmd.sublist(1));
        if (result.exitCode == 0) {
          onProgress?.call(1.0, null);
          return;
        }
        final errText = '${result.stderr}';
        if (_isWrongPassword(errText, '${result.stdout}')) {
          throw const ArchivePasswordException('Sai mật khẩu');
        }
        lastError = errText.trim().isEmpty ? '7z exit ${result.exitCode}' : errText.trim();
      } catch (e) {
        if (e is ArchivePasswordException) rethrow;
        lastError = e;
      }
    }
    throw Exception(lastError);
  }

  static Future<String?> extractEntryToDir({
    required String zipPath,
    required String innerPath,
    required String destDir,
    String? password,
  }) async {
    if (!isAvailable) return null;

    final norm = innerPath.replaceAll('\\', '/');
    final args = <String>['-o', zipPath, norm, '-d', destDir];
    if (password != null && password.isNotEmpty) {
      args.insertAll(0, ['-P', password]);
    }

    final commands = [
      ['/system/bin/unzip', ...args],
      ['unzip', ...args],
    ];

    for (final cmd in commands) {
      try {
        final result = await Process.run(cmd.first, cmd.sublist(1));
        if (result.exitCode == 0) {
          final out = p.join(destDir, norm);
          if (File(out).existsSync()) return out;
          final flat = p.join(destDir, p.basename(norm));
          if (File(flat).existsSync()) return flat;
          return out;
        }
        if (_isWrongPassword('${result.stderr}', '${result.stdout}')) {
          throw const ArchivePasswordException('Sai mật khẩu');
        }
      } catch (e) {
        if (e is ArchivePasswordException) rethrow;
      }
    }

    if (password != null && password.isNotEmpty) {
      final args = ['x', '-p$password', '-o$destDir', '-y', zipPath, norm];
      final commands = [
        ['/system/bin/7z', ...args],
        ['/system/bin/7za', ...args],
        ['7z', ...args],
        ['7za', ...args],
      ];
      for (final cmd in commands) {
        try {
          final result = await Process.run(cmd.first, cmd.sublist(1));
          if (result.exitCode == 0) {
            final out = p.join(destDir, norm);
            if (File(out).existsSync()) return out;
            final flat = p.join(destDir, p.basename(norm));
            if (File(flat).existsSync()) return flat;
            return out;
          }
          if (_isWrongPassword('${result.stderr}', '${result.stdout}')) {
            throw const ArchivePasswordException('Sai mật khẩu');
          }
        } catch (e) {
          if (e is ArchivePasswordException) rethrow;
        }
      }
    }
    return null;
  }

  /// Nén file/thư mục qua lệnh `zip` / `7z` — RAM thấp, hỗ trợ tiến độ và hủy.
  static Future<void> createFromPaths({
    required List<String> sources,
    required String zipPath,
    String? password,
    ArchiveCancelToken? cancelToken,
    void Function(double progress, String? currentFile)? onProgress,
  }) async {
    if (!isAvailable) {
      throw UnsupportedError('Shell zip không khả dụng trên nền tảng này');
    }
    if (sources.isEmpty) {
      throw ArgumentError('Danh sách nguồn nén trống');
    }
    if (cancelToken?.isCancelled == true) {
      throw const ArchiveCancelledException();
    }

    final out = File(zipPath);
    if (!out.parent.existsSync()) {
      await out.parent.create(recursive: true);
    }
    if (out.existsSync()) {
      await out.delete();
    }

    final total = await _countZipSources(sources);
    final tracker = EntryProgressTracker(total > 0 ? total : 1);

    if (sources.length == 1 && Directory(sources.first).existsSync()) {
      final dir = Directory(sources.first);
      final parent = dir.parent.path;
      final name = p.basename(dir.path);
      final args = <String>['-r', zipPath, name];
      if (password != null && password.isNotEmpty) {
        args.insertAll(0, ['-P', password]);
      }

      final ok = await _runZipCommand(
        zipPath: zipPath,
        args: args,
        workingDirectory: parent,
        cancelToken: cancelToken,
        onProgress: onProgress,
        tracker: tracker,
      );
      if (ok) {
        onProgress?.call(1.0, p.basename(zipPath));
        return;
      }
    } else {
      final commonParent = _commonParentDir(sources);
      final relSources = sources.map((source) {
        final normalized = p.normalize(source);
        if (p.isWithin(commonParent, normalized) || normalized == commonParent) {
          return p.relative(normalized, from: commonParent);
        }
        return normalized;
      }).toList();

      final args = <String>['-r', zipPath, ...relSources];
      if (password != null && password.isNotEmpty) {
        args.insertAll(0, ['-P', password]);
      }

      final ok = await _runZipCommand(
        zipPath: zipPath,
        args: args,
        workingDirectory: commonParent,
        cancelToken: cancelToken,
        onProgress: onProgress,
        tracker: tracker,
      );
      if (ok) {
        onProgress?.call(1.0, p.basename(zipPath));
        return;
      }
    }

    if (password != null && password.isNotEmpty) {
      await _createWith7z(
        sources: sources,
        zipPath: zipPath,
        password: password,
        cancelToken: cancelToken,
        onProgress: onProgress,
        tracker: tracker,
      );
      return;
    }

    throw Exception('Không thể chạy lệnh zip');
  }

  static Future<bool> _runZipCommand({
    required String zipPath,
    required List<String> args,
    required String workingDirectory,
    ArchiveCancelToken? cancelToken,
    void Function(double progress, String? currentFile)? onProgress,
    required EntryProgressTracker tracker,
  }) async {
    final commands = [
      ['/system/bin/zip', ...args],
      ['zip', ...args],
    ];

    for (final cmd in commands) {
      Process? process;
      try {
        process = await Process.start(
          cmd.first,
          cmd.sublist(1),
          workingDirectory: workingDirectory,
        );
        _activeProcess = process;
        final stderr = StringBuffer();

        process.stderr.transform(utf8.decoder).listen(stderr.write);

        await for (final line in process.stdout.transform(utf8.decoder).transform(const LineSplitter())) {
          if (cancelToken?.isCancelled == true) {
            process.kill(ProcessSignal.sigkill);
            throw const ArchiveCancelledException();
          }

          final file = _parseAddingFileLine(line.trim());
          if (file != null) {
            onProgress?.call(tracker.advance(file), file);
          }
        }

        final code = await process.exitCode;
        _activeProcess = null;
        if (cancelToken?.isCancelled == true) {
          throw const ArchiveCancelledException();
        }
        if (code == 0 && File(zipPath).existsSync()) {
          return true;
        }
      } on ArchiveCancelledException {
        _activeProcess = null;
        rethrow;
      } catch (_) {
        _activeProcess = null;
        if (process != null) {
          try {
            process.kill(ProcessSignal.sigkill);
          } catch (_) {}
        }
      }
    }
    return false;
  }

  static Future<void> _createWith7z({
    required List<String> sources,
    required String zipPath,
    required String password,
    ArchiveCancelToken? cancelToken,
    void Function(double progress, String? currentFile)? onProgress,
    required EntryProgressTracker tracker,
  }) async {
    if (cancelToken?.isCancelled == true) {
      throw const ArchiveCancelledException();
    }

    final commonParent = _commonParentDir(sources);
    final relSources = sources.map((source) {
      final normalized = p.normalize(source);
      if (p.isWithin(commonParent, normalized) || normalized == commonParent) {
        return p.relative(normalized, from: commonParent);
      }
      return normalized;
    }).toList();

    final args = ['a', '-tzip', '-p$password', '-y', zipPath, ...relSources];
    final commands = [
      ['/system/bin/7z', ...args],
      ['/system/bin/7za', ...args],
      ['7z', ...args],
      ['7za', ...args],
    ];

    Object? lastError = 'Không tìm thấy lệnh 7z';
    for (final cmd in commands) {
      try {
        final result = await Process.run(
          cmd.first,
          cmd.sublist(1),
          workingDirectory: commonParent,
        );
        if (result.exitCode == 0 && File(zipPath).existsSync()) {
          onProgress?.call(1.0, p.basename(zipPath));
          return;
        }
        final errText = '${result.stderr}';
        if (_isWrongPassword(errText, '${result.stdout}')) {
          throw const ArchivePasswordException('Sai mật khẩu');
        }
        lastError = errText.trim().isEmpty ? '7z exit ${result.exitCode}' : errText.trim();
      } catch (e) {
        if (e is ArchivePasswordException || e is ArchiveCancelledException) rethrow;
        lastError = e;
      }
    }
    throw Exception(lastError);
  }

  static String? _parseAddingFileLine(String line) {
    for (final prefix in ['adding:', 'updating:']) {
      if (line.startsWith(prefix)) {
        var rest = line.substring(prefix.length).trim();
        final paren = rest.indexOf(' (');
        if (paren > 0) rest = rest.substring(0, paren).trim();
        return rest.isEmpty ? null : rest;
      }
    }
    return null;
  }

  static Future<int> _countZipSources(List<String> sources) async {
    var count = 0;
    for (final source in sources) {
      final type = FileSystemEntity.typeSync(source);
      if (type == FileSystemEntityType.file) {
        count++;
      } else if (type == FileSystemEntityType.directory) {
        count += await _countDirectoryFiles(Directory(source));
      }
    }
    return count;
  }

  static Future<int> _countDirectoryFiles(Directory dir) async {
    var count = 0;
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) count++;
    }
    return count;
  }

  static String _commonParentDir(List<String> paths) {
    if (paths.isEmpty) return Directory.current.path;
    var common = p.normalize(
      Directory(paths.first).existsSync() ? paths.first : p.dirname(paths.first),
    );
    if (FileSystemEntity.isDirectorySync(common)) {
      common = p.dirname(common);
    }
    for (final path in paths.skip(1)) {
      var normalized = p.normalize(path);
      if (Directory(normalized).existsSync()) {
        normalized = p.dirname(normalized);
      } else {
        normalized = p.dirname(normalized);
      }
      while (!p.isWithin(common, normalized) && common != normalized) {
        final next = p.dirname(common);
        if (next == common) return Directory.current.path;
        common = next;
      }
    }
    return common;
  }

  static List<ZipEntryMeta> _parseListOutput(String output) {
    final entries = <ZipEntryMeta>[];
    final lines = output.split('\n');
    var inList = false;

    for (final raw in lines) {
      final line = raw.trimRight();
      if (line.startsWith('---------')) {
        inList = true;
        continue;
      }
      if (!inList || line.isEmpty) continue;
      if (line.startsWith('Archive:') || line.startsWith('Length')) continue;

      final match = RegExp(r'^\s*(\d+)\s+\d{2,4}-\d{2}-\d{2}\s+\d{1,2}:\d{2}\s+(.+)$').firstMatch(line);
      if (match == null) continue;

      final size = int.tryParse(match.group(1)!) ?? 0;
      var name = match.group(2)!.trim();
      if (name.isEmpty) continue;

      final isDir = name.endsWith('/');
      if (isDir) name = name.substring(0, name.length - 1);

      entries.add(
        ZipEntryMeta(
          name: name,
          uncompressedSize: size,
          isDirectory: isDir,
        ),
      );
    }

    return entries;
  }
}
