#!/usr/bin/env python3
# -*- coding: utf-8 -*-
from pathlib import Path

def rep(path: str, pairs: list[tuple[str, str]]) -> int:
    p = Path(path)
    text = p.read_text(encoding='utf-8')
    missing = 0
    for old, new in pairs:
        if old not in text:
            missing += 1
        else:
            text = text.replace(old, new)
    p.write_text(text, encoding='utf-8')
    return missing

L10N = "import 'package:cope_x_studio/l10n/l10n_scope.dart';\n"

def ensure_import(path: str) -> None:
    p = Path(path)
    text = p.read_text(encoding='utf-8')
    if "l10n_scope.dart" not in text:
        lines = text.splitlines(keepends=True)
        last_import = 0
        for i, line in enumerate(lines):
            if line.startswith('import '):
                last_import = i
        lines.insert(last_import + 1, L10N)
        p.write_text(''.join(lines), encoding='utf-8')

# archive_service.dart
ensure_import('lib/services/archive_service.dart')
mb = '(size / (1024 * 1024)).toStringAsFixed(0)'
mb_total = '(totalBytes / (1024 * 1024)).toStringAsFixed(0)'
mb_limit = '(_legacyMaxBytes / (1024 * 1024)).toStringAsFixed(0)'
mb_cd = '(cdSize / (1024 * 1024)).toStringAsFixed(0)'

archive_pairs = [
    ("throw const FormatException('Không đọc được danh sách file trong ZIP')",
     "throw FormatException(L10nScope.current.errCannotReadZipList)"),
    (f"""      throw ArchivePasswordException(
        'ZIP quá lớn (${{size / (1024 * 1024)).toStringAsFixed(0)}} MB). '
        'Không thể xác minh mật khẩu trong bộ nhớ.',
      );""",
     f"      throw ArchivePasswordException(L10nScope.current.errZipTooLargeVerifyPassword({mb}));"),
    (f"""      throw ArchivePasswordException(
        'ZIP mã hóa AES quá lớn (${{size / (1024 * 1024)).toStringAsFixed(0)}} MB). '
        'Giới hạn ${{(_legacyMaxBytes / (1024 * 1024)).toStringAsFixed(0)}} MB.',
      );""",
     f"      throw ArchivePasswordException(L10nScope.current.errZipAesTooLarge({mb}, {mb_limit}));"),
    (f"""      throw ArchivePasswordException(
        'ZIP quá lớn (${{size / (1024 * 1024)).toStringAsFixed(0)}} MB). '
        'Cần lệnh unzip/7z trên thiết bị.',
      );""",
     f"      throw ArchivePasswordException(L10nScope.current.errZipTooLargeNeedUnzip({mb}));"),
    ("throw UnsupportedError('flutter_archive không khả dụng trên nền tảng này')",
     "throw UnsupportedError(L10nScope.current.errFlutterArchiveUnavailable)"),
    ("throw FileSystemException('Không trích xuất được mục ZIP', innerPath)",
     "throw FileSystemException(L10nScope.current.errCannotExtractZipEntry, innerPath)"),
    ("var lastError = 'Không thể giải nén TAR'",
     "var lastError = L10nScope.current.errCannotExtractTar"),
    (f"""      throw Exception(
        'Dữ liệu quá lớn (${{totalBytes / (1024 * 1024)).toStringAsFixed(0)}} MB). '
        'Không thể nén trong bộ nhớ.',
      );""",
     f"      throw Exception(L10nScope.current.errDataTooLargeCompress({mb_total}));"),
    ("throw Exception('Không thể nén nhiều thư mục — thiếu lệnh zip trên thiết bị')",
     "throw Exception(L10nScope.current.errMultiFolderZipNoCommand)"),
    ("if (bytes == null) throw Exception('Không thể tạo file ZIP')",
     "if (bytes == null) throw Exception(L10nScope.current.errCannotCreateZip)"),
    ("throw FileSystemException('Thư mục cha không tồn tại', destinationDir)",
     "throw FileSystemException(L10nScope.current.errParentDirNotFound, destinationDir)"),
    ("throw FileSystemException('Không thể ghi vào thư mục đích', destinationDir)",
     "throw FileSystemException(L10nScope.current.errCannotWriteDestDir, destinationDir)"),
    (f"""      throw Exception(
        'File ZIP quá lớn (${{size / (1024 * 1024)).toStringAsFixed(0)}} MB). '
        'Cần giải nén native hoặc lệnh unzip.',
      );""",
     f"      throw Exception(L10nScope.current.errZipTooLargeExtract({mb}));"),
    ("throw FileSystemException('Không tìm thấy mục trong ZIP', innerPath)",
     "throw FileSystemException(L10nScope.current.errZipEntryNotFound, innerPath)"),
]

