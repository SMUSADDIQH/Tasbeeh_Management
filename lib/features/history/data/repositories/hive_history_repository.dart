import 'package:hive/hive.dart';

import '../../domain/models/counter_history_entry.dart';
import '../../domain/models/history_filter.dart';
import '../../domain/repositories/history_repository.dart';

class HiveHistoryRepository implements HistoryRepository {
  HiveHistoryRepository(this._historyBox, this._counterBox);

  static const _counterKey = 'counter';

  final LazyBox<dynamic> _historyBox;
  final Box<dynamic> _counterBox;
  int _keySequence = 0;
  List<String>? _keyCache;

  @override
  Future<void> append(CounterHistoryEntry entry) {
    final key =
        '${entry.timestamp.microsecondsSinceEpoch}_'
        '${_historyBox.length}_${_keySequence++}';
    _keyCache = null;
    return _historyBox.put(key, entry.toMap());
  }

  @override
  Future<HistoryPage> fetchPage({
    required HistoryDateRange range,
    required String searchTerm,
    required int limit,
    String? cursor,
  }) async {
    final keys = _sortedKeys();
    var index = cursor == null ? 0 : keys.indexOf(cursor) + 1;
    if (index < 0) {
      index = 0;
    }

    final normalizedSearch = searchTerm.trim().toLowerCase();
    final entries = <CounterHistoryEntry>[];
    String? lastScannedKey;

    while (index < keys.length && entries.length < limit) {
      final key = keys[index++];
      lastScannedKey = key;
      final timestamp = _timestampFromKey(key);
      if (timestamp == null || !range.contains(timestamp)) {
        continue;
      }

      final entry = CounterHistoryEntry.tryFromMap(await _historyBox.get(key));
      if (entry == null || !_matchesSearch(entry, normalizedSearch)) {
        continue;
      }

      entries.add(entry);
    }

    return HistoryPage(
      entries: entries,
      nextCursor: lastScannedKey,
      hasMore: index < keys.length,
    );
  }

  @override
  Future<void> migrateLegacySnapshot(Object? counterSnapshot) async {
    if (counterSnapshot is! Map<dynamic, dynamic>) {
      return;
    }

    final legacyHistory = counterSnapshot['history'];
    if (legacyHistory is List<dynamic> && _historyBox.isEmpty) {
      for (final value in legacyHistory) {
        final entry = CounterHistoryEntry.tryFromMap(value);
        if (entry != null) {
          await append(entry);
        }
      }
    }

    if (counterSnapshot.containsKey('history')) {
      final migratedSnapshot = Map<dynamic, dynamic>.from(counterSnapshot)
        ..remove('history');
      await _counterBox.put(_counterKey, migratedSnapshot);
    }
  }

  List<String> _sortedKeys() {
    return _keyCache ??= (_historyBox.keys.whereType<String>().toList()
      ..sort((first, second) => second.compareTo(first)));
  }

  DateTime? _timestampFromKey(String key) {
    final separator = key.indexOf('_');
    final value = separator == -1 ? key : key.substring(0, separator);
    final microseconds = int.tryParse(value);
    return microseconds == null
        ? null
        : DateTime.fromMicrosecondsSinceEpoch(microseconds);
  }

  bool _matchesSearch(CounterHistoryEntry entry, String normalizedSearch) {
    if (normalizedSearch.isEmpty) {
      return true;
    }

    final searchableText = [
      entry.action.name,
      _actionLabel(entry.action),
      '${entry.previousCount}',
      '${entry.newCount}',
      '${entry.target}',
    ].join(' ').toLowerCase();
    return searchableText.contains(normalizedSearch);
  }

  String _actionLabel(CounterHistoryAction action) {
    return switch (action) {
      CounterHistoryAction.increment => 'increment',
      CounterHistoryAction.undo => 'undo',
      CounterHistoryAction.reset => 'reset',
      CounterHistoryAction.targetChanged => 'target changed',
      CounterHistoryAction.dailyRollover => 'daily rollover',
    };
  }
}
