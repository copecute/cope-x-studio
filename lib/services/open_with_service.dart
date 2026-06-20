import 'dart:io';

import 'package:cope_x_studio/services/file_service.dart';
import 'package:cope_x_studio/services/platform_bridge.dart';
import 'package:cope_x_studio/utils/file_type_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mime/mime.dart';
import 'package:open_filex/open_filex.dart';

class OpenWithService {
  OpenWithService({PlatformBridge? platform}) : _platform = platform ?? PlatformBridge();

  final PlatformBridge _platform;

  Future<OpenResult> openWithSystem(String filePath) async {
    if (!kIsWeb && Platform.isAndroid && FileTypeUtils.isApk(filePath)) {
      return _openApkInstaller(filePath);
    }

    final mime = lookupMimeType(filePath) ?? '*/*';
    return OpenFilex.open(filePath, type: mime);
  }

  Future<OpenResult> _openApkInstaller(String filePath) async {
    try {
      await _platform.installApk(filePath);
      return OpenResult(type: ResultType.done);
    } on MissingPluginException {
      return OpenFilex.open(filePath, type: 'application/vnd.android.package-archive');
    } on FileAccessException catch (e) {
      return OpenResult(type: ResultType.error, message: e.message);
    } on PlatformException catch (e) {
      return OpenResult(type: ResultType.error, message: e.message ?? '$e');
    } catch (e) {
      return OpenResult(type: ResultType.error, message: '$e');
    }
  }

  Future<String> openResultMessage(OpenResult result) async {
    return switch (result.type) {
      ResultType.done => 'Đã mở trình cài đặt',
      ResultType.noAppToOpen => 'Không tìm thấy trình cài đặt gói',
      ResultType.fileNotFound => 'File không tồn tại',
      ResultType.permissionDenied => 'Không có quyền mở file',
      ResultType.error => 'Lỗi: ${result.message}',
    };
  }
}
