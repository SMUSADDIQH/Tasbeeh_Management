import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/settings/domain/models/app_settings.dart';
import '../features/settings/presentation/providers/settings_provider.dart';
import 'app_shell.dart';
import 'theme/app_theme.dart';

class TasbeehTrackerApp extends ConsumerWidget {
  const TasbeehTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themePreference = ref.watch(
      settingsProvider.select((state) => state.settings.theme),
    );
    final themeMode = switch (themePreference) {
      AppThemePreference.system => ThemeMode.system,
      AppThemePreference.light => ThemeMode.light,
      AppThemePreference.dark => ThemeMode.dark,
    };

    return MaterialApp(
      title: 'Zikr',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: const AppShell(),
    );
  }
}
