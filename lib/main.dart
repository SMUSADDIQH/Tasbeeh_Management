import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/app.dart';
import 'features/home/data/repositories/counter_repository.dart';
import 'features/home/presentation/providers/counter_provider.dart';
import 'features/history/data/repositories/hive_history_repository.dart';
import 'features/history/presentation/providers/history_repository_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final counterBox = await Hive.openBox<dynamic>('tasbeeh_counter');
  final historyBox = await Hive.openLazyBox<dynamic>('tasbeeh_history');
  final historyRepository = HiveHistoryRepository(historyBox, counterBox);
  await historyRepository.migrateLegacySnapshot(counterBox.get('counter'));

  runApp(
    ProviderScope(
      overrides: [
        counterRepositoryProvider.overrideWithValue(
          HiveCounterRepository(counterBox),
        ),
        historyRepositoryProvider.overrideWithValue(historyRepository),
      ],
      child: const TasbeehTrackerApp(),
    ),
  );
}
