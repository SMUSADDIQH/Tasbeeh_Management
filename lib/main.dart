import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/app.dart';
import 'features/settings/data/repositories/hive_settings_repository.dart';
import 'features/settings/presentation/providers/settings_provider.dart';
import 'features/zikr/data/hive_zikr_repository.dart';
import 'features/zikr/presentation/zikr_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Version 2 deliberately uses isolated boxes. Version 1 event data is never
  // opened or interpreted as completed sessions.
  final zikrBox = await Hive.openBox<dynamic>('zikr_v2');
  final sessionBox = await Hive.openLazyBox<dynamic>('zikr_sessions_v2');
  final preferencesBox = await Hive.openBox<dynamic>('preferences_v2');
  final zikrRepository = HiveZikrRepository(zikrBox, sessionBox);
  await zikrRepository.verifyIntegrity();

  runApp(
    ProviderScope(
      overrides: [
        zikrRepositoryProvider.overrideWithValue(zikrRepository),
        settingsRepositoryProvider.overrideWithValue(
          HiveSettingsRepository(preferencesBox),
        ),
      ],
      child: const TasbeehTrackerApp(),
    ),
  );
}
