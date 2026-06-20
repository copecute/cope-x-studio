import 'package:cope_x_studio/l10n/l10n_scope.dart';
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
  bool isRollingBack = false;
  final List<String> rollbackPaths = [];
  final List<({String src, String dest})> movedPairs = [];

  bool get canCancel =>
      !isRollingBack &&
      (type == TabFileOperation.unzip ||
          type == TabFileOperation.zip ||
          type == TabFileOperation.paste ||
          type == TabFileOperation.duplicate ||
          type == TabFileOperation.delete);

  String get overlayTitle {
    final l = L10nScope.current;
    if (isRollingBack) return l.rollingBack;
    return switch (type) {
      TabFileOperation.unzip => l.unzipping,
      TabFileOperation.zip => l.zipping,
      TabFileOperation.delete => l.deleting,
      TabFileOperation.paste => l.pasting,
      TabFileOperation.duplicate => l.duplicating,
      TabFileOperation.none => '',
    };
  }
}
