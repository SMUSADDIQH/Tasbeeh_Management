import 'package:flutter_test/flutter_test.dart';
import 'package:tasbeeh_tracker/features/zikr/domain/zikr_models.dart';
import 'package:tasbeeh_tracker/features/zikr/presentation/zikr_haptics.dart';
import 'package:tasbeeh_tracker/features/zikr/presentation/zikr_provider.dart';

import '../support/fakes.dart';

class TestZikrHaptics implements ZikrHaptics {
  int milestoneCount = 0;
  int completionCount = 0;

  @override
  Future<void> milestoneImpact() async {
    milestoneCount++;
  }

  @override
  Future<void> completionImpact() async {
    completionCount++;
  }

  void reset() {
    milestoneCount = 0;
    completionCount = 0;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MemoryZikrRepository repository;
  late TestZikrHaptics haptics;
  late ZikrNotifier notifier;
  final now = DateTime(2026, 7, 31, 12);

  setUp(() async {
    repository = MemoryZikrRepository();
    haptics = TestZikrHaptics();
    notifier = ZikrNotifier(repository, () => now, haptics: haptics);
    await notifier.refresh();
  });

  ZikrDraft draft({
    String name = 'SubhanAllah',
    int target = 1000,
    CountVibrationMode vibrationMode = CountVibrationMode.off,
    int? vibrationInterval,
  }) => ZikrDraft(
    name: name,
    target: target,
    category: ZikrCategory.tasbeeh,
    startingCompleted: 0,
    isFavorite: false,
    colorValue: 0xFF146B55,
    iconCodePoint: 0,
    startDate: now,
    countVibrationMode: vibrationMode,
    vibrationInterval: vibrationInterval,
  );

  test(
    'Existing Zikr records default vibration mode to Off (Backward Compatibility)',
    () {
      final oldRecordMap = {
        'id': 'old1',
        'name': 'Legacy Zikr',
        'target': 100,
        'completed': 10,
        'category': 'tasbeeh',
        'status': 'active',
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'startDate': now.toIso8601String(),
        'schemaVersion': 2,
      };

      final zikr = Zikr.fromMap(oldRecordMap);
      expect(zikr.countVibrationMode, CountVibrationMode.off);
      expect(zikr.vibrationInterval, isNull);
    },
  );

  test('New Zikr saves Tasbeeh 100 mode', () async {
    final item = await notifier.create(
      draft(vibrationMode: CountVibrationMode.tasbeeh100),
    );
    expect(item.countVibrationMode, CountVibrationMode.tasbeeh100);
    expect(item.vibrationInterval, isNull);
  });

  test('New Zikr saves a valid custom interval', () async {
    final item = await notifier.create(
      draft(
        vibrationMode: CountVibrationMode.customInterval,
        vibrationInterval: 10,
      ),
    );
    expect(item.countVibrationMode, CountVibrationMode.customInterval);
    expect(item.vibrationInterval, 10);
  });

  test('Tasbeeh 100 milestones occur at 33, 66 and 100', () async {
    final item = await notifier.create(
      draft(target: 1000, vibrationMode: CountVibrationMode.tasbeeh100),
    );
    await notifier.startCounterSession(zikrId: item.id, target: 1000);
    haptics.reset();

    for (var i = 1; i <= 32; i++) {
      await notifier.incrementCounter();
    }
    expect(haptics.milestoneCount, 0);

    await notifier.incrementCounter(); // count = 33
    expect(haptics.milestoneCount, 1);

    for (var i = 34; i <= 65; i++) {
      await notifier.incrementCounter();
    }
    expect(haptics.milestoneCount, 1);

    await notifier.incrementCounter(); // count = 66
    expect(haptics.milestoneCount, 2);

    for (var i = 67; i <= 99; i++) {
      await notifier.incrementCounter();
    }
    expect(haptics.milestoneCount, 2);

    await notifier.incrementCounter(); // count = 100
    expect(haptics.milestoneCount, 3);
  });

  test('Custom interval 10 occurs at 10, 20, 30', () async {
    final item = await notifier.create(
      draft(
        target: 1000,
        vibrationMode: CountVibrationMode.customInterval,
        vibrationInterval: 10,
      ),
    );
    await notifier.startCounterSession(zikrId: item.id, target: 1000);
    haptics.reset();

    for (var i = 1; i <= 9; i++) {
      await notifier.incrementCounter();
    }
    expect(haptics.milestoneCount, 0);

    await notifier.incrementCounter(); // count = 10
    expect(haptics.milestoneCount, 1);

    for (var i = 11; i <= 19; i++) {
      await notifier.incrementCounter();
    }
    expect(haptics.milestoneCount, 1);

    await notifier.incrementCounter(); // count = 20
    expect(haptics.milestoneCount, 2);

    for (var i = 21; i <= 29; i++) {
      await notifier.incrementCounter();
    }
    expect(haptics.milestoneCount, 2);

    await notifier.incrementCounter(); // count = 30
    expect(haptics.milestoneCount, 3);
  });

  test('Rebuild while count is 33 does not vibrate again', () async {
    final item = await notifier.create(
      draft(target: 1000, vibrationMode: CountVibrationMode.tasbeeh100),
    );
    await notifier.startCounterSession(zikrId: item.id, target: 1000);

    for (var i = 1; i <= 33; i++) {
      await notifier.incrementCounter();
    }
    expect(haptics.milestoneCount, 1);

    // Refresh provider state (simulating rebuild)
    await notifier.refresh();
    expect(haptics.milestoneCount, 1);
  });

  test('Restart while count is 33 does not vibrate again', () async {
    final item = await notifier.create(
      draft(target: 1000, vibrationMode: CountVibrationMode.tasbeeh100),
    );
    await notifier.startCounterSession(zikrId: item.id, target: 1000);

    for (var i = 1; i <= 33; i++) {
      await notifier.incrementCounter();
    }
    expect(haptics.milestoneCount, 1);

    // Simulate app restart
    final restartedNotifier = ZikrNotifier(
      repository,
      () => now,
      haptics: haptics,
    );
    await restartedNotifier.refresh();
    expect(haptics.milestoneCount, 1);
  });

  test('Rapid taps do not duplicate milestone vibration', () async {
    final item = await notifier.create(
      draft(target: 1000, vibrationMode: CountVibrationMode.tasbeeh100),
    );
    await notifier.startCounterSession(zikrId: item.id, target: 1000);
    haptics.reset();

    for (var i = 1; i <= 33; i++) {
      await notifier.incrementCounter();
    }
    expect(haptics.milestoneCount, 1);

    // Rapid duplicate call at count 33 (e.g. while session count is already 33)
    await notifier.incrementCounter(); // count becomes 34
    expect(haptics.milestoneCount, 1);
  });

  test('Live Target completion vibrates exactly once', () async {
    final item = await notifier.create(
      draft(target: 1000, vibrationMode: CountVibrationMode.off),
    );
    await notifier.startCounterSession(zikrId: item.id, target: 33);
    haptics.reset();

    for (var i = 1; i <= 32; i++) {
      await notifier.incrementCounter();
    }
    expect(haptics.completionCount, 0);

    await notifier.incrementCounter(); // count = 33 (target reached!)
    expect(haptics.completionCount, 1);

    // Extra increment call on completed session
    await notifier.incrementCounter();
    expect(haptics.completionCount, 1);
  });

  test(
    'Completion at an interval milestone does not trigger two vibration patterns',
    () async {
      final item = await notifier.create(
        draft(target: 1000, vibrationMode: CountVibrationMode.tasbeeh100),
      );
      // Live Target set to 33 (which is also a milestone in tasbeeh100 mode)
      await notifier.startCounterSession(zikrId: item.id, target: 33);
      haptics.reset();

      for (var i = 1; i <= 32; i++) {
        await notifier.incrementCounter();
      }
      expect(haptics.milestoneCount, 0);
      expect(haptics.completionCount, 0);

      await notifier
          .incrementCounter(); // count = 33 (reaches milestone & target!)
      expect(haptics.completionCount, 1);
      expect(haptics.milestoneCount, 0); // Completion takes precedence!
    },
  );

  test('Reset allows milestones to be crossed again', () async {
    final item = await notifier.create(
      draft(target: 1000, vibrationMode: CountVibrationMode.tasbeeh100),
    );
    await notifier.startCounterSession(zikrId: item.id, target: 1000);
    haptics.reset();

    for (var i = 1; i <= 33; i++) {
      await notifier.incrementCounter();
    }
    expect(haptics.milestoneCount, 1);

    // Reset session count to 0
    await notifier.resetCounterSession();
    expect(haptics.milestoneCount, 1); // Reset itself does not vibrate

    // Increment back up to 33
    for (var i = 1; i <= 33; i++) {
      await notifier.incrementCounter();
    }
    expect(haptics.milestoneCount, 2); // Milestone crossed again after reset!
  });

  test('Abandon does not vibrate', () async {
    final item = await notifier.create(
      draft(target: 1000, vibrationMode: CountVibrationMode.tasbeeh100),
    );
    await notifier.startCounterSession(zikrId: item.id, target: 1000);
    haptics.reset();

    await notifier.abandonCounterSession();
    expect(haptics.milestoneCount, 0);
    expect(haptics.completionCount, 0);
  });

  test(
    'Manual Entry does not trigger live vibration and does not alter active Live Counter state',
    () async {
      final item = await notifier.create(
        draft(target: 1000, vibrationMode: CountVibrationMode.tasbeeh100),
      );
      await notifier.startCounterSession(zikrId: item.id, target: 1000);
      await notifier.incrementCounter(); // count = 1
      haptics.reset();

      await notifier.addSession(item.id, 50, label: 'Manual Entry');

      expect(haptics.milestoneCount, 0);
      expect(haptics.completionCount, 0);

      // Active live counter session remains untouched at count 1
      expect(notifier.state.activeCounterSession?.zikrId, item.id);
      expect(notifier.state.activeCounterSession?.count, 1);
      expect(notifier.state.activeCounterSession?.target, 1000);
    },
  );

  test(
    'Zikr Details uses only the opened Zikr vibration configuration',
    () async {
      final item1 = await notifier.create(
        draft(name: 'Zikr1', vibrationMode: CountVibrationMode.off),
      );
      final item2 = await notifier.create(
        draft(
          name: 'Zikr2',
          vibrationMode: CountVibrationMode.customInterval,
          vibrationInterval: 5,
        ),
      );

      // Active counter on Zikr2
      await notifier.startCounterSession(zikrId: item2.id, target: 100);
      haptics.reset();

      for (var i = 1; i <= 5; i++) {
        await notifier.incrementCounter();
      }
      expect(haptics.milestoneCount, 1); // Zikr2's custom interval 5 triggered!

      // Start active counter on Zikr1 (which has vibration Mode OFF)
      await notifier.startCounterSession(zikrId: item1.id, target: 100);
      haptics.reset();

      for (var i = 1; i <= 5; i++) {
        await notifier.incrementCounter();
      }
      expect(haptics.milestoneCount, 0); // Zikr1 has vibration mode OFF!
    },
  );
}
