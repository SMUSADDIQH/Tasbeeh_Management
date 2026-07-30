import 'package:tasbeeh_tracker/features/history/domain/models/counter_history_entry.dart';
import 'package:tasbeeh_tracker/features/history/domain/models/history_filter.dart';
import 'package:tasbeeh_tracker/features/history/domain/repositories/history_repository.dart';
import 'package:tasbeeh_tracker/features/home/data/repositories/counter_repository.dart';
import 'package:tasbeeh_tracker/features/home/domain/models/tasbeeh_counter_model.dart';

class FakeCounterRepository implements CounterRepository {
  FakeCounterRepository([this.value]);

  TasbeehCounterModel? value;

  @override
  TasbeehCounterModel? load() => value;

  @override
  Future<void> save(TasbeehCounterModel counter) async {
    value = counter;
  }
}

class FakeHistoryRepository implements HistoryRepository {
  final List<CounterHistoryEntry> entries = [];
  int _revision = 0;

  @override
  int get revision => _revision;

  @override
  Future<void> append(CounterHistoryEntry entry) async {
    entries.add(entry);
    _revision++;
  }

  @override
  Future<void> clear() async {
    entries.clear();
    _revision++;
  }

  @override
  Future<List<CounterHistoryEntry>> fetchAll() async {
    return List.unmodifiable(entries);
  }

  @override
  Future<HistoryPage> fetchPage({
    required HistoryDateRange range,
    required String searchTerm,
    required int limit,
    String? cursor,
  }) async {
    final sorted = entries.reversed
        .where((entry) => range.contains(entry.timestamp))
        .where(
          (entry) =>
              searchTerm.isEmpty ||
              entry.action.name.toLowerCase().contains(
                searchTerm.toLowerCase(),
              ),
        )
        .toList();
    final start = cursor == null ? 0 : int.parse(cursor);
    final end = (start + limit).clamp(0, sorted.length);
    return HistoryPage(
      entries: sorted.sublist(start, end),
      nextCursor: '$end',
      hasMore: end < sorted.length,
    );
  }

  @override
  Future<void> migrateLegacySnapshot(Object? counterSnapshot) async {}

  @override
  Future<void> replaceAll(List<CounterHistoryEntry> values) async {
    entries
      ..clear()
      ..addAll(values);
    _revision++;
  }
}

CounterHistoryEntry historyEntry({
  required DateTime timestamp,
  CounterHistoryAction action = CounterHistoryAction.increment,
  int previousCount = 0,
  int newCount = 1,
  int target = 100,
  int todayCount = 1,
  int lifetimeCount = 1,
}) {
  return CounterHistoryEntry(
    action: action,
    timestamp: timestamp,
    previousCount: previousCount,
    newCount: newCount,
    target: target,
    todayCount: todayCount,
    lifetimeCount: lifetimeCount,
  );
}
