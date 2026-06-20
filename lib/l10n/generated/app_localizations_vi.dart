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
}
