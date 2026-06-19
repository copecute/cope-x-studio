/// Tiến độ theo số mục đã xử lý / tổng số mục (file + thư mục).
class EntryProgressTracker {
  EntryProgressTracker(this.totalEntries);

  final int totalEntries;
  int _processed = 0;

  double advance([String? _]) {
    _processed++;
    if (totalEntries <= 0) return 1.0;
    return (_processed / totalEntries).clamp(0.0, 1.0);
  }

  int get processed => _processed;
}
