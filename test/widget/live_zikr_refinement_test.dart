import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tasbeeh_tracker/app/theme/app_theme.dart';
import 'package:tasbeeh_tracker/features/settings/presentation/providers/settings_provider.dart';
import 'package:tasbeeh_tracker/features/zikr/presentation/widgets/tasbeeh_counter_widget.dart';
import 'package:tasbeeh_tracker/features/zikr/presentation/zikr_provider.dart';

import '../support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  late MemoryZikrRepository zikrRepository;
  late MemorySettingsRepository settingsRepository;
  final now = DateTime(2026, 7, 30, 12);

  setUp(() {
    zikrRepository = MemoryZikrRepository()
      ..zikr['s1'] = sampleZikr(
        id: 's1',
        target: 1000,
        completed: 100,
      ).copyWith(name: 'Sample1')
      ..zikr['s2'] = sampleZikr(
        id: 's2',
        target: 500,
        completed: 50,
      ).copyWith(name: 'Sample2')
      ..sessions['sess1'] = sampleSession(
        id: 'sess1',
        zikrId: 's1',
        amount: 100,
      )
      ..sessions['sess2'] = sampleSession(
        id: 'sess2',
        zikrId: 's2',
        amount: 50,
      );
    settingsRepository = MemorySettingsRepository();
  });

  Widget buildApp(Widget child) {
    return ProviderScope(
      overrides: [
        zikrRepositoryProvider.overrideWithValue(zikrRepository),
        settingsRepositoryProvider.overrideWithValue(settingsRepository),
        clockProvider.overrideWithValue(() => now),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );
  }

  testWidgets(
    'Renders Live Zikr tab title and 3-column top/bottom stats rows',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildApp(const TasbeehCounterWidget()));
      await tester.pumpAndSettle();

      // Tab title is 'Live Zikr'
      expect(find.text('Live Zikr'), findsOneWidget);
      expect(find.text('Manual Entry'), findsOneWidget);

      // Switch to Live Zikr tab
      await tester.tap(find.text('Live Zikr'));
      await tester.pumpAndSettle();

      // Start Live Session for Sample1
      await tester.tap(find.text('Start Live Session'));
      await tester.pumpAndSettle();

      // Top Stats Row (MAIN Zikr metrics)
      expect(find.text('Target'), findsOneWidget);
      expect(find.text('1,000'), findsWidgets); // Main Target = 1000
      expect(find.text('Remaining'), findsOneWidget);
      expect(
        find.text('900'),
        findsOneWidget,
      ); // Main Remaining = 1000 - 100 = 900
      expect(find.text('Percentage'), findsOneWidget);
      expect(find.text('10.0%'), findsOneWidget); // (100 / 1000) * 100 = 10.0%

      // Bottom Stats Row (LIVE Session metrics)
      expect(find.text('Live Remaining'), findsOneWidget);
      expect(
        find.text('33'),
        findsWidgets,
      ); // Live Target = 33, count = 0 -> Live Remaining = 33
      expect(find.text('Live Target'), findsOneWidget);
      expect(find.text('Live Percentage'), findsOneWidget);
      expect(find.text('0.0%'), findsNWidgets(2));
    },
  );

  testWidgets(
    'Changing Live Zikr while active session exists switches non-destructively',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildApp(const TasbeehCounterWidget()));
      await tester.pumpAndSettle();

      // Switch to Live Zikr tab
      await tester.tap(find.text('Live Zikr'));
      await tester.pumpAndSettle();

      // Start live session for Sample1
      await tester.tap(find.text('Start Live Session'));
      await tester.pumpAndSettle();

      // Tap 'Change Zikr' button in header
      await tester.tap(find.text('Change Zikr'));
      await tester.pumpAndSettle();

      // Select Sample2
      await tester.tap(find.text('Sample2'));
      await tester.pumpAndSettle();

      // Non-destructive: Sample1 draft remains safely preserved in repository drafts map
      expect(zikrRepository.liveDrafts['s1'], isNotNull);
      expect(zikrRepository.liveDrafts['s1']?.zikrId, 's1');
    },
  );

  testWidgets(
    'Zikr Details screen remains locked without Zikr selector or Change Zikr option',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildApp(const TasbeehCounterWidget(initialZikrId: 's1')),
      );
      await tester.pumpAndSettle();

      // Switch to Live Zikr tab
      await tester.tap(find.text('Live Zikr'));
      await tester.pumpAndSettle();

      // Locked badge shown
      expect(find.text('Target Zikr: Sample1'), findsOneWidget);
      expect(find.text('Change Zikr'), findsNothing);
      expect(
        find.byWidgetPredicate((w) => w is DropdownButtonFormField<String>),
        findsNothing,
      );
    },
  );
}
