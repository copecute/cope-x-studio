// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Cope X Studio';

  @override
  String get settings => 'Cài đặt';

  @override
  String get back => 'Quay lại';

  @override
  String get cancel => 'Hủy';

  @override
  String get ok => 'Đồng ý';

  @override
  String get confirm => 'Xác nhận';

  @override
  String get save => 'Lưu';

  @override
  String get close => 'Đóng';

  @override
  String get delete => 'Xóa';

  @override
  String get rename => 'Đổi tên';

  @override
  String get search => 'Tìm kiếm';

  @override
  String get retry => 'Thử lại';

  @override
  String get done => 'Xong';

  @override
  String get shortcutApps => 'Quản lý ứng dụng';

  @override
  String get shortcutSdCard => 'Thẻ nhớ SD';

  @override
  String get shortcutInternalStorage => 'Bộ nhớ trong';

  @override
  String get shortcutSystemAppsSubtitle => 'Hệ thống · Cài đặt';

  @override
  String extractingProgress(int percent) {
    return 'Đang giải nén: $percent%';
  }

  @override
  String storageFreeOfTotal(String free, String total) {
    return 'Trống $free trên tổng số $total';
  }

  @override
  String get language => 'Ngôn ngữ';

  @override
  String get languageEnglish => 'Tiếng Anh';

  @override
  String get languageVietnamese => 'Tiếng Việt';

  @override
  String get sectionAppLock => 'Khóa ứng dụng';

  @override
  String get sectionBiometrics => 'Sinh trắc học';

  @override
  String get sectionRootAccess => 'Truy cập Root';

  @override
  String get sectionDisplay => 'Hiển thị';

  @override
  String get sectionTextEditor => 'Văn bản & trình soạn thảo';

  @override
  String get sectionUiAndActions => 'Giao diện & thao tác';

  @override
  String get sectionApplication => 'Ứng dụng';

  @override
  String get appLockTitle => 'Khóa ứng dụng';

  @override
  String get appLockSubtitleActive => 'Yêu cầu mật khẩu sau 1 phút rời app. Chạm để đổi mật khẩu.';

  @override
  String get appLockSubtitleInactive => 'Khóa đang tắt. Chạm để đổi mật khẩu.';

  @override
  String get appLockSubtitleSetup => 'Chạm để đặt mật khẩu, sau đó bật switch để kích hoạt.';

  @override
  String get passwordChanged => 'Đã đổi mật khẩu';

  @override
  String get passwordSet => 'Đã đặt mật khẩu';

  @override
  String get changePassword => 'Đổi mật khẩu';

  @override
  String get setPassword => 'Đặt mật khẩu';

  @override
  String get passwordHint => 'Mật khẩu dùng để khóa app khi mở lại (sau 1 phút rời app).';

  @override
  String get passwordLabel => 'Mật khẩu';

  @override
  String get passwordEmptyError => 'Mật khẩu không được để trống';

  @override
  String get savePassword => 'Lưu mật khẩu';

  @override
  String get biometricNotSupported => 'Thiết bị không hỗ trợ vân tay / Face ID.';

  @override
  String get biometricUnlockTitle => 'Mở khóa bằng sinh trắc học';

  @override
  String get biometricUnlockSubtitle => 'Dùng vân tay hoặc Face ID thay mật khẩu';

  @override
  String get biometricNeedsPassword => 'Cần đặt mật khẩu trước';

  @override
  String get checkingSuperuser => 'Đang kiểm tra quyền siêu người dùng...';

  @override
  String get showHiddenFiles => 'Hiển thị tệp tin ẩn';

  @override
  String get showHiddenFilesSubtitle => 'Hiện tệp tin bắt đầu bằng dấu chấm hoặc tệp hệ thống';

  @override
  String get openApkAsZip => 'Mở APK như ZIP';

  @override
  String get openApkAsZipSubtitle => 'Duyệt file APK như ZIP. Tắt để mở bằng trình cài đặt hệ thống.';

  @override
  String get textEncoding => 'Mã hóa văn bản';

  @override
  String get textEncodingSheetTitle => 'Mã hóa văn bản';

  @override
  String get textEncodingSheetSubtitle => 'Dùng khi mở và lưu file văn bản trong trình soạn thảo.';

  @override
  String editorFontSize(int size) {
    return 'Cỡ chữ trình soạn thảo ($size)';
  }

  @override
  String get editorFontSizeSubtitle => 'Chỉ áp dụng trong trình soạn thảo, không ảnh hưởng giao diện chung';

  @override
  String get editorLineNumbers => 'Hiển thị số dòng';

  @override
  String get editorLineNumbersSubtitle => 'Cột số dòng bên trái trong trình soạn thảo';

  @override
  String get editorWordWrap => 'Xuống dòng tự động (Word wrap)';

  @override
  String get editorWordWrapSubtitle => 'Tự xuống dòng khi văn bản dài hơn chiều rộng màn hình';

  @override
  String get themeModeTitle => 'Chế độ giao diện';

  @override
  String uiScale(int percent) {
    return 'Kích thước hiển thị ($percent%)';
  }

  @override
  String get fullscreen => 'Toàn màn hình';

  @override
  String get fullscreenSubtitle => 'Ẩn thanh trạng thái và điều hướng hệ thống';

  @override
  String get hapticFeedback => 'Rung khi hoàn tất thao tác';

  @override
  String get hapticFeedbackSubtitle => 'Phản hồi rung nhẹ sau khi sao chép, di chuyển hoặc xóa';

  @override
  String get rememberLastPath => 'Nhớ đường dẫn gần nhất';

  @override
  String get rememberLastPathSubtitle => 'Mở lại tab và thư mục khi khởi động lại app';

  @override
  String get requireExitConfirmation => 'Yêu cầu xác nhận khi thoát';

  @override
  String get requireExitConfirmationSubtitle => 'Hiện hộp thoại trước khi đóng ứng dụng';

  @override
  String get useTrash => 'Sử dụng thùng rác';

  @override
  String get useTrashSubtitle => 'Xóa file sẽ chuyển vào /copecute/.trash và tự xóa sau 30 ngày';

  @override
  String get add => 'Thêm';

  @override
  String get copy => 'Copy';

  @override
  String get cut => 'Cut';

  @override
  String get paste => 'Paste';

  @override
  String get share => 'Chia sẻ';

  @override
  String get refresh => 'Làm mới';

  @override
  String get parentFolder => 'Thư mục cha';

  @override
  String get extract => 'Giải nén';

  @override
  String get searchInFolder => 'Tìm kiếm trong thư mục...';

  @override
  String get hideHiddenFilesToggle => 'Ẩn tệp ẩn';

  @override
  String get showHiddenFilesToggle => 'Hiện tệp ẩn';

  @override
  String get pleaseWait => 'Vui lòng đợi...';

  @override
  String get understood => 'Đã hiểu';

  @override
  String get grantPermission => 'Cấp quyền';

  @override
  String get storagePermissionTitle => 'Cần quyền truy cập tất cả file';

  @override
  String get storagePermissionBody => 'Bật MANAGE_EXTERNAL_STORAGE để duyệt toàn bộ bộ nhớ.';

  @override
  String get newFile => 'File mới';

  @override
  String get newFolder => 'Thư mục mới';

  @override
  String selectedCount(int count) {
    return '$count đã chọn';
  }

  @override
  String get duplicate => 'Nhân đôi';

  @override
  String get installApk => 'Cài đặt APK';

  @override
  String get openAs => 'Mở như';

  @override
  String get openWithSystem => 'Mở bằng ứng dụng khác';

  @override
  String get openInNewTab => 'Mở trong tab mới';

  @override
  String get revealLocation => 'Xem vị trí file';

  @override
  String get details => 'Chi tiết';

  @override
  String get openApp => 'Mở ứng dụng';

  @override
  String get appInfo => 'Thông tin ứng dụng';

  @override
  String get copyApk => 'Sao chép APK';

  @override
  String get shareApk => 'Chia sẻ APK';

  @override
  String get viewPlayStore => 'Xem trên Play Store';

  @override
  String get backupApk => 'Backup APK (Trích xuất)';

  @override
  String get uninstall => 'Gỡ cài đặt';

  @override
  String get openAsText => 'Văn bản';

  @override
  String get openAsImage => 'Hình ảnh';

  @override
  String get openAsAudio => 'Âm nhạc';

  @override
  String get openAsVideo => 'Video';

  @override
  String get openAsArchive => 'File nén';

  @override
  String get viewModeList => 'Danh sách';

  @override
  String get viewModeGrid => 'Lưới';

  @override
  String get viewModeTree => 'Cây thư mục';

  @override
  String get emptyFolder => 'Thư mục trống';

  @override
  String get emptyZip => 'ZIP trống';

  @override
  String get noApps => 'Không có ứng dụng';

  @override
  String get noRecentFiles => 'Không tìm thấy tập tin gần đây';

  @override
  String get noSearchResults => 'Không tìm thấy kết quả';

  @override
  String get loadingFtp => 'Đang tải thư mục FTP...';

  @override
  String get loadingZip => 'Đang đọc nội dung ZIP...';

  @override
  String get loadingDirectory => 'Đang đọc thư mục...';

  @override
  String get loadingApps => 'Đang tải danh sách ứng dụng...';

  @override
  String get scanningStorage => 'Đang quét bộ nhớ...';

  @override
  String get scanningRecent => 'Đang quét tập tin gần đây...';

  @override
  String get extractingAndOpening => 'Đang giải nén và mở file...';

  @override
  String get ftpConnectionError => 'Lỗi kết nối FTP';

  @override
  String get cannotReadDirectory => 'Không thể đọc thư mục';

  @override
  String cannotReadPath(String name) {
    return 'Không thể đọc $name';
  }

  @override
  String get cannotLoadApps => 'Không thể tải ứng dụng';

  @override
  String pathCopied(String path) {
    return 'Đã sao chép đường dẫn: $path';
  }

  @override
  String get noFilesToZip => 'Không có tập tin để nén';

  @override
  String formatNotSupportedExtract(String format) {
    return 'Định dạng $format chưa được hỗ trợ giải nén.';
  }

  @override
  String get zipPasswordExtractTitle => 'Giải nén file ZIP có mật khẩu';

  @override
  String get zipFileTitle => 'Nén file ZIP';

  @override
  String get fileName => 'Tên file';

  @override
  String get passwordProtect => 'Bảo vệ bằng mật khẩu';

  @override
  String get compress => 'Nén';

  @override
  String get passwordOptional => 'Mật khẩu (tùy chọn)';

  @override
  String get wrongPasswordRetry => 'Mật khẩu sai. Vui lòng nhập lại.';

  @override
  String get zipPasswordProtected => 'File nén được bảo vệ bằng mật khẩu.';

  @override
  String get unlock => 'Mở khóa';

  @override
  String get editFtpConfig => 'Chỉnh sửa cấu hình';

  @override
  String get deleteFtpServer => 'Xóa cấu hình máy chủ';

  @override
  String get editFtpServer => 'Chỉnh sửa máy chủ FTP';

  @override
  String get addFtpServer => 'Thêm máy chủ FTP';

  @override
  String get displayName => 'Tên gợi nhớ';

  @override
  String get hostAddress => 'Địa chỉ IP / Host';

  @override
  String get port => 'Cổng (Port)';

  @override
  String get username => 'Tên đăng nhập';

  @override
  String itemCount(int count) {
    return '$count mục';
  }

  @override
  String get zipCurrentFolder => 'Nén thư mục hiện tại';

  @override
  String get zipRecentFiles => 'Nén các tập tin gần đây';

  @override
  String get zipCopiedItems => 'Nén các mục đã copy';

  @override
  String get deselectAll => 'Bỏ chọn tất cả';

  @override
  String get select => 'Chọn';

  @override
  String get selectAll => 'Chọn tất cả';

  @override
  String get move => 'Di chuyển';

  @override
  String get shortcutHome => 'Trang chủ';

  @override
  String get shortcutRecent => 'Các tập tin gần đây';

  @override
  String get shortcutFtp => 'FTP';

  @override
  String get shortcutAddFtp => '+ Thêm máy chủ';

  @override
  String get deviceStorage => 'Bộ nhớ thiết bị';

  @override
  String get systemApps => 'Hệ thống';

  @override
  String get userApps => 'Cài đặt';

  @override
  String get systemApp => 'Ứng dụng hệ thống';

  @override
  String get userApp => 'Ứng dụng người dùng cài đặt';

  @override
  String get accessDenied => 'Truy cập bị từ chối';

  @override
  String get superuserNotGranted => 'Chưa được cấp quyền siêu người dùng';

  @override
  String get superuserRevertedNormal => 'Chưa được cấp quyền siêu người dùng — đã chuyển về Bình thường';

  @override
  String get wrongPassword => 'Sai mật khẩu';

  @override
  String get cancelUnzip => 'Đã hủy giải nén';

  @override
  String get cancelZip => 'Đã hủy nén';

  @override
  String get cancelPaste => 'Đã hủy dán';

  @override
  String get cancelDuplicate => 'Đã hủy nhân đôi';

  @override
  String get cancelOperation => 'Đã hủy thao tác';

  @override
  String get rollingBack => 'Đang hoàn tác...';

  @override
  String get zipping => 'Đang nén...';

  @override
  String get deleting => 'Đang xóa...';

  @override
  String get pasting => 'Đang dán...';

  @override
  String get duplicating => 'Đang nhân đôi...';

  @override
  String get moving => 'Đang di chuyển...';

  @override
  String moveProgress(String name, int percent) {
    return 'Di chuyển: $name ($percent%)';
  }

  @override
  String pasteProgress(String name, int percent) {
    return 'Dán: $name ($percent%)';
  }

  @override
  String duplicateProgress(String name, int percent) {
    return 'Nhân đôi: $name ($percent%)';
  }

  @override
  String deleteProgress(String name, int percent) {
    return 'Đang xóa: $name ($percent%)';
  }

  @override
  String zipProgress(String name, int percent) {
    return 'Nén: $name ($percent%)';
  }

  @override
  String unzipProgress(String name, int percent) {
    return 'Giải nén: $name ($percent%)';
  }

  @override
  String openFileProgress(String name) {
    return 'Đang mở $name...';
  }

  @override
  String get ready => 'Sẵn sàng';

  @override
  String get notSaved => 'Chưa lưu';

  @override
  String get saved => 'Đã lưu';

  @override
  String get deleteStopped => 'Đã dừng xóa';

  @override
  String get exitAppTitle => 'Thoát ứng dụng';

  @override
  String get exitAppBody => 'Bạn có chắc muốn thoát Cope X Studio?';

  @override
  String get exit => 'Thoát';

  @override
  String get webServer => 'Web Server';

  @override
  String get shareViaWifi => 'Chia sẻ file qua Wi‑Fi. Thiết bị khác mở địa chỉ hoặc quét QR để truy cập.';

  @override
  String get sharedFolder => 'Thư mục chia sẻ';

  @override
  String get pickFolder => 'Chọn thư mục';

  @override
  String get entireStorage => 'Toàn bộ bộ nhớ thiết bị';

  @override
  String get useAppLockPassword => 'Dùng mật khẩu khóa app';

  @override
  String get httpBasicAuthHint => 'HTTP Basic Auth — tên đăng nhập tùy ý';

  @override
  String get webServerPassword => 'Mật khẩu Web Server';

  @override
  String get webServerPasswordSet => 'Đã đặt — chạm để đổi';

  @override
  String get webServerPasswordUnset => 'Chưa đặt — ai trong mạng đều truy cập được';

  @override
  String serverRunning(int port) {
    return 'Đang chạy — port $port';
  }

  @override
  String get startServer => 'Bật server';

  @override
  String onlyFolder(String path) {
    return 'Chỉ: $path';
  }

  @override
  String get addressCopied => 'Đã sao chép địa chỉ';

  @override
  String get changeWebServerPassword => 'Đổi mật khẩu Web Server';

  @override
  String get setWebServerPassword => 'Đặt mật khẩu Web Server';

  @override
  String get removeWebServerPassword => 'Xóa mật khẩu';

  @override
  String get consoleLog => 'Console Log';

  @override
  String get clearLog => 'Xóa log';

  @override
  String get noLogsYet => 'Chưa có log';

  @override
  String get newBrowserTab => 'Tab duyệt file mới';

  @override
  String get pickSharedFolder => 'Chọn thư mục chia sẻ';

  @override
  String get cannotReadFolder => 'Không thể đọc thư mục';

  @override
  String get noSubfolders => 'Không có thư mục con';

  @override
  String get selectThisFolder => 'Chọn thư mục này';

  @override
  String get enterPasswordUnlock => 'Nhập mật khẩu để mở khóa';

  @override
  String get wrongPasswordLock => 'Mật khẩu không đúng';

  @override
  String get biometrics => 'Sinh trắc học';

  @override
  String get loading => 'Đang tải...';

  @override
  String get loadingFile => 'Đang tải tệp tin...';

  @override
  String get cannotLoadFile => 'Không thể tải tệp tin';

  @override
  String get formatNotSupported => 'Định dạng không được hỗ trợ';

  @override
  String get previous => 'Trước';

  @override
  String get next => 'Tiếp theo';

  @override
  String get rewind10s => 'Tua lại 10s';

  @override
  String get forward10s => 'Tua tới 10s';

  @override
  String get playlist => 'Danh sách';

  @override
  String get nowPlaying => 'Đang phát';

  @override
  String get exitFullscreen => 'Thoát toàn màn hình';

  @override
  String get rotatePortrait => 'Xoay dọc';

  @override
  String get rotateLandscape => 'Xoay ngang';

  @override
  String get undo => 'Hoàn tác';

  @override
  String get redo => 'Làm lại';

  @override
  String get findReplace => 'Tìm kiếm & Thay thế';

  @override
  String get hideLineNumbers => 'Ẩn số dòng';

  @override
  String get showLineNumbersToggle => 'Hiện số dòng';

  @override
  String get disableWordWrap => 'Tắt xuống dòng tự động';

  @override
  String get enableWordWrap => 'Bật xuống dòng tự động';

  @override
  String get decreaseFontSize => 'Giảm cỡ chữ';

  @override
  String get increaseFontSize => 'Tăng cỡ chữ';

  @override
  String get notFound => 'Không tìm thấy';

  @override
  String get findHint => 'Tìm kiếm...';

  @override
  String get replaceHint => 'Thay thế...';

  @override
  String get replace => 'Thay thế';

  @override
  String get replaceAll => 'Tất cả';

  @override
  String get backToBrowser => 'Quay lại duyệt file';

  @override
  String get createBrowserTab => 'Tạo tab duyệt file';

  @override
  String get propertyDetails => 'Chi tiết';

  @override
  String get loadingProperties => 'Đang tải thông tin...';

  @override
  String cannotReadProperties(String error) {
    return 'Không thể đọc thông tin: $error';
  }

  @override
  String get propertyName => 'Tên';

  @override
  String get propertyType => 'Loại';

  @override
  String get propertyLocation => 'Vị trí';

  @override
  String get propertyItemCount => 'Số mục';

  @override
  String get propertySize => 'Kích thước';

  @override
  String get propertyFiles => 'Tệp';

  @override
  String get propertySubfolders => 'Thư mục con';

  @override
  String get propertyModified => 'Sửa đổi';

  @override
  String get propertyAccessed => 'Truy cập';

  @override
  String get propertyNotes => 'Ghi chú';

  @override
  String get propertyResolution => 'Độ phân giải';

  @override
  String get propertyDuration => 'Thời lượng';

  @override
  String get propertyCamera => 'Máy ảnh';

  @override
  String get propertyCapturedAt => 'Chụp lúc';

  @override
  String get propertyDateModified => 'Ngày sửa';

  @override
  String get propertyOrientation => 'Hướng';

  @override
  String get propertyTitle => 'Tiêu đề';

  @override
  String get propertyArtist => 'Nghệ sĩ';

  @override
  String get propertyGenre => 'Thể loại';

  @override
  String get propertyYear => 'Năm';

  @override
  String get folderType => 'Thư mục';

  @override
  String get fileType => 'Tệp';

  @override
  String fileTypeExt(String ext) {
    return 'Tệp $ext';
  }

  @override
  String get themeDark => 'Tối';

  @override
  String get themeLight => 'Sáng';

  @override
  String get themeSystem => 'Theo hệ thống';

  @override
  String get rootAccessDisabled => 'Vô hiệu hóa';

  @override
  String get rootAccessNormal => 'Bình thường';

  @override
  String get rootAccessSuperuser => 'Siêu người dùng';

  @override
  String get rootAccessSuperuserWritable => 'Siêu người dùng + mount writable';

  @override
  String get rootAccessDisabledDesc => 'Thư mục gốc không được hiển thị';

  @override
  String get rootAccessNormalDesc => 'Hiển thị thư mục gốc theo cách bình thường, hoạt động trên mọi thiết bị';

  @override
  String get rootAccessSuperuserDesc => 'Truy cập thông qua sử dụng siêu người dùng, hoạt động trên các thiết bị toàn quyền điều khiển';

  @override
  String get rootAccessSuperuserWritableDesc => 'Chế độ siêu người dùng, cho phép thay đổi trong các thư mục chỉ được đọc';

  @override
  String get openWithDone => 'Đã mở trình cài đặt';

  @override
  String get openWithNoApp => 'Không tìm thấy trình cài đặt gói';

  @override
  String get openWithFileNotFound => 'File không tồn tại';

  @override
  String get openWithPermissionDenied => 'Không có quyền mở file';

  @override
  String openWithError(String message) {
    return 'Lỗi: $message';
  }

  @override
  String get operationCancelled => 'Đã hủy thao tác';

  @override
  String storageFreeSlash(String free, String total) {
    return 'Trống $free/$total';
  }

  @override
  String get treeLoading => 'Đang tải cây thư mục...';

  @override
  String get webServerRunningNotification => 'Web Server đang chạy';

  @override
  String get webServerNotificationChannel => 'Thông báo khi Web Server đang chạy';

  @override
  String get untitled => 'Untitled';

  @override
  String get video => 'Video';

  @override
  String get pdf => 'PDF';

  @override
  String get online => 'Online';

  @override
  String get output => 'OUTPUT';

  @override
  String get unzipping => 'Đang giải nén...';

  @override
  String get passwordRequired => 'Vui lòng nhập mật khẩu';

  @override
  String get wrongPasswordOrCorrupt => 'Sai mật khẩu hoặc file bị lỗi';

  @override
  String get webDisk => 'Ổ đĩa';

  @override
  String get webGoUp => 'Lên';

  @override
  String get webUpload => 'Tải lên';

  @override
  String get webDownload => 'Tải xuống';

  @override
  String get webActions => 'Thao tác';

  @override
  String get webRoot => 'Gốc';

  @override
  String get webReady => 'Sẵn sàng';

  @override
  String get webEditFile => 'Sửa file';

  @override
  String get webViewFile => 'Xem';

  @override
  String get webNewFolderName => 'Tên thư mục mới';

  @override
  String get webNewFileName => 'Tên file mới';

  @override
  String get webCreate => 'Tạo';

  @override
  String get webEdit => 'Chỉnh sửa';

  @override
  String get webClearLogs => 'Xóa logs';

  @override
  String get webClosePanel => 'Đóng panel';

  @override
  String get webItems => 'mục';

  @override
  String get webLoading => 'Đang tải...';

  @override
  String get webError => 'Lỗi';

  @override
  String get webUploading => 'Đang tải lên...';

  @override
  String get webUploadSuccess => 'Đã tải lên';

  @override
  String webUploadSuccessCount(int count) {
    return 'Đã tải lên $count file thành công';
  }

  @override
  String get webUploadError => 'Lỗi upload';

  @override
  String get webNoSelectionDownload => 'Chưa chọn mục để tải xuống';

  @override
  String get webNoFilesDownload => 'Không có file nào được chọn để tải xuống';

  @override
  String get webDownloading => 'Đang tải xuống';

  @override
  String get webZipAndDownload => 'Phát hiện thư mục hoặc tải trên 5 mục, tiến hành nén ZIP...';

  @override
  String get webZipSuccessDownload => 'Đã nén thành công';

  @override
  String get webZipError => 'Lỗi nén zip';

  @override
  String get webSelectedAll => 'Đã chọn tất cả';

  @override
  String webSelectedAllCount(int count) {
    return 'Đã chọn tất cả $count mục';
  }

  @override
  String get webDeselectedAll => 'Đã bỏ chọn tất cả';

  @override
  String get webSavedSuccess => 'Đã lưu thành công';

  @override
  String get webSelectOneRename => 'Chọn 1 mục để đổi tên';

  @override
  String get webNoSelection => 'Chưa chọn mục';

  @override
  String webDeleteConfirm(int count) {
    return 'Xóa $count mục?';
  }

  @override
  String get webZipSuccess => 'Đã nén thành công';

  @override
  String webZipSuccessDownloading(String name) {
    return 'Đã nén thành công: $name. Đang tải xuống...';
  }

  @override
  String get webUnzipSuccess => 'Đã giải nén thành công';

  @override
  String get webGridView => 'Lưới';

  @override
  String get webListView => 'Danh sách';

  @override
  String logUnlockZip(String name) {
    return 'Đã mở khóa ZIP: $name';
  }

  @override
  String logUnlockError(String error) {
    return 'Lỗi mở khóa: $error';
  }

  @override
  String get logEnableManageStorage => 'Bật quyền Truy cập tất cả file trong Cài đặt';

  @override
  String get logGrantedAllFilesAccess => 'Đã cấp quyền truy cập tất cả file';

  @override
  String get logEnableManageAllFiles => 'Bật Cho phép truy cập để quản lý tất cả tệp trong Cài đặt';

  @override
  String logNewTab(String name) {
    return 'Tab mới: $name';
  }

  @override
  String logFileLocation(String path) {
    return 'Vị trí: $path';
  }

  @override
  String logViewZip(String name) {
    return 'Xem ZIP: $name';
  }

  @override
  String logRecentAdded(int count) {
    return 'Đã thêm $count tập tin gần đây';
  }

  @override
  String logRecentScanned(int count) {
    return 'Đã quét $count tập tin gần đây';
  }

  @override
  String logRecentScanError(String error) {
    return 'Lỗi quét tập tin gần đây: $error';
  }

  @override
  String logAppsAdded(int count, String type) {
    return 'Đã thêm $count ứng dụng ($type)';
  }

  @override
  String logAppsLoaded(int count) {
    return 'Đã tải $count ứng dụng';
  }

  @override
  String logAppsLoadError(String error) {
    return 'Lỗi tải ứng dụng: $error';
  }

  @override
  String get logAppsTypeSystem => 'hệ thống';

  @override
  String get logAppsTypeUser => 'người dùng';

  @override
  String logReadItemsRoot(int count) {
    return 'Đã đọc $count mục tại Root';
  }

  @override
  String logReadItemsAt(int count, String location) {
    return 'Đã đọc $count mục tại $location';
  }

  @override
  String logReadError(String location, String error) {
    return 'Lỗi đọc $location: $error';
  }

  @override
  String get logOpenAppInfo => 'Mở thông tin ứng dụng';

  @override
  String logOpenAppInfoError(String error) {
    return 'Lỗi mở thông tin ứng dụng: $error';
  }

  @override
  String logApkCopied(String name) {
    return 'Đã sao chép APK: $name';
  }

  @override
  String logApkCopyError(String error) {
    return 'Lỗi sao chép APK: $error';
  }

  @override
  String logApkShared(String name) {
    return 'Chia sẻ APK: $name';
  }

  @override
  String logApkShareError(String error) {
    return 'Lỗi chia sẻ APK: $error';
  }

  @override
  String logPlayStoreError(String error) {
    return 'Lỗi mở Play Store: $error';
  }

  @override
  String logApkBackup(String path) {
    return 'Đã backup APK → $path';
  }

  @override
  String logApkBackupError(String error) {
    return 'Lỗi backup APK: $error';
  }

  @override
  String logUninstall(String name) {
    return 'Gỡ cài đặt: $name';
  }

  @override
  String logUninstallError(String error) {
    return 'Lỗi gỡ cài đặt: $error';
  }

  @override
  String logLaunchApp(String package) {
    return 'Khởi chạy ứng dụng: $package';
  }

  @override
  String logOpenAppError(String error) {
    return 'Lỗi mở ứng dụng: $error';
  }

  @override
  String logHomeLoadError(String error) {
    return 'Lỗi tải màn hình chính: $error';
  }

  @override
  String logFtpError(String error) {
    return 'Lỗi FTP: $error';
  }

  @override
  String logZipReadError(String error) {
    return 'Lỗi đọc ZIP: $error';
  }

  @override
  String logFileOpened(String name) {
    return 'Đã mở $name';
  }

  @override
  String logFormatNotSupportedOpen(String format) {
    return 'Định dạng $format chưa được hỗ trợ.';
  }

  @override
  String logFtpFileLoadError(String error) {
    return 'Lỗi tải tệp FTP: $error';
  }

  @override
  String logCreateFile(String name) {
    return 'Tạo file mới: $name';
  }

  @override
  String logCreateFolder(String name) {
    return 'Tạo thư mục mới: $name';
  }

  @override
  String logCopiedItems(int count) {
    return 'Đã copy $count mục';
  }

  @override
  String logCutItems(int count) {
    return 'Đã cut $count mục';
  }

  @override
  String get logCannotPasteInZip => 'Không thể paste vào bên trong ZIP';

  @override
  String get logPasteSuccess => 'Đã dán thành công';

  @override
  String logPasteError(String error) {
    return 'Lỗi paste: $error';
  }

  @override
  String logDuplicateSuccess(int count) {
    return 'Đã nhân đôi $count mục';
  }

  @override
  String logDuplicateError(String error) {
    return 'Lỗi nhân đôi: $error';
  }

  @override
  String get logDeletePartialNotice => 'Các mục đã xóa không thể khôi phục. Phần còn lại chưa bị xóa.';

  @override
  String logMovedToTrash(int count) {
    return 'Đã chuyển $count mục vào thùng rác';
  }

  @override
  String logDeletedItems(int count) {
    return 'Đã xóa $count mục';
  }

  @override
  String logDeleteError(String error) {
    return 'Lỗi xóa: $error';
  }

  @override
  String logRenamedTo(String name) {
    return 'Đã đổi tên thành $name';
  }

  @override
  String logZippedTo(String name) {
    return 'Đã nén thành $name';
  }

  @override
  String logUnzipTo(String folder) {
    return 'Đã giải nén vào $folder';
  }

  @override
  String logUnzipError(String error) {
    return 'Lỗi giải nén: $error';
  }

  @override
  String get logApkNotFound => 'File APK không tồn tại';

  @override
  String logInstallApkError(String error) {
    return 'Lỗi cài APK: $error';
  }

  @override
  String get logOpeningFromZip => 'Đang mở file từ ZIP...';

  @override
  String get logPrepareShareFromZip => 'Đang chuẩn bị chia sẻ file từ ZIP...';

  @override
  String logShareFileError(String error) {
    return 'Lỗi chia sẻ file: $error';
  }

  @override
  String logFormatNotSupportedDirect(String format) {
    return 'Định dạng $format chưa được hỗ trợ giải nén trực tiếp.';
  }

  @override
  String logFileSaved(String name) {
    return 'Đã lưu $name';
  }

  @override
  String logSaveError(String error) {
    return 'Lỗi lưu: $error';
  }

  @override
  String logWebServerStarted(String auth, String url, String scope) {
    return 'Web server$auth: $url$scope';
  }

  @override
  String get logWebServerAuthWith => ' (có mật khẩu)';

  @override
  String logWebServerScopeFolder(String path) {
    return ' — thư mục: $path';
  }

  @override
  String get logWebServerScopeAll => ' — toàn bộ bộ nhớ';

  @override
  String logWebServerStartError(String error) {
    return 'Lỗi bật web server: $error';
  }

  @override
  String get logWebServerStopped => 'Đã tắt web server';

  @override
  String logZipError(String error) {
    return 'Lỗi nén ZIP: $error';
  }

  @override
  String get errCannotReadZipList => 'Không đọc được danh sách file trong ZIP';

  @override
  String errZipTooLargeVerifyPassword(String sizeMb) {
    return 'ZIP quá lớn ($sizeMb MB). Không thể xác minh mật khẩu trong bộ nhớ.';
  }

  @override
  String errZipAesTooLarge(String sizeMb, String limitMb) {
    return 'ZIP mã hóa AES quá lớn ($sizeMb MB). Giới hạn $limitMb MB.';
  }

  @override
  String errZipTooLargeNeedUnzip(String sizeMb) {
    return 'ZIP quá lớn ($sizeMb MB). Cần lệnh unzip/7z trên thiết bị.';
  }

  @override
  String get errFlutterArchiveUnavailable => 'flutter_archive không khả dụng trên nền tảng này';

  @override
  String get errCannotExtractZipEntry => 'Không trích xuất được mục ZIP';

  @override
  String get errCannotExtractTar => 'Không thể giải nén TAR';

  @override
  String errDataTooLargeCompress(String sizeMb) {
    return 'Dữ liệu quá lớn ($sizeMb MB). Không thể nén trong bộ nhớ.';
  }

  @override
  String get errMultiFolderZipNoCommand => 'Không thể nén nhiều thư mục — thiếu lệnh zip trên thiết bị';

  @override
  String get errCannotCreateZip => 'Không thể tạo file ZIP';

  @override
  String get errParentDirNotFound => 'Thư mục cha không tồn tại';

  @override
  String get errCannotWriteDestDir => 'Không thể ghi vào thư mục đích';

  @override
  String errZipTooLargeExtract(String sizeMb) {
    return 'File ZIP quá lớn ($sizeMb MB). Cần giải nén native hoặc lệnh unzip.';
  }

  @override
  String get errZipTooLargeSingleEntry => 'File ZIP quá lớn để trích xuất mục đơn lẻ trong RAM';

  @override
  String get errZipEntryNotFound => 'Không tìm thấy mục trong ZIP';

  @override
  String get errFileNotExists => 'File không tồn tại';

  @override
  String get errInvalidZip => 'File ZIP không hợp lệ';

  @override
  String get errZipEocdNotFound => 'Không tìm thấy End of Central Directory';

  @override
  String get errZipCdCorrupt => 'Central Directory ZIP bị hỏng';

  @override
  String errZipCdTooLarge(String sizeMb) {
    return 'Central Directory quá lớn ($sizeMb MB)';
  }

  @override
  String get errZipCdIncomplete => 'Không đọc đủ Central Directory';

  @override
  String get errZip64LocatorInvalid => 'ZIP64 locator không hợp lệ';

  @override
  String get errZip64EocdInvalid => 'ZIP64 EOCD signature không hợp lệ';

  @override
  String get errZip64EocdOutOfFile => 'ZIP64 EOCD nằm ngoài file';

  @override
  String get errDirectoryNotExists => 'Thư mục không tồn tại';

  @override
  String errCannotAccessPath(String path, String message) {
    return 'Không thể truy cập $path: $message';
  }

  @override
  String get errAlreadyExists => 'Đã tồn tại';

  @override
  String get errShellListingAndroidOnly => 'Shell listing chỉ hỗ trợ Android';

  @override
  String get errSuperuserAndroidOnly => 'Chế độ siêu người dùng chỉ hỗ trợ Android';

  @override
  String get errCannotCheckSuperuser => 'Không thể kiểm tra quyền siêu người dùng';

  @override
  String get errSuperuserCheckTimeout => 'Hết thời gian kiểm tra quyền siêu người dùng. Thiết bị có thể chưa root hoặc chưa cấp quyền.';

  @override
  String get errInstallApkAndroidOnly => 'Cài APK chỉ hỗ trợ Android';

  @override
  String get errApkNotFound => 'Không tìm thấy APK';

  @override
  String get errApkBackupFailed => 'Backup thất bại';

  @override
  String get errNoWebServerPassword => 'Chưa có mật khẩu Web Server';

  @override
  String get errNoPassword => 'Chưa có mật khẩu';

  @override
  String get errCurrentPasswordWrong => 'Mật khẩu hiện tại không đúng';

  @override
  String get errBiometricUnlockReason => 'Mở khóa Cope X Studio';

  @override
  String get errCannotTestPasswordOnPlatform => 'Không thể kiểm tra mật khẩu trên nền tảng này';

  @override
  String get errShellUnsupportedZipEncryption => 'Shell không hỗ trợ định dạng mã hóa ZIP này';

  @override
  String get errCannotRunUnzip => 'Không thể chạy lệnh unzip';

  @override
  String get err7zNotFound => 'Không tìm thấy lệnh 7z';

  @override
  String get errEmptyZipSources => 'Danh sách nguồn nén trống';

  @override
  String get errCannotRunZip => 'Không thể chạy lệnh zip';

  @override
  String get errPasswordNeeded => 'Cần mật khẩu';

  @override
  String get apiPasswordRequired => 'Cần mật khẩu';

  @override
  String get apiWrongPassword => 'Mật khẩu sai';

  @override
  String get apiCannotListFolder => 'Không thể tải thư mục';

  @override
  String get apiFileNotFound => 'Không tìm thấy file';

  @override
  String get apiCannotFolderThumbnail => 'Không thể lấy thumbnail của thư mục';

  @override
  String get apiCannotReadFolder => 'Không thể đọc thư mục';

  @override
  String get apiFileTooLargeEdit => 'File quá lớn để chỉnh sửa (>2MB)';

  @override
  String get apiMissingFolderName => 'Thiếu tên thư mục';

  @override
  String get apiMissingFileName => 'Thiếu tên file';

  @override
  String get apiMissingNewName => 'Thiếu tên mới';

  @override
  String get apiNothingToDelete => 'Không có mục để xóa';

  @override
  String get apiCannotWriteFolder => 'Không thể ghi thư mục';

  @override
  String get apiNothingToZip => 'Không có mục để nén';

  @override
  String get apiNotZipFile => 'Không phải file ZIP';

  @override
  String get apiInvalidDestFolder => 'Thư mục đích không hợp lệ';

  @override
  String get apiMissingFileNameParam => 'Thiếu tên file (tham số name)';

  @override
  String get welcomeTitle => 'Chào mừng đến Cope X Studio';

  @override
  String get welcomeSubtitle => 'Duyệt file, chỉnh sửa code và quản lý nén — tất cả trong một ứng dụng.';

  @override
  String get welcomeLanguage => 'Ngôn ngữ';

  @override
  String get welcomeTheme => 'Giao diện';

  @override
  String get welcomeNext => 'Tiếp theo';

  @override
  String get welcomeBack => 'Quay lại';

  @override
  String get welcomeGetStarted => 'Bắt đầu';

  @override
  String get welcomePermissionTitle => 'Quyền truy cập bộ nhớ';

  @override
  String get welcomePermissionBody => 'Cấp quyền truy cập tất cả file để Cope X Studio có thể duyệt và quản lý file trên thiết bị.';

  @override
  String get welcomeGrantPermission => 'Cấp quyền';

  @override
  String get welcomeSkipPermission => 'Bỏ qua';

  @override
  String get welcomePermissionGranted => 'Đã cấp quyền';

  @override
  String get welcomePermissionNotNeeded => 'Không cần cấp thêm quyền trên thiết bị này.';

  @override
  String get welcomePermissionsTitle => 'Quyền truy cập';

  @override
  String get welcomePermissionsSubtitle => 'Cope X Studio cần một vài quyền để hoạt động đầy đủ.';

  @override
  String get welcomeNotificationTitle => 'Thông báo';

  @override
  String get welcomeNotificationBody => 'Hiển thị trạng thái Web Server, phát media và tác vụ nền.';

  @override
  String get welcomeGrantNotification => 'Cho phép thông báo';

  @override
  String get welcomeNotificationGranted => 'Đã cho phép thông báo';

  @override
  String get welcomeStorageRequiredHint => 'Hãy cấp quyền truy cập bộ nhớ để tiếp tục.';

  @override
  String welcomeStep(int current, int total) {
    return 'Bước $current/$total';
  }

  @override
  String get welcomeDoneTitle => 'Hoàn tất!';

  @override
  String get welcomeDoneBody => 'Mọi thứ đã sẵn sàng. Bắt đầu khám phá file của bạn.';
}
