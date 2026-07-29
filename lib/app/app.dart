import 'package:flutter/material.dart';

import '../features/home/presentation/screens/home_screen.dart';
import 'theme/app_theme.dart';

class TasbeehTrackerApp extends StatelessWidget {
  const TasbeehTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tasbeeh-Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
