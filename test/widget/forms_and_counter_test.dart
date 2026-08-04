import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tasbeeh_tracker/app/app_shell.dart';
import 'package:tasbeeh_tracker/app/theme/app_theme.dart';
import 'package:tasbeeh_tracker/features/settings/presentation/providers/settings_provider.dart';
import 'package:tasbeeh_tracker/features/zikr/presentation/screens/home_screen.dart';
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

  setUp(() {
    zikrRepository = MemoryZikrRepository()
      ..zikr['z1'] = sampleZikr(completed: 100)
      ..sessions['s1'] = sampleSession();
    settingsRepository = MemorySettingsRepository();
  });

  Widget app(Widget child) {
    return ProviderScope(
      overrides: [
        zikrRepositoryProvider.overrideWithValue(zikrRepository),
        settingsRepositoryProvider.overrideWithValue(settingsRepository),
        clockProvider.overrideWithValue(() => DateTime(2026, 7, 30, 12)),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets(
    'showZikrForm creates and disposes controllers cleanly through dismissals',
    (tester) async {
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

      // Open form
      await tester.tap(find.text('Open Form'));
      await tester.pumpAndSettle();

      expect(find.text('New Zikr'), findsOneWidget);
      expect(find.byKey(const ValueKey('new-zikr-form')), findsOneWidget);

      // Enter values
      await tester.enterText(
        find.widgetWithText(TextFormField, 'English Name *'),
        'Test Zikr',
      );
      await tester.pump();

      // Dismiss by dragging down or tapping outside
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('new-zikr-form')), findsNothing);

      // Re-open form to verify repeated usage works cleanly
      await tester.tap(find.text('Open Form'));
      await tester.pumpAndSettle();
      expect(find.text('New Zikr'), findsOneWidget);

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
    },
  );

  testWidgets('showSessionForm creates and disposes controllers cleanly', (
    tester,
  ) async {
    final zikr = sampleZikr();
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) => Consumer(
            builder: (context, ref, _) => ElevatedButton(
              onPressed: () => showSessionForm(context, ref, zikr),
              child: const Text('Add Session'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Add Session'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('add-session-form')), findsOneWidget);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('add-session-form')), findsNothing);
  });

  testWidgets(
    'TasbeehCounterWidget renders visible Select Zikr label in Live setup and Manual entry',
    (tester) async {
      await tester.pumpWidget(app(const TasbeehCounterWidget()));
      await tester.pumpAndSettle();

      // Live setup view
      expect(find.text('Select Zikr:'), findsWidgets);

      // Switch to Manual Entry
      await tester.tap(find.text('Manual Entry'));
      await tester.pumpAndSettle();

      expect(find.text('Select Zikr:'), findsWidgets);
      expect(find.text('Completed Count'), findsOneWidget);
    },
  );

  testWidgets(
    'Home renders Continue Your Journey at the top before Completed Today',
    (tester) async {
      await tester.pumpWidget(
        app(HomeScreen(onNewZikr: () {}, onViewHistory: () {})),
      );
      await tester.pumpAndSettle();

      final continueFinder = find.text('Continue Your Journey');
      final todaysFinder = find.text('Completed Today');

      expect(continueFinder, findsOneWidget);
      expect(todaysFinder, findsOneWidget);

      final continueY = tester.getTopLeft(continueFinder).dy;
      final todaysY = tester.getTopLeft(todaysFinder).dy;

      // Continue Your Journey MUST be physically above Completed Today
      expect(continueY < todaysY, isTrue);
    },
  );

  testWidgets('AppShell tab re-tap triggers scroll to top without errors', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          zikrRepositoryProvider.overrideWithValue(zikrRepository),
          settingsRepositoryProvider.overrideWithValue(settingsRepository),
          clockProvider.overrideWithValue(() => DateTime(2026, 7, 30, 12)),
        ],
        child: const MaterialApp(home: AppShell()),
      ),
    );
    await tester.pumpAndSettle();

    // Re-tapping Home when offset is 0 should cause no exception
    await tester.tap(find.text('Home').first);
    await tester.pumpAndSettle();

    // Switch to Zikr tab
    await tester.tap(find.text('Zikr').first);
    await tester.pumpAndSettle();

    // Re-tapping Zikr when offset is 0 should cause no exception
    await tester.tap(find.text('Zikr').first);
    await tester.pumpAndSettle();

    // Switch to History tab
    await tester.tap(find.text('History').first);
    await tester.pumpAndSettle();

    // Re-tapping History when offset is 0 should cause no exception
    await tester.tap(find.text('History').first);
    await tester.pumpAndSettle();

    // Switch to Reflection tab
    await tester.tap(find.text('Reflection').first);
    await tester.pumpAndSettle();

    // Re-tapping Reflection when offset is 0 should cause no exception
    await tester.tap(find.text('Reflection').first);
    await tester.pumpAndSettle();
  });

  testWidgets(
    'ZikrDetailsScreen Delete menu item shows confirmation and handles cancellation vs deletion',
    (tester) async {
      await tester.pumpWidget(app(const ZikrDetailsScreen(zikrId: 'z1')));
      await tester.pumpAndSettle();

      // Open popup menu
      await tester.tap(find.byWidgetPredicate((w) => w is PopupMenuButton));
      await tester.pumpAndSettle();

      expect(find.text('Delete'), findsOneWidget);

      // Tap Delete
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Zikr?'), findsOneWidget);
      expect(find.text('Delete Permanently'), findsOneWidget);

      // Cancel deletion
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Zikr?'), findsNothing);
      expect(zikrRepository.zikr.containsKey('z1'), isTrue);

      // Open popup menu again
      await tester.tap(find.byWidgetPredicate((w) => w is PopupMenuButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Confirm deletion
      await tester.tap(find.text('Delete Permanently'));
      await tester.pumpAndSettle();

      expect(zikrRepository.zikr.containsKey('z1'), isFalse);
      expect(zikrRepository.sessions.containsKey('s1'), isFalse);
    },
  );
}