# zip_central_directory_reader.dart
ensure_import('lib/services/zip_central_directory_reader.dart')
zip_cd_pairs = [
    ("throw FileSystemException('File không tồn tại', zipPath)",
     "throw FileSystemException(L10nScope.current.errFileNotExists, zipPath)"),
    ("throw const FormatException('File ZIP không hợp lệ')",
     "throw FormatException(L10nScope.current.errInvalidZip)"),
    ("throw const FormatException('Không tìm thấy End of Central Directory')",
     "throw FormatException(L10nScope.current.errZipEocdNotFound)"),
    ("throw const FormatException('Central Directory ZIP bị hỏng')",
     "throw FormatException(L10nScope.current.errZipCdCorrupt)"),
    ("""        throw FormatException(
          'Central Directory quá lớn (${(cdSize / (1024 * 1024)).toStringAsFixed(0)} MB)',
        );""",
     f"        throw FormatException(L10nScope.current.errZipCdTooLarge({mb_cd}));"),
    ("throw const FormatException('Không đọc đủ Central Directory')",
     "throw FormatException(L10nScope.current.errZipCdIncomplete)"),
    ("throw const FormatException('ZIP64 locator không hợp lệ')",
     "throw FormatException(L10nScope.current.errZip64LocatorInvalid)"),
    ("throw const FormatException('ZIP64 EOCD signature không hợp lệ')",
     "throw FormatException(L10nScope.current.errZip64EocdInvalid)"),
    ("throw const FormatException('ZIP64 EOCD nằm ngoài file')",
     "throw FormatException(L10nScope.current.errZip64EocdOutOfFile)"),
]

# file_service.dart
ensure_import('lib/services/file_service.dart')
file_pairs = [
    ("  String toString() => 'Không thể truy cập $path: $message';",
     "  String toString() => L10nScope.current.errCannotAccessPath(path, message);"),
    ("throw FileSystemException('Đã tồn tại', dest)",
     "throw FileSystemException(L10nScope.current.errAlreadyExists, dest)"),
]

# shell_list_service.dart
ensure_import('lib/services/shell_list_service.dart')
shell_list_pairs = [
    ("throw FileAccessException(normalized, 'Thư mục không tồn tại')",
     "throw FileAccessException(normalized, L10nScope.current.errDirectoryNotExists)"),
]

# security_service.dart
ensure_import('lib/services/security_service.dart')
security_pairs = [
    ("throw StateError('Chưa có mật khẩu')", "throw StateError(L10nScope.current.errNoPassword)"),
    ("throw StateError('Cần đặt mật khẩu trước')", "throw StateError(L10nScope.current.biometricNeedsPassword)"),
    ("throw StateError('Mật khẩu hiện tại không đúng')", "throw StateError(L10nScope.current.errCurrentPasswordWrong)"),
    ("throw StateError('Mật khẩu không đúng')", "throw StateError(L10nScope.current.wrongPassword)"),
    ("throw StateError('Thiết bị không hỗ trợ sinh trắc học')", "throw StateError(L10nScope.current.biometricNotSupported)"),
    ("{String reason = 'Mở khóa Cope X Studio'}", "{String? reason}"),
    ("reason: reason,", "reason: reason ?? L10nScope.current.errBiometricUnlockReason,"),
]

# platform_bridge.dart
ensure_import('lib/services/platform_bridge.dart')
platform_pairs = [
    ("throw FileAccessException(dirPath, 'Shell listing chỉ hỗ trợ Android')",
     "throw FileAccessException(dirPath, L10nScope.current.errShellListingAndroidOnly)"),
    ("        message: 'Chế độ siêu người dùng chỉ hỗ trợ Android',",
     "        message: L10nScope.current.errSuperuserAndroidOnly,"),
    ("          message: 'Không thể kiểm tra quyền siêu người dùng',",
     "          message: L10nScope.current.errCannotCheckSuperuser,"),
    ("        message:\n            'Hết thời gian kiểm tra quyền siêu người dùng. Thiết bị có thể chưa root hoặc chưa cấp quyền.',",
     "        message: L10nScope.current.errSuperuserCheckTimeout,"),
    ("message: e.message ?? 'Không thể kiểm tra quyền siêu người dùng',",
     "message: e.message ?? L10nScope.current.errCannotCheckSuperuser,"),
    ("throw FileAccessException(apkPath, 'Cài APK chỉ hỗ trợ Android')",
     "throw FileAccessException(apkPath, L10nScope.current.errInstallApkAndroidOnly)"),
    ("throw FileAccessException(packageName, 'Không tìm thấy APK')",
     "throw FileAccessException(packageName, L10nScope.current.errApkNotFound)"),
]

# Remove const from RootAccessCheckResult where using L10nScope
platform_pairs += [
    ("return const RootAccessCheckResult(\n          granted: false,\n          message: L10nScope.current.errCannotCheckSuperuser,\n        );",
     "return RootAccessCheckResult(\n          granted: false,\n          message: L10nScope.current.errCannotCheckSuperuser,\n        );"),
    ("return const RootAccessCheckResult(\n        granted: false,\n        message: L10nScope.current.errSuperuserCheckTimeout,\n      );",
     "return RootAccessCheckResult(\n        granted: false,\n        message: L10nScope.current.errSuperuserCheckTimeout,\n      );"),
    ("return const RootAccessCheckResult(\n        granted: false,\n        message: 'Chế độ siêu người dùng chỉ hỗ trợ Android',\n      );",
     "return RootAccessCheckResult(\n        granted: false,\n        message: L10nScope.current.errSuperuserAndroidOnly,\n      );"),
]

