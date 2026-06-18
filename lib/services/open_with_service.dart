import 'package:mime/mime.dart';
import 'package:open_filex/open_filex.dart';

class OpenWithService {
  Future<OpenResult> openWithSystem(String filePath) async {
    final mime = lookupMimeType(filePath) ?? '*/*';
    return OpenFilex.open(filePath, type: mime);
  }

  Future<String> openResultMessage(OpenResult result) async {
    return switch (result.type) {
      ResultType.done => 'Đã mở bằng ứng dụng hệ thống',
      ResultType.noAppToOpen => 'Không tìm thấy ứng dụng để mở file này',
      ResultType.fileNotFound => 'File không tồn tại',
      ResultType.permissionDenied => 'Không có quyền mở file',
      ResultType.error => 'Lỗi: ${result.message}',
    };
  }
}
