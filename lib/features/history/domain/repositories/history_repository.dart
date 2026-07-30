import '../models/counter_history_entry.dart';
import '../models/history_filter.dart';

class HistoryPage {
  const HistoryPage({
    required this.entries,
    required this.nextCursor,
    required this.hasMore,
  });

  final List<CounterHistoryEntry> entries;
  final String? nextCursor;
  final bool hasMore;
}

abstract interface class HistoryRepository {
  int get revision;

  Future<void> append(CounterHistoryEntry entry);

  Future<List<CounterHistoryEntry>> fetchAll();

  Future<HistoryPage> fetchPage({
    required HistoryDateRange range,
    required String searchTerm,
    required int limit,
    String? cursor,
  });

  Future<void> migrateLegacySnapshot(Object? counterSnapshot);
}