# zip_shell_service.dart
ensure_import('lib/services/zip_shell_service.dart')
zip_shell_pairs = [
    ("throw const ArchivePasswordException('Không thể kiểm tra mật khẩu trên nền tảng này')",
     "throw ArchivePasswordException(L10nScope.current.errCannotTestPasswordOnPlatform)"),
    ("throw const ArchivePasswordException('Sai mật khẩu')",
     "throw ArchivePasswordException(L10nScope.current.wrongPassword)"),
    ("throw const ArchivePasswordException('Cần mật khẩu')",
     "throw ArchivePasswordException(L10nScope.current.errPasswordNeeded)"),
    ("throw Exception('Shell không hỗ trợ định dạng mã hóa ZIP này')",
     "throw Exception(L10nScope.current.errShellUnsupportedZipEncryption)"),
    ("Object? lastError = 'Không thể chạy lệnh unzip'",
     "Object? lastError = L10nScope.current.errCannotRunUnzip"),
    ("Object? lastError = 'Không tìm thấy lệnh 7z'",
     "Object? lastError = L10nScope.current.err7zNotFound"),
    ("throw Exception('Không thể chạy lệnh zip')",
     "throw Exception(L10nScope.current.errCannotRunZip)"),
    ("throw UnsupportedError('Shell zip không khả dụng trên nền tảng này')",
     "throw UnsupportedError(L10nScope.current.errFlutterArchiveUnavailable)"),
    ("throw ArgumentError('Danh sách nguồn nén trống')",
     "throw ArgumentError(L10nScope.current.errEmptyZipSources)"),
]

# web_server_service.dart
ensure_import('lib/services/web_server/web_server_service.dart')
web_pairs = [
    ("body: 'Cần mật khẩu',", "body: L10nScope.current.apiPasswordRequired,"),
    ("body: 'Mật khẩu sai',", "body: L10nScope.current.apiWrongPassword,"),
    ("return _jsonError('Không thể tải thư mục', 400);", "return _jsonError(L10nScope.current.apiCannotListFolder, 400);"),
    ("return _jsonError('Không tìm thấy file', 404);", "return _jsonError(L10nScope.current.apiFileNotFound, 404);"),
    ("return _jsonError('Không thể lấy thumbnail của thư mục', 400);", "return _jsonError(L10nScope.current.apiCannotFolderThumbnail, 400);"),
    ("return _jsonError('Không thể đọc thư mục', 400);", "return _jsonError(L10nScope.current.apiCannotReadFolder, 400);"),
    ("return _jsonError('File quá lớn để chỉnh sửa (>2MB)', 400);", "return _jsonError(L10nScope.current.apiFileTooLargeEdit, 400);"),
    ("return _jsonError('Thiếu tên thư mục', 400);", "return _jsonError(L10nScope.current.apiMissingFolderName, 400);"),
    ("return _jsonError('Thiếu tên file', 400);", "return _jsonError(L10nScope.current.apiMissingFileName, 400);"),
    ("return _jsonError('Thiếu tên mới', 400);", "return _jsonError(L10nScope.current.apiMissingNewName, 400);"),
    ("return _jsonError('Không có mục để xóa', 400);", "return _jsonError(L10nScope.current.apiNothingToDelete, 400);"),
    ("return _jsonError('Không thể ghi thư mục', 400);", "return _jsonError(L10nScope.current.apiCannotWriteFolder, 400);"),
    ("return _jsonError('Không có mục để nén', 400);", "return _jsonError(L10nScope.current.apiNothingToZip, 400);"),
    ("return _jsonError('Không phải file ZIP', 400);", "return _jsonError(L10nScope.current.apiNotZipFile, 400);"),
    ("return _jsonError('Thư mục đích không hợp lệ', 400);", "return _jsonError(L10nScope.current.apiInvalidDestFolder, 400);"),
    ("return _jsonError('Thiếu tên file (tham số name)', 400);", "return _jsonError(L10nScope.current.apiMissingFileNameParam, 400);"),
]

total = 0
total += rep('lib/services/archive_service.dart', archive_pairs)
total += rep('lib/services/zip_central_directory_reader.dart', zip_cd_pairs)
total += rep('lib/services/file_service.dart', file_pairs)
total += rep('lib/services/shell_list_service.dart', shell_list_pairs)
total += rep('lib/services/security_service.dart', security_pairs)
total += rep('lib/services/platform_bridge.dart', platform_pairs)
total += rep('lib/services/zip_shell_service.dart', zip_shell_pairs)
total += rep('lib/services/web_server/web_server_service.dart', web_pairs)
print(f'done missing={total}')
