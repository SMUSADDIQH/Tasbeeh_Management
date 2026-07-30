import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/settings/presentation/providers/settings_provider.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/zikr/presentation/screens/history_screen.dart';
import '../features/zikr/presentation/screens/home_screen.dart';
import '../features/zikr/presentation/screens/reflection_screen.dart';
import '../features/zikr/presentation/screens/zikr_screen.dart';
import '../features/zikr/presentation/widgets/zikr_widgets.dart';
import '../features/zikr/presentation/zikr_provider.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});
  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _selectedIndex = 0;

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.spa_outlined),
      selectedIcon: Icon(Icons.spa_rounded),
      label: 'Zikr',
    ),
    NavigationDestination(
      icon: Icon(Icons.history_outlined),
      selectedIcon: Icon(Icons.history_rounded),
      label: 'History',
    ),
    NavigationDestination(
      icon: Icon(Icons.auto_awesome_outlined),
      selectedIcon: Icon(Icons.auto_awesome_rounded),
      label: 'Reflection',
    ),
    NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings_rounded),
      label: 'Settings',
    ),
  ];

  Future<void> _newZikr() async {
    final draft = await showZikrForm(
      context,
      defaultTarget: ref.read(settingsProvider).settings.defaultTarget,
    );
    if (draft != null) {
      await ref.read(zikrProvider.notifier).create(draft);
      if (mounted) setState(() => _selectedIndex = 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        onNewZikr: _newZikr,
        onViewHistory: () => setState(() => _selectedIndex = 2),
      ),
      const ZikrScreen(),
      const HistoryScreen(),
      const ReflectionScreen(),
      const SettingsScreen(),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final content = IndexedStack(index: _selectedIndex, children: screens);
        if (constraints.maxWidth >= 840) {
          return Scaffold(
            body: Row(
              children: [
                SafeArea(
                  child: NavigationRail(
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: (value) =>
                        setState(() => _selectedIndex = value),
                    extended: constraints.maxWidth >= 1120,
                    labelType: constraints.maxWidth >= 1120
                        ? NavigationRailLabelType.none
                        : NavigationRailLabelType.all,
                    destinations: [
                      for (final destination in _destinations)
                        NavigationRailDestination(
                          icon: destination.icon,
                          selectedIcon: destination.selectedIcon,
                          label: Text(destination.label),
                        ),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: content),
              ],
            ),
          );
        }
        return Scaffold(
          body: content,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (value) =>
                setState(() => _selectedIndex = value),
            destinations: _destinations,
          ),
        );
      },
    );
  }
}
