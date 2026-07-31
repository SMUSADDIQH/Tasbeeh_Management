import 'package:flutter_test/flutter_test.dart';
import 'package:tasbeeh_tracker/features/settings/domain/models/app_settings.dart';
import 'package:tasbeeh_tracker/features/zikr/domain/zikr_models.dart';

void main() {
  group('Settings & Auto-translate Model', () {
    test('10. Existing setting defaults to false', () {
      final settings = AppSettings.defaults();
      expect(settings.autoTranslateZikrName, isFalse);
    });

    test('11. Setting persists enabled and disabled states', () {
      final mapEnabled = {'autoTranslateZikrName': true};
      final loadedEnabled = AppSettings.fromMap(mapEnabled);
      expect(loadedEnabled.autoTranslateZikrName, isTrue);

      final mapDisabled = {'autoTranslateZikrName': false};
      final loadedDisabled = AppSettings.fromMap(mapDisabled);
      expect(loadedDisabled.autoTranslateZikrName, isFalse);

      final copied = loadedEnabled.copyWith(autoTranslateZikrName: false);
      expect(copied.autoTranslateZikrName, isFalse);
      expect(copied.toMap()['autoTranslateZikrName'], isFalse);
    });
  });

  group('Repeating Tasbeeh 100 Pattern', () {
    test('23. Milestones include 33, 66 and 100', () {
      expect(
        evaluateVibrationTrigger(
          previousCount: 32,
          newCount: 33,
          liveTarget: 1000,
          vibrationMode: CountVibrationMode.tasbeeh100,
          customInterval: null,
        ),
        VibrationTrigger.milestone,
      );

      expect(
        evaluateVibrationTrigger(
          previousCount: 65,
          newCount: 66,
          liveTarget: 1000,
          vibrationMode: CountVibrationMode.tasbeeh100,
          customInterval: null,
        ),
        VibrationTrigger.milestone,
      );

      expect(
        evaluateVibrationTrigger(
          previousCount: 99,
          newCount: 100,
          liveTarget: 1000,
          vibrationMode: CountVibrationMode.tasbeeh100,
          customInterval: null,
        ),
        VibrationTrigger.milestone,
      );
    });

    test('24. Milestones continue at 133, 166 and 200', () {
      expect(
        evaluateVibrationTrigger(
          previousCount: 132,
          newCount: 133,
          liveTarget: 1000,
          vibrationMode: CountVibrationMode.tasbeeh100,
          customInterval: null,
        ),
        VibrationTrigger.milestone,
      );

      expect(
        evaluateVibrationTrigger(
          previousCount: 165,
          newCount: 166,
          liveTarget: 1000,
          vibrationMode: CountVibrationMode.tasbeeh100,
          customInterval: null,
        ),
        VibrationTrigger.milestone,
      );

      expect(
        evaluateVibrationTrigger(
          previousCount: 199,
          newCount: 200,
          liveTarget: 1000,
          vibrationMode: CountVibrationMode.tasbeeh100,
          customInterval: null,
        ),
        VibrationTrigger.milestone,
      );
    });

    test('25. Milestones continue at 233, 266 and 300', () {
      expect(
        evaluateVibrationTrigger(
          previousCount: 232,
          newCount: 233,
          liveTarget: 1000,
          vibrationMode: CountVibrationMode.tasbeeh100,
          customInterval: null,
        ),
        VibrationTrigger.milestone,
      );

      expect(
        evaluateVibrationTrigger(
          previousCount: 265,
          newCount: 266,
          liveTarget: 1000,
          vibrationMode: CountVibrationMode.tasbeeh100,
          customInterval: null,
        ),
        VibrationTrigger.milestone,
      );

      expect(
        evaluateVibrationTrigger(
          previousCount: 299,
          newCount: 300,
          liveTarget: 1000,
          vibrationMode: CountVibrationMode.tasbeeh100,
          customInterval: null,
        ),
        VibrationTrigger.milestone,
      );
    });

    test(
      '26. Counts 32, 34, 65, 67, 99 and 101 do not trigger incorrectly',
      () {
        expect(
          evaluateVibrationTrigger(
            previousCount: 31,
            newCount: 32,
            liveTarget: 1000,
            vibrationMode: CountVibrationMode.tasbeeh100,
            customInterval: null,
          ),
          VibrationTrigger.none,
        );

        expect(
          evaluateVibrationTrigger(
            previousCount: 33,
            newCount: 34,
            liveTarget: 1000,
            vibrationMode: CountVibrationMode.tasbeeh100,
            customInterval: null,
          ),
          VibrationTrigger.none,
        );

        expect(
          evaluateVibrationTrigger(
            previousCount: 64,
            newCount: 65,
            liveTarget: 1000,
            vibrationMode: CountVibrationMode.tasbeeh100,
            customInterval: null,
          ),
          VibrationTrigger.none,
        );

        expect(
          evaluateVibrationTrigger(
            previousCount: 66,
            newCount: 67,
            liveTarget: 1000,
            vibrationMode: CountVibrationMode.tasbeeh100,
            customInterval: null,
          ),
          VibrationTrigger.none,
        );

        expect(
          evaluateVibrationTrigger(
            previousCount: 98,
            newCount: 99,
            liveTarget: 1000,
            vibrationMode: CountVibrationMode.tasbeeh100,
            customInterval: null,
          ),
          VibrationTrigger.none,
        );

        expect(
          evaluateVibrationTrigger(
            previousCount: 100,
            newCount: 101,
            liveTarget: 1000,
            vibrationMode: CountVibrationMode.tasbeeh100,
            customInterval: null,
          ),
          VibrationTrigger.none,
        );
      },
    );

    test('27. Restoring at 133 does not replay vibration', () {
      expect(
        evaluateVibrationTrigger(
          previousCount: 133,
          newCount: 133,
          liveTarget: 1000,
          vibrationMode: CountVibrationMode.tasbeeh100,
          customInterval: null,
          lastVibratedMilestone: 133,
        ),
        VibrationTrigger.none,
      );
    });

    test('28. Incrementing from 132 to 133 vibrates exactly once', () {
      final trigger = evaluateVibrationTrigger(
        previousCount: 132,
        newCount: 133,
        liveTarget: 1000,
        vibrationMode: CountVibrationMode.tasbeeh100,
        customInterval: null,
        lastVibratedMilestone: 100,
      );
      expect(trigger, VibrationTrigger.milestone);

      final crossed = getCrossedMilestone(
        previousCount: 132,
        newCount: 133,
        vibrationMode: CountVibrationMode.tasbeeh100,
        customInterval: null,
      );
      expect(crossed, 133);

      final nextTrigger = evaluateVibrationTrigger(
        previousCount: 133,
        newCount: 133,
        liveTarget: 1000,
        vibrationMode: CountVibrationMode.tasbeeh100,
        customInterval: null,
        lastVibratedMilestone: 133,
      );
      expect(nextTrigger, VibrationTrigger.none);
    });

    test('29. Switching away and back does not duplicate vibration', () {
      expect(
        evaluateVibrationTrigger(
          previousCount: 133,
          newCount: 133,
          liveTarget: 1000,
          vibrationMode: CountVibrationMode.tasbeeh100,
          customInterval: null,
          lastVibratedMilestone: 133,
        ),
        VibrationTrigger.none,
      );
    });
  });

  group('Custom Repeating Interval', () {
    test('30. Interval 50 triggers at 50, 100, 150 and 200', () {
      for (final m in [50, 100, 150, 200]) {
        expect(
          evaluateVibrationTrigger(
            previousCount: m - 1,
            newCount: m,
            liveTarget: 1000,
            vibrationMode: CountVibrationMode.customInterval,
            customInterval: 50,
          ),
          VibrationTrigger.milestone,
        );
      }
    });

    test('31. Interval 10 continues beyond 100', () {
      expect(
        evaluateVibrationTrigger(
          previousCount: 109,
          newCount: 110,
          liveTarget: 1000,
          vibrationMode: CountVibrationMode.customInterval,
          customInterval: 10,
        ),
        VibrationTrigger.milestone,
      );

      expect(
        evaluateVibrationTrigger(
          previousCount: 149,
          newCount: 150,
          liveTarget: 1000,
          vibrationMode: CountVibrationMode.customInterval,
          customInterval: 10,
        ),
        VibrationTrigger.milestone,
      );
    });

    test('32. Custom zero and negative values are rejected', () {
      expect(
        evaluateVibrationTrigger(
          previousCount: 9,
          newCount: 10,
          liveTarget: 1000,
          vibrationMode: CountVibrationMode.customInterval,
          customInterval: 0,
        ),
        VibrationTrigger.none,
      );

      expect(
        evaluateVibrationTrigger(
          previousCount: 9,
          newCount: 10,
          liveTarget: 1000,
          vibrationMode: CountVibrationMode.customInterval,
          customInterval: -5,
        ),
        VibrationTrigger.none,
      );
    });

    test('33. App restart does not replay a custom milestone', () {
      expect(
        evaluateVibrationTrigger(
          previousCount: 150,
          newCount: 150,
          liveTarget: 1000,
          vibrationMode: CountVibrationMode.customInterval,
          customInterval: 50,
          lastVibratedMilestone: 150,
        ),
        VibrationTrigger.none,
      );
    });
  });

  group('Completion Safety & Precedence', () {
    test(
      '34. Completion vibration takes precedence over interval vibration',
      () {
        final trigger = evaluateVibrationTrigger(
          previousCount: 99,
          newCount: 100,
          liveTarget: 100,
          vibrationMode: CountVibrationMode.tasbeeh100,
          customInterval: null,
        );
        expect(trigger, VibrationTrigger.completion);
      },
    );

    test(
      '35. Target 100 with Tasbeeh 100 emits one vibration at completion',
      () {
        final trigger = evaluateVibrationTrigger(
          previousCount: 99,
          newCount: 100,
          liveTarget: 100,
          vibrationMode: CountVibrationMode.tasbeeh100,
          customInterval: null,
        );
        expect(trigger, VibrationTrigger.completion);
      },
    );

    test(
      '36. Target 200 with interval 50 emits one vibration at completion',
      () {
        final trigger = evaluateVibrationTrigger(
          previousCount: 199,
          newCount: 200,
          liveTarget: 200,
          vibrationMode: CountVibrationMode.customInterval,
          customInterval: 50,
        );
        expect(trigger, VibrationTrigger.completion);
      },
    );
  });
}
