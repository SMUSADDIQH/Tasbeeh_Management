import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tasbeeh_tracker/app/theme/app_theme.dart';
import 'package:tasbeeh_tracker/features/settings/presentation/providers/settings_provider.dart';
import 'package:tasbeeh_tracker/features/settings/presentation/screens/settings_screen.dart';
import 'package:tasbeeh_tracker/features/zikr/presentation/screens/history_screen.dart';
import 'package:tasbeeh_tracker/features/zikr/presentation/screens/home_screen.dart';
import 'package:tasbeeh_tracker/features/zikr/presentation/screens/reflection_screen.dart';
import 'package:tasbeeh_tracker/features/zikr/presentation/screens/zikr_screen.dart';
import 'package:tasbeeh_tracker/features/zikr/presentation/zikr_provider.dart';

import '../support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  late MemoryZikrRepository zikrRepository;
  late MemorySettingsRepository settingsRepository;

  setUp(() {
    zikrRepository = MemoryZikrRepository()
      ..zikr['z1'] = sampleZikr(completed: 100)
      ..sessions['s1'] = sampleSession(timestamp: DateTime.now());
    settingsRepository = MemorySettingsRepository();
  });

  Widget app(Widget child, {ThemeMode mode = ThemeMode.light}) {
    return ProviderScope(
      overrides: [
        zikrRepositoryProvider.overrideWithValue(zikrRepository),
        settingsRepositoryProvider.overrideWithValue(settingsRepository),
        clockProvider.overrideWithValue(() => DateTime(2026, 7, 30, 12)),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: mode,
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets('Home renders Arabic greeting and session dashboard', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(HomeScreen(onNewZikr: () {}, onViewHistory: () {})),
    );
    await tester.pump();
    expect(
      find.text('أَلَا بِذِكْرِ ٱللَّهِ تَطْمَئِنُّ ٱلْقُلُوبُ'),
      findsOneWidget,
    );
    expect(find.text('Completed Today'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Continue Your Journey'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Continue Your Journey'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Recent Activity'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Recent Activity'), findsOneWidget);
    expect(find.textContaining('Good Morning'), findsNothing);
  });

  testWidgets('Zikr screen renders session-based actions', (tester) async {
    await tester.pumpWidget(app(const ZikrScreen()));
    await tester.pumpAndSettle();
    expect(find.text('My Zikr'), findsOneWidget);
    expect(find.text('Add Session'), findsOneWidget);
    expect(find.text('New Zikr'), findsWidgets);
  });

  testWidgets('History renders completed session with running total', (
    tester,
  ) async {
    await tester.pumpWidget(app(const HistoryScreen()));
    await tester.pumpAndSettle();
    expect(find.text('History'), findsOneWidget);
    expect(find.text('+100'), findsOneWidget);
    expect(find.textContaining('Total 100'), findsOneWidget);
  });

  testWidgets('Reflection renders meaningful cards and accessible chart', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(app(const ReflectionScreen()));
    await tester.pump();
    await tester.pump();
    expect(find.text('Reflection'), findsOneWidget);
    expect(find.text('Total Completed'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        RegExp('Weekly completed sessions chart.*Monday through Sunday'),
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('Settings renders geometric header and preference sections', (
    tester,
  ) async {
    await tester.pumpWidget(app(const SettingsScreen()));
    await tester.pump();
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Zikr & Data'), findsOneWidget);
    expect(find.text('Backup and Restore'), findsOneWidget);
  });

  testWidgets('large text and landscape layouts do not overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
        child: app(HomeScreen(onNewZikr: () {}, onViewHistory: () {})),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('all destinations support phone, landscape, tablet, and themes', (
    tester,
  ) async {
    final screens = <Widget>[
      HomeScreen(onNewZikr: () {}, onViewHistory: () {}),
      const ZikrScreen(),
      const HistoryScreen(),
      const ReflectionScreen(),
      const SettingsScreen(),
    ];
    for (final size in const [
      Size(360, 800),
      Size(800, 420),
      Size(1100, 900),
    ]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      for (final mode in [ThemeMode.light, ThemeMode.dark]) {
        for (final screen in screens) {
          await tester.pumpWidget(app(screen, mode: mode));
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason:
                '${screen.runtimeType} failed at ${size.width}x${size.height} '
                'in ${mode.name}',
          );
        }
      }
    }
    tester.view.reset();
  });

  test('light and dark themes meet primary text contrast', () {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      final colors = theme.colorScheme;
      expect(
        _contrast(colors.onPrimary, colors.primary),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(colors.onSurface, colors.surface),
        greaterThanOrEqualTo(4.5),
      );
    }
  });
}

double _contrast(Color first, Color second) {
  final a = first.computeLuminance();
  final b = second.computeLuminance();
  return ((a > b ? a : b) + 0.05) / ((a > b ? b : a) + 0.05);
}
