class ArchiveCancelToken {
  bool _cancelled = false;
  bool get isCancelled => _cancelled;
  void cancel() => _cancelled = true;
}

class ArchiveCancelledException implements Exception {
  const ArchiveCancelledException();
  @override
  String toString() => 'Đã hủy thao tác';
}
