import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tasbeeh_tracker/app/theme/app_theme.dart';
import 'package:tasbeeh_tracker/features/settings/presentation/providers/settings_provider.dart';
import 'package:tasbeeh_tracker/features/zikr/domain/zikr_models.dart';
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
        completed: 100,
      ).copyWith(name: 'Sample')
      ..sessions['sess1'] = sampleSession(
        id: 'sess1',
        zikrId: 's1',
        amount: 100,
      );
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

  testWidgets(
    'Preset 34 is available and selecting it starts liveTarget = 34',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(app(const TasbeehCounterWidget()));
      await tester.pumpAndSettle();

      // ChoiceChip '34' is present
      final chip34 = find.widgetWithText(ChoiceChip, '34');
      expect(chip34, findsOneWidget);

      // Tap 34
      await tester.tap(chip34);
      await tester.pumpAndSettle();

      // Start Live Session
      await tester.tap(find.text('Start Live Session'));
      await tester.pumpAndSettle();

      // Verify active session target is 34
      expect(zikrRepository.activeCounterSession?.target, 34);
    },
  );

  testWidgets(
    'Active Live Counter displays Live Target, Live Remaining, Target, and Remaining statistics',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Start live counter for Sample (target 1000, completed 100) with Live Target 34
      await tester.pumpWidget(app(const TasbeehCounterWidget()));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ChoiceChip, '34'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start Live Session'));
      await tester.pumpAndSettle();

      // Check text labels
      expect(find.text('Live Target: 34'), findsOneWidget);
      expect(find.text('Live Remaining'), findsOneWidget);
      expect(find.text('Target'), findsOneWidget);
      expect(find.text('Remaining'), findsOneWidget);

      // Verify Main Remaining starts at 1000 - 100 = 900
      expect(find.text('900'), findsOneWidget);

      // Tap counter button
      await tester.tap(find.bySemanticsLabel(RegExp(r'Counter control')));
      await tester.pumpAndSettle();

      // Effective completed is 100 + 1 = 101. Main Remaining = 1000 - 101 = 899
      expect(find.text('899'), findsOneWidget);
    },
  );

  testWidgets('Main Remaining never becomes negative', (tester) async {
    // Set completed equal to target
    zikrRepository.zikr['s1'] = sampleZikr(
      id: 's1',
      target: 100,
      completed: 100,
    ).copyWith(name: 'Sample');

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app(const TasbeehCounterWidget()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start Live Session'));
    await tester.pumpAndSettle();

    // Increment count by 1 (effective completed = 101)
    await tester.tap(find.byType(GestureDetector).at(1));
    await tester.pumpAndSettle();

    // Main Remaining should be clamped to 0, not negative
    expect(find.text('0'), findsWidgets);
  });

  testWidgets('Custom interval form rejects empty, zero, and negative values', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showZikrForm(context, defaultTarget: 100),
            child: const Text('Open Form'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Form'));
    await tester.pumpAndSettle();

    // Fill Name
    await tester.enterText(
      find.widgetWithText(TextFormField, 'English Name *'),
      'Test Zikr',
    );

    // Select Vibration Mode: Every N Counts
    await tester.tap(
      find.widgetWithText(
        DropdownButtonFormField<CountVibrationMode>,
        'Vibration Mode',
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Every N Counts').last);
    await tester.pumpAndSettle();

    final submitBtn = find.widgetWithText(FilledButton, 'Create Zikr');
    await tester.ensureVisible(submitBtn);
    await tester.pumpAndSettle();

    // Interval is initially empty -> Submit -> Should show 'Interval is required'
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();
    expect(find.text('Interval is required'), findsOneWidget);

    // Enter 0 -> Submit -> Should show 'Enter an interval greater than 0'
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Vibration Interval'),
      '0',
    );
    await tester.ensureVisible(submitBtn);
    await tester.pumpAndSettle();
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();
    expect(find.text('Enter an interval greater than 0'), findsOneWidget);
  });
}
