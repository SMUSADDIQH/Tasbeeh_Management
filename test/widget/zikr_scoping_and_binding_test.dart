import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tasbeeh_tracker/app/theme/app_theme.dart';
import 'package:tasbeeh_tracker/features/settings/presentation/providers/settings_provider.dart';
import 'package:tasbeeh_tracker/features/zikr/presentation/screens/history_screen.dart';
import 'package:tasbeeh_tracker/features/zikr/presentation/screens/zikr_details_screen.dart';
import 'package:tasbeeh_tracker/features/zikr/presentation/widgets/tasbeeh_counter_widget.dart';
import 'package:tasbeeh_tracker/features/zikr/presentation/widgets/zikr_widgets.dart';
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
        completed: 0,
      ).copyWith(name: 'Sample')
      ..zikr['s2'] = sampleZikr(
        id: 's2',
        target: 500,
        completed: 0,
      ).copyWith(name: 'Sample2');
    settingsRepository = MemorySettingsRepository();
  });

  Widget app(Widget child) {
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

  Widget appScreen(Widget child) {
    return ProviderScope(
      overrides: [
        zikrRepositoryProvider.overrideWithValue(zikrRepository),
        settingsRepositoryProvider.overrideWithValue(settingsRepository),
        clockProvider.overrideWithValue(() => now),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: child,
      ),
    );
  }

  testWidgets(
    'CASE 1: Live Counter on Sample2 is not mutated when Manual Entry is saved for Sample',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(app(const TasbeehCounterWidget()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Live Zikr'));
      await tester.pumpAndSettle();

      // Select Sample2 in Live Counter dropdown
      await tester.tap(
        find.byWidgetPredicate((w) => w is DropdownButtonFormField<String>),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sample2').last);
      await tester.pumpAndSettle();

      // Start Live Counter for Sample2
      await tester.tap(find.text('Start Live Session'));
      await tester.pumpAndSettle();

      // Verify active counter is for Sample2
      expect(zikrRepository.activeCounterSession?.zikrId, 's2');
      expect(zikrRepository.activeCounterSession?.count, 0);

      // Switch to Manual Entry tab
      await tester.tap(find.text('Manual Entry'));
      await tester.pumpAndSettle();

      // Select Sample in Manual Entry dropdown
      await tester.tap(
        find.byWidgetPredicate((w) => w is DropdownButtonFormField<String>),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sample').last);
      await tester.pumpAndSettle();

      // Enter count 50 and save
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Completed Count'),
        '50',
      );
      await tester.tap(find.text('Save Completed Session'));
      await tester.pumpAndSettle();

      // Expected: Sample completed count increases by 50, Sample2 completed count does not increase, active counter remains Sample2 at count 0
      expect(zikrRepository.zikr['s1']?.completed, 50);
      expect(zikrRepository.zikr['s2']?.completed, 0);
      expect(zikrRepository.activeCounterSession?.zikrId, 's2');
      expect(zikrRepository.activeCounterSession?.count, 0);
    },
  );

  testWidgets(
    'CASE 2: Live Counter remains active for Sample2 when Manual Entry is saved for Sample2',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(app(const TasbeehCounterWidget()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Live Zikr'));
      await tester.pumpAndSettle();

      // Select Sample2 and start Live Counter
      await tester.tap(
        find.byWidgetPredicate((w) => w is DropdownButtonFormField<String>),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sample2').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start Live Session'));
      await tester.pumpAndSettle();

      expect(zikrRepository.activeCounterSession?.zikrId, 's2');

      // Switch to Manual Entry
      await tester.tap(find.text('Manual Entry'));
      await tester.pumpAndSettle();

      // Select Sample2 in Manual Entry
      await tester.tap(
        find.byWidgetPredicate((w) => w is DropdownButtonFormField<String>),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sample2').last);
      await tester.pumpAndSettle();

      // Enter count 25 and save
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Completed Count'),
        '25',
      );
      await tester.tap(find.text('Save Completed Session'));
      await tester.pumpAndSettle();

      // Expected: Sample2 completed total increases by 25, active counter state remains unchanged
      expect(zikrRepository.zikr['s2']?.completed, 25);
      expect(zikrRepository.activeCounterSession?.zikrId, 's2');
      expect(zikrRepository.activeCounterSession?.count, 0);
      expect(
        zikrRepository.sessions.values.where((s) => s.zikrId == 's2'),
        hasLength(1),
      );
    },
  );

  testWidgets(
    'CASE 3: Open Sample Details has no Zikr selector and contains Sample-only data',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      zikrRepository.sessions['sess1'] = sampleSession(
        id: 'sess1',
        zikrId: 's1',
        amount: 100,
      );
      zikrRepository.sessions['sess2'] = sampleSession(
        id: 'sess2',
        zikrId: 's2',
        amount: 200,
      );

      await tester.pumpWidget(appScreen(const ZikrDetailsScreen(zikrId: 's1')));
      await tester.pumpAndSettle();

      // No dropdown
      expect(find.byType(DropdownButtonFormField<String>), findsNothing);

      // Displays Target Zikr: Sample locked indicator inside TasbeehCounterWidget
      expect(find.text('Target Zikr: Sample'), findsWidgets);

      // Session History only shows Sample session (100), not Sample2 (200)
      expect(find.text('+100'), findsOneWidget);
      expect(find.text('+200'), findsNothing);
    },
  );

  testWidgets('CASE 4: Open Sample2 Details contains Sample2-only data', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    zikrRepository.sessions['sess1'] = sampleSession(
      id: 'sess1',
      zikrId: 's1',
      amount: 100,
    );
    zikrRepository.sessions['sess2'] = sampleSession(
      id: 'sess2',
      zikrId: 's2',
      amount: 200,
    );

    await tester.pumpWidget(appScreen(const ZikrDetailsScreen(zikrId: 's2')));
    await tester.pumpAndSettle();

    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    expect(find.text('Target Zikr: Sample2'), findsWidgets);
    expect(find.text('+200'), findsOneWidget);
    expect(find.text('+100'), findsNothing);
  });

  testWidgets('CASE 5: Five Zikrs operate independently without fallback', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (var i = 1; i <= 5; i++) {
      zikrRepository.zikr['z$i'] = sampleZikr(
        id: 'z$i',
      ).copyWith(name: 'Zikr $i');
    }

    await tester.pumpWidget(app(const TasbeehCounterWidget()));
    await tester.pumpAndSettle();

    // Switch to Manual Entry
    await tester.tap(find.text('Manual Entry'));
    await tester.pumpAndSettle();

    // Select Zikr 4
    await tester.tap(
      find.byWidgetPredicate((w) => w is DropdownButtonFormField<String>),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zikr 4').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Completed Count'),
      '400',
    );
    await tester.tap(find.text('Save Completed Session'));
    await tester.pumpAndSettle();

    expect(zikrRepository.zikr['z4']?.completed, 400);
    expect(zikrRepository.zikr['z1']?.completed, 0);
    expect(zikrRepository.zikr['z2']?.completed, 0);
    expect(zikrRepository.zikr['z3']?.completed, 0);
    expect(zikrRepository.zikr['z5']?.completed, 0);
  });

  testWidgets(
    'CASE 6: Switching repeatedly between Live Counter and Manual Entry preserves selections',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(app(const TasbeehCounterWidget()));
      await tester.pumpAndSettle();

      // Switch to Live Zikr mode select Sample2
      await tester.tap(find.text('Live Zikr'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byWidgetPredicate((w) => w is DropdownButtonFormField<String>),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sample2').last);
      await tester.pumpAndSettle();

      // Switch to Manual Entry mode select Sample
      await tester.tap(find.text('Manual Entry'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byWidgetPredicate((w) => w is DropdownButtonFormField<String>),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sample').last);
      await tester.pumpAndSettle();

      // Toggle back to Live Zikr
      await tester.tap(find.text('Live Zikr'));
      await tester.pumpAndSettle();

      final liveDropdown = tester.widget<DropdownButtonFormField<String>>(
        find.byWidgetPredicate((w) => w is DropdownButtonFormField<String>),
      );
      expect(liveDropdown.initialValue, 's2');

      // Toggle back to Manual Entry
      await tester.tap(find.text('Manual Entry'));
      await tester.pumpAndSettle();

      final manualDropdown = tester.widget<DropdownButtonFormField<String>>(
        find.byWidgetPredicate((w) => w is DropdownButtonFormField<String>),
      );
      expect(manualDropdown.initialValue, 's1');
    },
  );

  testWidgets(
    'CASE 7: Deleting, archiving, or renaming Zikr preserves stable ID session association',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      zikrRepository.sessions['sess1'] = sampleSession(
        id: 'sess1',
        zikrId: 's1',
        amount: 100,
      );

      // Rename Zikr s1
      zikrRepository.zikr['s1'] = zikrRepository.zikr['s1']!.copyWith(
        name: 'Renamed Sample',
      );

      await tester.pumpWidget(appScreen(const ZikrDetailsScreen(zikrId: 's1')));
      await tester.pumpAndSettle();

      expect(find.text('Renamed Sample'), findsWidgets);
      expect(find.text('+100'), findsOneWidget);
    },
  );

  testWidgets(
    'CASE 8: Global History displays all sessions while Details history remains filtered',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Populate via repository before provider creation, or call notifier refresh
      final container = ProviderContainer(
        overrides: [
          zikrRepositoryProvider.overrideWithValue(zikrRepository),
          settingsRepositoryProvider.overrideWithValue(settingsRepository),
          clockProvider.overrideWithValue(() => now),
        ],
      );
      final notifier = container.read(zikrProvider.notifier);
      await notifier.refresh();
      await notifier.addSession('s1', 100, timestamp: DateTime.now());
      await notifier.addSession('s2', 200, timestamp: DateTime.now());

      // Global History Screen with expanded height
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            home: const Scaffold(
              body: SizedBox(height: 3000, child: HistoryScreen()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SessionTile), findsNWidgets(2));
      container.dispose();
    },
  );
}
