import 'package:flutter_test/flutter_test.dart';
import 'package:tasbeeh_tracker/features/home/presentation/providers/counter_provider.dart';

import '../support/fakes.dart';

void main() {
  test('increment, undo, target, and reset update and persist state', () async {
    final counterRepository = FakeCounterRepository();
    final historyRepository = FakeHistoryRepository();
    final notifier = CounterNotifier(counterRepository, historyRepository);

    notifier.increment();
    await Future<void>.delayed(Duration.zero);
    expect(notifier.state.currentCount, 1);
    expect(notifier.state.todayCount, 1);
    expect(notifier.state.lifetimeCount, 1);
    expect(historyRepository.entries.single.action.name, 'increment');

    notifier.undo();
    await Future<void>.delayed(Duration.zero);
    expect(notifier.state.currentCount, 0);
    expect(notifier.state.canUndo, isFalse);

    expect(notifier.setCustomTarget('250'), isTrue);
    expect(notifier.state.target, 250);
    expect(notifier.setCustomTarget('0'), isFalse);

    notifier.increment();
    notifier.reset();
    expect(notifier.state.currentCount, 0);
    expect(counterRepository.value?.target, 250);

    notifier.dispose();
  });
}
