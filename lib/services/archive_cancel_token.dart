import 'package:cope_x_studio/l10n/l10n_scope.dart';

class ArchiveCancelToken {
  bool _cancelled = false;
  bool get isCancelled => _cancelled;
  void cancel() => _cancelled = true;
}

class ArchiveCancelledException implements Exception {
  const ArchiveCancelledException();
  @override
  String toString() => L10nScope.current.operationCancelled;
}
