#!/usr/bin/env python3
# -*- coding: utf-8 -*-
from pathlib import Path

REPLACEMENTS = [
    ("_log('Đã mở khóa ZIP: ${p.basename(zipPath)}')", "_log(L10nScope.current.logUnlockZip(p.basename(zipPath)))"),
    ("_log('Lỗi mở khóa: $e')", "_log(L10nScope.current.logUnlockError('$e'))"),
    ("_log('Bật quyền \"Truy cập tất cả file\" trong Cài đặt')", "_log(L10nScope.current.logEnableManageStorage)"),
    ("_log('Đã cấp quyền truy cập tất cả file')", "_log(L10nScope.current.logGrantedAllFilesAccess)"),
    ("_log('Bật \"Cho phép truy cập để quản lý tất cả tệp\" trong Cài đặt')", "_log(L10nScope.current.logEnableManageAllFiles)"),
    ("_log('Tab mới: ${PathUtils.displayName(browsePath)}')", "_log(L10nScope.current.logNewTab(PathUtils.displayName(browsePath)))"),
    ("_log('Tab mới: ${tab.displayName}')", "_log(L10nScope.current.logNewTab(tab.displayName))"),
    ("_log('Vị trí: ${PathUtils.shortDisplayDir(filePath)}')", "_log(L10nScope.current.logFileLocation(PathUtils.shortDisplayDir(filePath)))"),
    ("_log('Xem ZIP: ${p.basename(zipPath)}')", "_log(L10nScope.current.logViewZip(p.basename(zipPath)))"),
    ("_log('Đã thêm $added tập tin gần đây')", "_log(L10nScope.current.logRecentAdded(added))"),
    ("_log('Đã quét ${results.length} tập tin gần đây')", "_log(L10nScope.current.logRecentScanned(results.length))"),
    ("_log('Lỗi quét tập tin gần đây: $e')", "_log(L10nScope.current.logRecentScanError('$e'))"),
    ("final label = cacheKey == 'system' ? 'hệ thống' : 'người dùng';", "final label = cacheKey == 'system' ? L10nScope.current.logAppsTypeSystem : L10nScope.current.logAppsTypeUser;"),
    ("_log('Đã thêm $added ứng dụng ($label)')", "_log(L10nScope.current.logAppsAdded(added, label))"),
    ("_log('Đã tải ${apps.length} ứng dụng')", "_log(L10nScope.current.logAppsLoaded(apps.length))"),
    ("_log('Lỗi tải ứng dụng: $e')", "_log(L10nScope.current.logAppsLoadError('$e'))"),
    ("_log('Đã đọc ${entries.length} mục tại Root')", "_log(L10nScope.current.logReadItemsRoot(entries.length))"),
    ("_log('Đã đọc ${entries.length} mục tại ${PathUtils.displayName(path)}')", "_log(L10nScope.current.logReadItemsAt(entries.length, PathUtils.displayName(path)))"),
    ("_log('Lỗi đọc ${PathUtils.displayName(path)}: $e')", "_log(L10nScope.current.logReadError(PathUtils.displayName(path), '$e'))"),
    ("_log('Mở thông tin ứng dụng')", "_log(L10nScope.current.logOpenAppInfo)"),
    ("_log('Lỗi mở thông tin ứng dụng: $e')", "_log(L10nScope.current.logOpenAppInfoError('$e'))"),
    ("_log('Đã sao chép APK: ${app.appName}')", "_log(L10nScope.current.logApkCopied(app.appName))"),
    ("_log('Lỗi sao chép APK: $e')", "_log(L10nScope.current.logApkCopyError('$e'))"),
    ("_log('Chia sẻ APK: ${app.appName}')", "_log(L10nScope.current.logApkShared(app.appName))"),
    ("_log('Lỗi chia sẻ APK: $e')", "_log(L10nScope.current.logApkShareError('$e'))"),
    ("_log('Lỗi mở Play Store: $e')", "_log(L10nScope.current.logPlayStoreError('$e'))"),
    ("_log('Đã backup APK → $path')", "_log(L10nScope.current.logApkBackup(path))"),
    ("_log('Lỗi backup APK: $e')", "_log(L10nScope.current.logApkBackupError('$e'))"),
    ("_log('Gỡ cài đặt: ${app?.appName ?? packageName}')", "_log(L10nScope.current.logUninstall(app?.appName ?? packageName))"),
    ("_log('Lỗi gỡ cài đặt: $e')", "_log(L10nScope.current.logUninstallError('$e'))"),
    ("_log('Khởi chạy ứng dụng: $packageName')", "_log(L10nScope.current.logLaunchApp(packageName))"),
    ("_log('Lỗi mở ứng dụng: $e')", "_log(L10nScope.current.logOpenAppError('$e'))"),
    ("_log('Lỗi tải màn hình chính: $e')", "_log(L10nScope.current.logHomeLoadError('$e'))"),
    ("_log('Lỗi FTP: $e')", "_log(L10nScope.current.logFtpError('$e'))"),
    ("_log('Lỗi đọc ZIP: $e')", "_log(L10nScope.current.logZipReadError('$e'))"),
    ("_log('Đã mở ${p.basename(filePath)}')", "_log(L10nScope.current.logFileOpened(p.basename(filePath)))"),
    ("_log('Lỗi mở file: $e')", "_log(L10nScope.current.logOpenAppError('$e'))"),
    ("_log('Định dạng ${FileTypeUtils.archiveFormatName(filePath)} chưa được hỗ trợ.')", "_log(L10nScope.current.logFormatNotSupportedOpen(FileTypeUtils.archiveFormatName(filePath)))"),
    ("_log('Lỗi tải tệp FTP: $e')", "_log(L10nScope.current.logFtpFileLoadError('$e'))"),
    ("_log('Tạo file mới: $name')", "_log(L10nScope.current.logCreateFile(name))"),
    ("_log('Tạo thư mục mới: $name')", "_log(L10nScope.current.logCreateFolder(name))"),
    ("_log('Đã copy ${paths.length} mục')", "_log(L10nScope.current.logCopiedItems(paths.length))"),
    ("_log('Đã cut ${paths.length} mục')", "_log(L10nScope.current.logCutItems(paths.length))"),
    ("_log('Không thể paste vào bên trong ZIP')", "_log(L10nScope.current.logCannotPasteInZip)"),
    ("_log(isMove ? 'Đang di chuyển...' : 'Đang dán...')", "_log(isMove ? L10nScope.current.moving : L10nScope.current.pasting)"),
    ("_log('Đã dán thành công')", "_log(L10nScope.current.logPasteSuccess)"),
    ("_log('Đã hủy dán')", "_log(L10nScope.current.cancelPaste)"),
    ("_log('Lỗi paste: $e')", "_log(L10nScope.current.logPasteError('$e'))"),
    ("_log('Đang nhân đôi...')", "_log(L10nScope.current.duplicating)"),
    ("_log('Đã nhân đôi ${paths.length} mục')", "_log(L10nScope.current.logDuplicateSuccess(paths.length))"),
    ("_log('Đã hủy nhân đôi')", "_log(L10nScope.current.cancelDuplicate)"),
    ("_log('Lỗi nhân đôi: $e')", "_log(L10nScope.current.logDuplicateError('$e'))"),
    ("_log('Đang xóa ${paths.length} mục...')", "_log(L10nScope.current.deleting)"),
    ("_log('Đã dừng xóa')", "_log(L10nScope.current.deleteStopped)"),
    ("_log(_useTrash ? 'Đã chuyển ${paths.length} mục vào thùng rác' : 'Đã xóa ${paths.length} mục')", "_log(_useTrash ? L10nScope.current.logMovedToTrash(paths.length) : L10nScope.current.logDeletedItems(paths.length))"),
    ("_log('Lỗi xóa: $e')", "_log(L10nScope.current.logDeleteError('$e'))"),
    ("_log('Đã đổi tên thành $newName')", "_log(L10nScope.current.logRenamedTo(newName))"),
    ("_log('Đang nén...')", "_log(L10nScope.current.zipping)"),
    ("_log('Đã nén thành $zipName')", "_log(L10nScope.current.logZippedTo(zipName))"),
    ("_log('Đã hủy nén')", "_log(L10nScope.current.cancelZip)"),
    ("_log('Lỗi nén ZIP: $e')", "_log(L10nScope.current.logZipError('$e'))"),
    ("_log('Đang giải nén...')", "_log(L10nScope.current.unzipping)"),
    ("_log('Đã giải nén vào $folderName')", "_log(L10nScope.current.logUnzipTo(folderName))"),
    ("_log('Đã hủy giải nén')", "_log(L10nScope.current.cancelUnzip)"),
    ("_log('Lỗi giải nén: $e')", "_log(L10nScope.current.logUnzipError('$e'))"),
    ("_log('File APK không tồn tại')", "_log(L10nScope.current.logApkNotFound)"),
    ("_log('Lỗi cài APK: $e')", "_log(L10nScope.current.logInstallApkError('$e'))"),
    ("_log('Đang mở file từ ZIP...')", "_log(L10nScope.current.logOpeningFromZip)"),
    ("_log('Đang chuẩn bị chia sẻ file từ ZIP...')", "_log(L10nScope.current.logPrepareShareFromZip)"),
    ("_log('Lỗi chia sẻ file: $e')", "_log(L10nScope.current.logShareFileError('$e'))"),
    ("_log('Định dạng $format chưa được hỗ trợ giải nén trực tiếp.')", "_log(L10nScope.current.logFormatNotSupportedDirect(format))"),
    ("_log('Đã lưu ${p.basename(editor.filePath ?? '')}')", "_log(L10nScope.current.logFileSaved(p.basename(editor.filePath ?? '')))"),
    ("_log('Lỗi lưu: $e')", "_log(L10nScope.current.logSaveError('$e'))"),
    ("_log('Đã tắt web server')", "_log(L10nScope.current.logWebServerStopped)"),
    ("_log('Lỗi bật web server: $e')", "_log(L10nScope.current.logWebServerStartError('$e'))"),
    ("'Các mục đã xóa không thể khôi phục. Phần còn lại chưa bị xóa.'", "L10nScope.current.logDeletePartialNotice"),
    ("          ? 'Đã mở trình cài đặt'", "          ? L10nScope.current.openWithDone"),
    ("      TabFileOperation.unzip => 'Đã hủy giải nén',\n      TabFileOperation.zip => 'Đã hủy nén',\n      TabFileOperation.paste => 'Đã hủy dán',\n      TabFileOperation.duplicate => 'Đã hủy nhân đôi',\n      _ => 'Đã hủy thao tác',", "      TabFileOperation.unzip => l10n.cancelUnzip,\n      TabFileOperation.zip => l10n.cancelZip,\n      TabFileOperation.paste => l10n.cancelPaste,\n      TabFileOperation.duplicate => l10n.cancelDuplicate,\n      _ => l10n.cancelOperation,"),
]

