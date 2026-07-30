import 'package:flutter_test/flutter_test.dart';
import 'package:tasbeeh_tracker/features/zikr/domain/zikr_models.dart';
import 'package:tasbeeh_tracker/features/zikr/presentation/zikr_provider.dart';

import '../support/fakes.dart';

void main() {
  test('Zikr serialization preserves all fields and calculates remaining', () {
    final original = sampleZikr(target: 1000, completed: 250);
    final restored = Zikr.fromMap(original.toMap());
    expect(restored.name, original.name);
    expect(restored.arabicName, original.arabicName);
    expect(restored.remaining, 750);
    expect(restored.progress, 0.25);
  });

  test('session serialization preserves amount, note, label and total', () {
    final original = sampleSession();
    final restored = ZikrSession.fromMap(original.toMap());
    expect(restored.amount, 100);
    expect(restored.note, 'Quiet morning');
    expect(restored.label, 'After Fajr');
    expect(restored.runningTotalAfter, 100);
  });

  test('invalid model records are rejected', () {
    expect(() => Zikr.fromMap({'id': 'bad'}), throwsA(isA<FormatException>()));
    expect(
      () => ZikrSession.fromMap({'id': 'bad'}),
      throwsA(isA<FormatException>()),
    );
  });

  test('reflection calculates totals, best day and streaks', () async {
    final repository = MemoryZikrRepository();
    repository.zikr['z1'] = sampleZikr(completed: 600);
    repository.sessions
      ..['s1'] = sampleSession(
        timestamp: DateTime(2026, 7, 28),
        amount: 100,
        total: 100,
      )
      ..['s2'] = sampleSession(
        id: 's2',
        timestamp: DateTime(2026, 7, 29),
        amount: 200,
        total: 300,
      )
      ..['s3'] = sampleSession(
        id: 's3',
        timestamp: DateTime(2026, 7, 30),
        amount: 300,
        total: 600,
      );
    final notifier = ZikrNotifier(repository, () => DateTime(2026, 7, 30, 12));
    await notifier.refresh();
    final result = await notifier.reflection(ReflectionPeriod.all);
    expect(result.total, 600);
    expect(result.averagePerActiveDay, 200);
    expect(result.bestDayTotal, 300);
    expect(result.currentStreak, 3);
    expect(result.longestStreak, 3);
    expect(result.mostActiveZikr?.id, 'z1');
  });

  test('projected completion is deterministic with injected clock', () async {
    final repository = MemoryZikrRepository();
    repository.zikr['z1'] = sampleZikr(completed: 200);
    repository.sessions
      ..['s1'] = sampleSession(timestamp: DateTime(2026, 7, 29), amount: 100)
      ..['s2'] = sampleSession(
        id: 's2',
        timestamp: DateTime(2026, 7, 30),
        amount: 100,
        total: 200,
      );
    final notifier = ZikrNotifier(repository, () => DateTime(2026, 7, 30));
    await notifier.refresh();
    final result = await notifier.reflection(ReflectionPeriod.all);
    expect(result.projectedCompletion, DateTime(2026, 8, 7));
  });
}
