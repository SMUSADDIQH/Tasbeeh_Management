enum HistoryFilter { today, thisWeek, thisMonth, allTime }

class HistoryDateRange {
  const HistoryDateRange({this.start, this.end});

  final DateTime? start;
  final DateTime? end;

  bool contains(DateTime timestamp) {
    final local = timestamp.toLocal();
    final afterStart = start == null || !local.isBefore(start!);
    final beforeEnd = end == null || local.isBefore(end!);
    return afterStart && beforeEnd;
  }
}

extension HistoryFilterRange on HistoryFilter {
  HistoryDateRange rangeAt(DateTime now) {
    final local = now.toLocal();
    final today = DateTime(local.year, local.month, local.day);
    final tomorrow = DateTime(local.year, local.month, local.day + 1);

    return switch (this) {
      HistoryFilter.today => HistoryDateRange(start: today, end: tomorrow),
      HistoryFilter.thisWeek => HistoryDateRange(
        start: today.subtract(Duration(days: local.weekday - 1)),
        end: tomorrow,
      ),
      HistoryFilter.thisMonth => HistoryDateRange(
        start: DateTime(local.year, local.month),
        end: DateTime(local.year, local.month + 1),
      ),
      HistoryFilter.allTime => const HistoryDateRange(),
    };
  }
}
