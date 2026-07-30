import 'package:flutter_test/flutter_test.dart';
import 'package:tasbeeh_tracker/features/history/domain/models/history_filter.dart';
import 'package:tasbeeh_tracker/features/history/presentation/providers/history_provider.dart';

import '../support/fakes.dart';

void main() {
  test('loads, groups, searches, and filters history', () async {
    final repository = FakeHistoryRepository()
      ..entries.addAll([
        historyEntry(timestamp: DateTime.now(), newCount: 2, todayCount: 2),
        historyEntry(
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          newCount: 1,
        ),
      ]);
    final notifier = HistoryNotifier(repository);

    await notifier.load();
    expect(notifier.state.items.whereType<HistoryDateHeaderItem>().length, 2);
    expect(notifier.state.items.whereType<HistoryEventItem>().length, 2);

    notifier.setFilter(HistoryFilter.today);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(notifier.state.filter, HistoryFilter.today);

    notifier.search('increment');
    await Future<void>.delayed(const Duration(milliseconds: 350));
    expect(notifier.state.errorMessage, isNull);

    notifier.dispose();
  });
}