OLD_WS = """      final authNote = verifier != null ? ' (có mật khẩu)' : '';
      final url = NetworkUtils.buildPreferredUrl(addresses, WebServerService.port);
      final scopeNote = restrictToRoots ? ' — thư mục: $sharedRoot' : ' — toàn bộ bộ nhớ';
      _log('Web server$authNote: ${url ?? addresses.join(', ')}$scopeNote');"""

NEW_WS = """      final l10n = L10nScope.current;
      final authNote = verifier != null ? l10n.logWebServerAuthWith : '';
      final url = NetworkUtils.buildPreferredUrl(addresses, WebServerService.port);
      final scopeNote = restrictToRoots
          ? l10n.logWebServerScopeFolder(sharedRoot!)
          : l10n.logWebServerScopeAll;
      _log(l10n.logWebServerStarted(authNote, url ?? addresses.join(', '), scopeNote));"""

path = Path('lib/providers/workspace_provider.dart')
text = path.read_text(encoding='utf-8')
missing = 0
for old, new in REPLACEMENTS:
    if old not in text:
        missing += 1
    else:
        text = text.replace(old, new)

if OLD_WS not in text:
    missing += 1
else:
    text = text.replace(OLD_WS, NEW_WS)

path.write_text(text, encoding='utf-8')
print(f'done missing={missing}')
