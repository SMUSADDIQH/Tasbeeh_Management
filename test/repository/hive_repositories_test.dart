import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tasbeeh_tracker/features/history/data/repositories/hive_history_repository.dart';
import 'package:tasbeeh_tracker/features/history/domain/models/history_filter.dart';
import 'package:tasbeeh_tracker/features/home/data/repositories/counter_repository.dart';
import 'package:tasbeeh_tracker/features/home/domain/models/tasbeeh_counter_model.dart';
import 'package:tasbeeh_tracker/features/settings/data/repositories/hive_settings_repository.dart';
import 'package:tasbeeh_tracker/features/settings/domain/models/app_settings.dart';
import 'package:tasbeeh_tracker/features/statistics/data/repositories/cached_statistics_repository.dart';
import 'package:tasbeeh_tracker/features/statistics/domain/models/statistics_models.dart';

import '../support/fakes.dart';

void main() {
  late Directory directory;
  late Box<dynamic> counterBox;
  late LazyBox<dynamic> historyBox;
  late Box<dynamic> settingsBox;
  late Box<dynamic> statisticsBox;

  setUpAll(() async {
    directory = Directory.systemTemp.createTempSync('tasbeeh_repo_test.');
    Hive.init(directory.path);
    counterBox = await Hive.openBox<dynamic>('counter_test');
    historyBox = await Hive.openLazyBox<dynamic>('history_test');
    settingsBox = await Hive.openBox<dynamic>('settings_test');
    statisticsBox = await Hive.openBox<dynamic>('statistics_test');
  });

  setUp(() async {
    await counterBox.clear();
    await historyBox.clear();
    await settingsBox.clear();
    await statisticsBox.clear();
  });

  tearDownAll(() async {
    await Hive.close();
    directory.deleteSync(recursive: true);
  });

  test('counter and settings repositories restore persisted state', () async {
    final counterRepository = HiveCounterRepository(counterBox);
    final settingsRepository = HiveSettingsRepository(settingsBox);
    final counter = TasbeehCounterModel.initial(
      DateTime(2026, 7, 30),
    ).copyWith(currentCount: 42, target: 500);
    const settings = AppSettings(
      theme: AppThemePreference.dark,
      defaultTarget: 500,
      hapticFeedbackEnabled: false,
      counterAnimationEnabled: true,
      continuousCountSpeed: ContinuousCountSpeed.fast,
    );

    await counterRepository.save(counter);
    await settingsRepository.save(settings);

    expect(counterRepository.load()?.currentCount, 42);
    expect(counterRepository.load()?.target, 500);
    expect(settingsRepository.load().theme, AppThemePreference.dark);
    expect(
      settingsRepository.load().continuousCountSpeed,
      ContinuousCountSpeed.fast,
    );
  });

  test(
    'history repository uses cursor pages and supports replacement',
    () async {
      final repository = HiveHistoryRepository(historyBox, counterBox);
      final now = DateTime.now();
      for (var index = 0; index < 35; index++) {
        await repository.append(
          historyEntry(
            timestamp: now.subtract(Duration(minutes: index)),
            previousCount: index,
            newCount: index + 1,
            todayCount: index + 1,
            lifetimeCount: index + 1,
          ),
        );
      }

      final firstPage = await repository.fetchPage(
        range: HistoryFilter.allTime.rangeAt(now),
        searchTerm: '',
        limit: 20,
      );
      final secondPage = await repository.fetchPage(
        range: HistoryFilter.allTime.rangeAt(now),
        searchTerm: '',
        limit: 20,
        cursor: firstPage.nextCursor,
      );

      expect(firstPage.entries, hasLength(20));
      expect(firstPage.hasMore, isTrue);
      expect(secondPage.entries, hasLength(15));
      expect(secondPage.hasMore, isFalse);

      await repository.replaceAll(firstPage.entries.take(2).toList());
      expect(await repository.fetchAll(), hasLength(2));
    },
  );

  test('statistics repository caches calculated period metrics', () async {
    final historyRepository = FakeHistoryRepository();
    final counterRepository = FakeCounterRepository(
      TasbeehCounterModel.initial(DateTime.now()).copyWith(lifetimeCount: 30),
    );
    final today = DateTime.now();
    historyRepository.entries.addAll([
      historyEntry(
        timestamp: today.subtract(const Duration(days: 1)),
        newCount: 20,
        todayCount: 20,
        lifetimeCount: 20,
      ),
      historyEntry(
        timestamp: today,
        previousCount: 20,
        newCount: 30,
        todayCount: 10,
        lifetimeCount: 30,
      ),
    ]);
    final repository = CachedStatisticsRepository(
      historyRepository,
      counterRepository,
      statisticsBox,
    );

    final first = await repository.load();
    final second = await repository.load();

    expect(identical(first, second), isTrue);
    expect(first.metrics[StatisticsPeriod.lifetime]?.totalCount, 30);
    expect(first.sevenDayCounts, hasLength(7));
  });
}
