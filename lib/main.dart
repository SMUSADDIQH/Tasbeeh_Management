import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/app.dart';
import 'features/home/data/repositories/counter_repository.dart';
import 'features/home/presentation/providers/counter_provider.dart';
import 'features/history/data/repositories/hive_history_repository.dart';
import 'features/history/presentation/providers/history_repository_provider.dart';
import 'features/statistics/data/repositories/cached_statistics_repository.dart';
import 'features/statistics/presentation/providers/statistics_provider.dart';
import 'features/settings/data/repositories/hive_settings_repository.dart';
import 'features/settings/presentation/providers/settings_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final counterBox = await Hive.openBox<dynamic>('tasbeeh_counter');
  final historyBox = await Hive.openLazyBox<dynamic>('tasbeeh_history');
  final statisticsBox = await Hive.openBox<dynamic>('tasbeeh_statistics');
  final settingsBox = await Hive.openBox<dynamic>('tasbeeh_settings');
  final historyRepository = HiveHistoryRepository(historyBox, counterBox);
  await historyRepository.migrateLegacySnapshot(counterBox.get('counter'));
  final counterRepository = HiveCounterRepository(counterBox);
  final statisticsRepository = CachedStatisticsRepository(
    historyRepository,
    counterRepository,
    statisticsBox,
  );
  final settingsRepository = HiveSettingsRepository(settingsBox);

  runApp(
    ProviderScope(
      overrides: [
        counterRepositoryProvider.overrideWithValue(counterRepository),
        historyRepositoryProvider.overrideWithValue(historyRepository),
        statisticsRepositoryProvider.overrideWithValue(statisticsRepository),
        settingsRepositoryProvider.overrideWithValue(settingsRepository),
      ],
      child: const TasbeehTrackerApp(),
    ),
  );
}
