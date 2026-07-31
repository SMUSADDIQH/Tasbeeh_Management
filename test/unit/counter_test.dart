import 'package:flutter_test/flutter_test.dart';
import 'package:tasbeeh_tracker/features/zikr/domain/zikr_models.dart';
import 'package:tasbeeh_tracker/features/zikr/presentation/zikr_provider.dart';

import '../support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MemoryZikrRepository repository;
  late ZikrNotifier notifier;
  final now = DateTime(2026, 7, 31, 12);

  setUp(() async {
    repository = MemoryZikrRepository();
    notifier = ZikrNotifier(repository, () => now);
    await notifier.refresh();
  });

  ZikrDraft draft({int target = 33}) => ZikrDraft(
    name: 'SubhanAllah',
    target: target,
    category: ZikrCategory.tasbeeh,
    startingCompleted: 0,
    isFavorite: false,
    colorValue: 0xFF146B55,
    iconCodePoint: 0,
    startDate: now,
  );

  test('Live Counter validates target greater than zero', () async {
    final item = await notifier.create(draft(target: 33));
    expect(
      () => notifier.startCounterSession(zikrId: item.id, target: 0),
      throwsArgumentError,
    );
    expect(
      () => notifier.startCounterSession(zikrId: item.id, target: -10),
      throwsArgumentError,
    );
  });

  test('Live Counter increments and persists active session state', () async {
    final item = await notifier.create(draft(target: 33));
    await notifier.startCounterSession(zikrId: item.id, target: 33);

    expect(notifier.state.activeCounterSession?.count, 0);
    expect(notifier.state.activeCounterSession?.remaining, 33);

    await notifier.incrementCounter();
    await notifier.incrementCounter();

    expect(notifier.state.activeCounterSession?.count, 2);
    expect(notifier.state.activeCounterSession?.remaining, 31);

    // Verify persistence in repository
    final stored = repository.loadActiveCounterSession();
    expect(stored?.count, 2);
    expect(stored?.target, 33);
  });

  test(
    'restores active Live Counter session after simulated restart',
    () async {
      final item = await notifier.create(draft(target: 100));
      await notifier.startCounterSession(zikrId: item.id, target: 100);
      await notifier.incrementCounter();

      // Simulate app restart with new notifier reading same repository
      final restartedNotifier = ZikrNotifier(repository, () => now);
      await restartedNotifier.refresh();

      expect(restartedNotifier.state.activeCounterSession, isNotNull);
      expect(restartedNotifier.state.activeCounterSession?.zikrId, item.id);
      expect(restartedNotifier.state.activeCounterSession?.count, 1);
      expect(restartedNotifier.state.activeCounterSession?.target, 100);
    },
  );

  test('Live Counter threshold completion occurs exactly once', () async {
    final item = await notifier.create(draft(target: 3));
    await notifier.startCounterSession(zikrId: item.id, target: 3);

    await notifier.incrementCounter(); // 1
    await notifier.incrementCounter(); // 2
    expect(notifier.state.activeCounterSession?.isCompleted, isFalse);
    expect(notifier.state.sessions, isEmpty);

    await notifier.incrementCounter(); // 3 - Reached threshold!
    expect(notifier.state.activeCounterSession, isNull);
    expect(notifier.state.sessions, hasLength(1));
    expect(notifier.state.sessions.first.amount, 3);
    expect(notifier.state.sessions.first.label, contains('Tasbeeh Counter'));
    expect(notifier.state.zikr.first.completed, 3);

    // Extra increment after completion must be ignored (idempotent)
    await notifier.incrementCounter();
    expect(notifier.state.sessions, hasLength(1));
    expect(notifier.state.zikr.first.completed, 3);
  });

  test('Live Counter reset and abandon update state correctly', () async {
    final item = await notifier.create(draft(target: 33));
    await notifier.startCounterSession(zikrId: item.id, target: 33);
    await notifier.incrementCounter();
    await notifier.incrementCounter();

    expect(notifier.state.activeCounterSession?.count, 2);

    await notifier.resetCounterSession();
    expect(notifier.state.activeCounterSession?.count, 0);

    await notifier.abandonCounterSession();
    expect(notifier.state.activeCounterSession, isNull);
    expect(repository.loadActiveCounterSession(), isNull);
  });

  test('rapid repeated increments aggregate correctly', () async {
    final item = await notifier.create(draft(target: 100));
    await notifier.startCounterSession(zikrId: item.id, target: 100);

    for (var i = 0; i < 20; i++) {
      await notifier.incrementCounter();
    }

    expect(notifier.state.activeCounterSession?.count, 20);
  });

  test(
    'Manual Session Entry saves session directly and updates history',
    () async {
      final item = await notifier.create(draft(target: 500));
      await notifier.addSession(
        item.id,
        100,
        label: 'Manual Daily Session',
        note: 'Added manually',
        timestamp: now,
      );

      expect(notifier.state.sessions, hasLength(1));
      expect(notifier.state.sessions.first.amount, 100);
      expect(notifier.state.sessions.first.label, 'Manual Daily Session');
      expect(notifier.state.sessions.first.note, 'Added manually');
      expect(notifier.state.zikr.first.completed, 100);
    },
  );

  test(
    'History and Reflection receive both Live Counter and Manual sessions',
    () async {
      final item = await notifier.create(draft(target: 1000));

      // 1. Add manual session
      await notifier.addSession(item.id, 50, label: 'Manual Session');

      // 2. Complete a live counter session of 33
      await notifier.startCounterSession(zikrId: item.id, target: 33);
      for (var i = 0; i < 33; i++) {
        await notifier.incrementCounter();
      }

      expect(notifier.state.sessions, hasLength(2));
      expect(notifier.state.zikr.first.completed, 83); // 50 + 33 = 83

      final summary = await notifier.reflection(ReflectionPeriod.all);
      expect(summary.total, 83);
    },
  );
}
