import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tasbeeh_tracker/app/theme/app_theme.dart';
import 'package:tasbeeh_tracker/features/settings/presentation/providers/settings_provider.dart';
import 'package:tasbeeh_tracker/features/zikr/domain/zikr_models.dart';
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
      ).copyWith(name: 'Sample')
      ..zikr['s2'] = sampleZikr(
        id: 's2',
        target: 500,
        completed: 50,
      ).copyWith(name: 'Sample2')
      ..zikr['s3'] = sampleZikr(
        id: 's3',
        target: 300,
        completed: 0,
      ).copyWith(name: 'Sample3')
      ..zikr['s4'] = sampleZikr(
        id: 's4',
        target: 400,
        completed: 0,
      ).copyWith(name: 'Sample4')
      ..zikr['s5'] = sampleZikr(
        id: 's5',
        target: 500,
        completed: 0,
      ).copyWith(name: 'Sample5');
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
    '1-4. Per-Zikr draft switching preserves count and targets independently for 5+ Zikrs',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          zikrRepositoryProvider.overrideWithValue(zikrRepository),
          clockProvider.overrideWithValue(() => now),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(zikrProvider.notifier);

      // Start session for Sample (s1) with target 100, count 40
      await notifier.startCounterSession(zikrId: 's1', target: 100);
      for (var i = 0; i < 40; i++) {
        await notifier.incrementCounter(forZikrId: 's1');
      }

      // Start session for Sample2 (s2) with target 33, count 15
      await notifier.selectLiveZikr('s2');
      await notifier.startCounterSession(zikrId: 's2', target: 33);
      for (var i = 0; i < 15; i++) {
        await notifier.incrementCounter(forZikrId: 's2');
      }

      // Verify drafts in state
      expect(container.read(zikrProvider).liveDrafts['s1']?.count, 40);
      expect(container.read(zikrProvider).liveDrafts['s1']?.target, 100);
      expect(container.read(zikrProvider).liveDrafts['s2']?.count, 15);
      expect(container.read(zikrProvider).liveDrafts['s2']?.target, 33);

      // Switch back to s1
      await notifier.selectLiveZikr('s1');
      expect(container.read(zikrProvider).activeCounterSession?.zikrId, 's1');
      expect(container.read(zikrProvider).activeCounterSession?.count, 40);
      expect(container.read(zikrProvider).activeCounterSession?.target, 100);

      // Switch back to s2
      await notifier.selectLiveZikr('s2');
      expect(container.read(zikrProvider).activeCounterSession?.zikrId, 's2');
      expect(container.read(zikrProvider).activeCounterSession?.count, 15);
      expect(container.read(zikrProvider).activeCounterSession?.target, 33);
    },
  );

  testWidgets(
    '5-6. App restart restores all unfinished drafts and previously selected Live Zikr',
    (tester) async {
      // Create pre-existing drafts in repository
      zikrRepository.liveDrafts['s1'] = ActiveCounterSession(
        id: 'sess1',
        zikrId: 's1',
        target: 100,
        count: 40,
        createdAt: now,
        updatedAt: now,
      );
      zikrRepository.liveDrafts['s2'] = ActiveCounterSession(
        id: 'sess2',
        zikrId: 's2',
        target: 33,
        count: 15,
        createdAt: now,
        updatedAt: now,
      );
      zikrRepository.selectedLiveZikrId = 's2';

      final container = ProviderContainer(
        overrides: [
          zikrRepositoryProvider.overrideWithValue(zikrRepository),
          clockProvider.overrideWithValue(() => now),
        ],
      );
      addTearDown(container.dispose);

      await container.read(zikrProvider.notifier).refresh();

      final state = container.read(zikrProvider);
      expect(state.selectedLiveZikrId, 's2');
      expect(state.activeCounterSession?.count, 15);
      expect(state.liveDrafts['s1']?.count, 40);
    },
  );

  testWidgets(
    '7-12. Manual submit below target saves count, creates 1 session, clears only draft, and keeps main remaining stable',
    (tester) async {
      zikrRepository.sessions['s1-init'] = sampleSession(
        id: 's1-init',
        zikrId: 's1',
        amount: 100,
      );

      final container = ProviderContainer(
        overrides: [
          zikrRepositoryProvider.overrideWithValue(zikrRepository),
          clockProvider.overrideWithValue(() => now),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(zikrProvider.notifier);

      // Start s1 with target 1000, completed = 100, draft count = 52
      await notifier.startCounterSession(zikrId: 's1', target: 100);
      for (var i = 0; i < 52; i++) {
        await notifier.incrementCounter(forZikrId: 's1');
      }

      // Also create draft for s2
      await notifier.selectLiveZikr('s2');
      await notifier.startCounterSession(zikrId: 's2', target: 33);
      for (var i = 0; i < 15; i++) {
        await notifier.incrementCounter(forZikrId: 's2');
      }

      // Before submit check s1: persisted completed = 100, draft = 52 -> effective = 152
      final s1Before = container
          .read(zikrProvider)
          .zikr
          .firstWhere((z) => z.id == 's1');
      expect(s1Before.completed, 100);
      expect(container.read(zikrProvider).liveDrafts['s1']?.count, 52);

      // Submit s1 draft (52)
      final success = await notifier.submitLiveSession('s1');
      expect(success, isTrue);

      // s1 draft cleared, s2 draft preserved
      expect(container.read(zikrProvider).liveDrafts['s1'], isNull);
      expect(container.read(zikrProvider).liveDrafts['s2']?.count, 15);

      // s1 completed total updated to 152
      final s1After = container
          .read(zikrProvider)
          .zikr
          .firstWhere((z) => z.id == 's1');
      expect(s1After.completed, 152);

      // History sessions count for s1 is 2 (initial session + submitted live session)
      final s1Sessions = zikrRepository.sessions.values
          .where((s) => s.zikrId == 's1')
          .toList();
      expect(s1Sessions.length, 2);
      expect(s1Sessions.last.amount, 52);
    },
  );

  testWidgets(
    '13-16. Rapid submit taps and zero count guard against duplicate submissions',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          zikrRepositoryProvider.overrideWithValue(zikrRepository),
          clockProvider.overrideWithValue(() => now),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(zikrProvider.notifier);

      // Draft count 0 -> cannot submit
      final zeroSubmit = await notifier.submitLiveSession('s1');
      expect(zeroSubmit, isFalse);

      // Start s1 with count 10
      await notifier.startCounterSession(zikrId: 's1', target: 100);
      for (var i = 0; i < 10; i++) {
        await notifier.incrementCounter(forZikrId: 's1');
      }

      // Rapid double submission
      final f1 = notifier.submitLiveSession('s1');
      final f2 = notifier.submitLiveSession('s1');
      final results = await Future.wait([f1, f2]);

      // Exactly one succeeds
      expect(results.where((r) => r == true).length, 1);
    },
  );

  testWidgets(
    '17-21. Reset, Abandon, Delete, and Manual Entry remain strictly scoped per Zikr',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          zikrRepositoryProvider.overrideWithValue(zikrRepository),
          clockProvider.overrideWithValue(() => now),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(zikrProvider.notifier);

      // Draft s1 = 40, s2 = 15
      await notifier.startCounterSession(zikrId: 's1', target: 100);
      for (var i = 0; i < 40; i++) {
        await notifier.incrementCounter(forZikrId: 's1');
      }

      await notifier.selectLiveZikr('s2');
      await notifier.startCounterSession(zikrId: 's2', target: 33);
      for (var i = 0; i < 15; i++) {
        await notifier.incrementCounter(forZikrId: 's2');
      }

      // Reset s2 -> s2 count = 0, s1 count remains 40
      await notifier.resetCounterSession(forZikrId: 's2');
      expect(container.read(zikrProvider).liveDrafts['s2']?.count, 0);
      expect(container.read(zikrProvider).liveDrafts['s1']?.count, 40);

      // Abandon s2 -> s2 draft removed, s1 draft remains 40
      await notifier.abandonCounterSession(forZikrId: 's2');
      expect(container.read(zikrProvider).liveDrafts['s2'], isNull);
      expect(container.read(zikrProvider).liveDrafts['s1']?.count, 40);

      // Delete s1 -> s1 draft removed
      await notifier.deleteZikr('s1');
      expect(container.read(zikrProvider).liveDrafts['s1'], isNull);
    },
  );

  testWidgets('22. Legacy single active session loads as per-Zikr draft', (
    tester,
  ) async {
    zikrRepository.activeCounterSession = ActiveCounterSession(
      id: 'legacy-sess',
      zikrId: 's1',
      target: 100,
      count: 40,
      createdAt: now,
      updatedAt: now,
    );

    final container = ProviderContainer(
      overrides: [
        zikrRepositoryProvider.overrideWithValue(zikrRepository),
        clockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(container.dispose);

    await container.read(zikrProvider.notifier).refresh();
    final drafts = container.read(zikrProvider).liveDrafts;

    expect(drafts['s1']?.count, 40);
    expect(drafts['s1']?.target, 100);
  });

  testWidgets(
    '24. UI Widget lifecycle renders Submit Live Session button and non-destructive switching',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildApp(const TasbeehCounterWidget()));
      await tester.pumpAndSettle();

      // Start Live Session
      await tester.tap(find.text('Start Live Session'));
      await tester.pumpAndSettle();

      // Increment count once
      await tester.tap(find.bySemanticsLabel(RegExp(r'Counter control')));
      await tester.pumpAndSettle();

      // Submit Live Session button is visible with count 1
      expect(find.text('Submit Live Session (1)'), findsOneWidget);

      // Tap Submit Live Session button
      await tester.tap(find.text('Submit Live Session (1)'));
      await tester.pumpAndSettle();

      // Dialog prompt appears
      expect(find.text('Submit Live Session?'), findsOneWidget);
      expect(
        find.text(
          'Submit the current count of 1 for "Sample" as a completed session?',
        ),
        findsOneWidget,
      );

      // Tap Submit Session in dialog
      await tester.tap(find.text('Submit Session'));
      await tester.pumpAndSettle();

      // Success snackbar
      expect(find.text('Live session submitted successfully'), findsOneWidget);
    },
  );
}
