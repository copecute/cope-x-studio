import 'package:cope_x_studio/models/tab_file_operation.dart';
import 'package:cope_x_studio/services/archive_cancel_token.dart';

class TabFileOperationState {
  TabFileOperationState({
    required this.type,
    this.progress = 0,
    this.label,
    this.cancelToken,
    this.destDir,
  });

  final TabFileOperation type;
  double progress;
  String? label;
  final ArchiveCancelToken? cancelToken;
  String? destDir;

  bool get canCancel => type == TabFileOperation.unzip;

  String get overlayTitle => switch (type) {
        TabFileOperation.unzip => 'Đang giải nén...',
        TabFileOperation.delete => 'Đang xóa...',
        TabFileOperation.none => '',
      };
}
