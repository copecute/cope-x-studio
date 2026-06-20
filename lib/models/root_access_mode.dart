import 'package:cope_x_studio/l10n/l10n_scope.dart';

enum RootAccessMode {
  disabled,
  normal,
  superuser,
  superuserMountWritable,
}

extension RootAccessModeLabels on RootAccessMode {
  String get label => switch (this) {
        RootAccessMode.disabled => L10nScope.current.rootAccessDisabled,
        RootAccessMode.normal => L10nScope.current.rootAccessNormal,
        RootAccessMode.superuser => L10nScope.current.rootAccessSuperuser,
        RootAccessMode.superuserMountWritable => L10nScope.current.rootAccessSuperuserWritable,
      };

  String get description => switch (this) {
        RootAccessMode.disabled => L10nScope.current.rootAccessDisabledDesc,
        RootAccessMode.normal => L10nScope.current.rootAccessNormalDesc,
        RootAccessMode.superuser => L10nScope.current.rootAccessSuperuserDesc,
        RootAccessMode.superuserMountWritable => L10nScope.current.rootAccessSuperuserWritableDesc,
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
