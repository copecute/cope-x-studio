enum RootAccessMode {
  disabled,
  normal,
  superuser,
  superuserMountWritable,
}

extension RootAccessModeLabels on RootAccessMode {
  String get label => switch (this) {
        RootAccessMode.disabled => 'Vô hiệu hóa',
        RootAccessMode.normal => 'Bình thường',
        RootAccessMode.superuser => 'Siêu người dùng',
        RootAccessMode.superuserMountWritable => 'Siêu người dùng + mount writable',
      };

  String get description => switch (this) {
        RootAccessMode.disabled => 'Thư mục gốc không được hiển thị',
        RootAccessMode.normal =>
          'Hiển thị thư mục gốc theo cách bình thường, hoạt động trên mọi thiết bị',
        RootAccessMode.superuser =>
          'Truy cập thông qua sử dụng siêu người dùng, hoạt động trên các thiết bị toàn quyền điều khiển',
        RootAccessMode.superuserMountWritable =>
          'Chế độ siêu người dùng, cho phép thay đổi trong các thư mục chỉ được đọc',
      };

  bool get usesSuperuser =>
      this == RootAccessMode.superuser || this == RootAccessMode.superuserMountWritable;

  bool get mountWritable => this == RootAccessMode.superuserMountWritable;

  String get storageValue => name;

  static RootAccessMode fromStorage(String? value) {
    if (value == null || value.isEmpty) return RootAccessMode.normal;
    for (final mode in RootAccessMode.values) {
      if (mode.storageValue == value) return mode;
    }
    return RootAccessMode.normal;
  }
}

class RootAccessCheckResult {
  const RootAccessCheckResult({
    required this.granted,
    this.message = '',
  });

  final bool granted;
  final String message;

  factory RootAccessCheckResult.fromMap(Map<dynamic, dynamic> map) {
    return RootAccessCheckResult(
      granted: map['granted'] as bool? ?? false,
      message: map['message'] as String? ?? '',
    );
  }
}
