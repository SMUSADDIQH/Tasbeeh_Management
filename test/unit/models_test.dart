import 'package:flutter_test/flutter_test.dart';
import 'package:tasbeeh_tracker/core/utils/count_formatter.dart';
import 'package:tasbeeh_tracker/features/history/domain/models/counter_history_entry.dart';
import 'package:tasbeeh_tracker/features/history/domain/models/history_filter.dart';
import 'package:tasbeeh_tracker/features/home/domain/models/tasbeeh_counter_model.dart';
import 'package:tasbeeh_tracker/features/settings/domain/models/app_settings.dart';

void main() {
  group('TasbeehCounterModel', () {
    test('round-trips persisted values and derives progress', () {
      final model = TasbeehCounterModel.initial(
        DateTime(2026, 7, 30),
      ).copyWith(currentCount: 25, target: 40, lifetimeCount: 125);

      final restored = TasbeehCounterModel.fromMap(model.toMap());

      expect(restored.currentCount, 25);
      expect(restored.target, 40);
      expect(restored.remaining, 15);
      expect(restored.progressPercent, 63);
      expect(restored.lifetimeCount, 125);
    });
  });

  group('CounterHistoryEntry', () {
    test('round-trips all release fields', () {
      final entry = CounterHistoryEntry(
        action: CounterHistoryAction.reset,
        timestamp: DateTime(2026, 7, 30, 9, 42),
        previousCount: 33,
        newCount: 0,
        target: 100,
        todayCount: 33,
        lifetimeCount: 1200,
      );

      final restored = CounterHistoryEntry.tryFromMap(entry.toMap());

      expect(restored?.action, CounterHistoryAction.reset);
      expect(restored?.previousCount, 33);
      expect(restored?.newCount, 0);
      expect(restored?.lifetimeCount, 1200);
    });
  });

  group('HistoryFilter', () {
    test('today includes today and excludes yesterday', () {
      final range = HistoryFilter.today.rangeAt(DateTime(2026, 7, 30, 12));

      expect(range.contains(DateTime(2026, 7, 30, 23)), isTrue);
      expect(range.contains(DateTime(2026, 7, 29, 23)), isFalse);
    });
  });

  group('AppSettings', () {
    test('restores every persisted preference', () {
      const settings = AppSettings(
        theme: AppThemePreference.dark,
        defaultTarget: 500,
        hapticFeedbackEnabled: false,
        counterAnimationEnabled: false,
        continuousCountSpeed: ContinuousCountSpeed.fast,
      );

      final restored = AppSettings.fromMap(settings.toMap());

      expect(restored.theme, AppThemePreference.dark);
      expect(restored.defaultTarget, 500);
      expect(restored.hapticFeedbackEnabled, isFalse);
      expect(restored.counterAnimationEnabled, isFalse);
      expect(restored.continuousCountSpeed, ContinuousCountSpeed.fast);
    });
  });

  test('formatCount groups thousands without locale allocation', () {
    expect(formatCount(2450), '2,450');
    expect(formatCount(125000), '125,000');
  });
}
