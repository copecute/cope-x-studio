import 'dart:io';

import 'package:cope_x_studio/l10n/l10n_scope.dart';
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
    final l10n = L10nScope.current;
    return switch (result.type) {
      ResultType.done => l10n.openWithDone,
      ResultType.noAppToOpen => l10n.openWithNoApp,
      ResultType.fileNotFound => l10n.openWithFileNotFound,
      ResultType.permissionDenied => l10n.openWithPermissionDenied,
      ResultType.error => l10n.openWithError(result.message),
    };
  }
}
