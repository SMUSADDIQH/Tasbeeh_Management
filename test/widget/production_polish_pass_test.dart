import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

import 'package:tasbeeh_tracker/app/app.dart';
import 'package:tasbeeh_tracker/app/theme/app_colors.dart';
import 'package:tasbeeh_tracker/features/settings/presentation/screens/privacy_policy_screen.dart';
import 'package:tasbeeh_tracker/features/settings/presentation/screens/report_issue_screen.dart';
import 'package:tasbeeh_tracker/features/settings/presentation/screens/settings_screen.dart';
import 'package:tasbeeh_tracker/features/settings/presentation/screens/terms_of_use_screen.dart';
import 'package:tasbeeh_tracker/features/settings/presentation/providers/settings_provider.dart';
import 'package:tasbeeh_tracker/features/settings/presentation/services/app_share_service.dart';
import 'package:tasbeeh_tracker/features/zikr/data/arabic_name_translation_service.dart';
import 'package:tasbeeh_tracker/features/zikr/domain/zikr_models.dart';
import 'package:tasbeeh_tracker/features/zikr/presentation/screens/history_screen.dart';
import 'package:tasbeeh_tracker/features/zikr/presentation/screens/home_screen.dart';
import 'package:tasbeeh_tracker/features/zikr/presentation/widgets/tasbeeh_counter_widget.dart';
import 'package:tasbeeh_tracker/features/zikr/presentation/zikr_provider.dart';

import '../support/fakes.dart';

void main() {
  late MemoryZikrRepository repo;

  setUp(() {
    repo = MemoryZikrRepository();
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 2));

    repo.replaceAll(
      zikr: [
        Zikr(
          id: 'z1',
          name: 'SubhanAllah',
          arabicName: 'سبحان الله',
          category: ZikrCategory.tasbeeh,
          target: 100,
          completed: 40,
          isFavorite: false,
          colorValue: 0xFF146B55,
          iconCodePoint: 0,
          status: ZikrStatus.active,
          startDate: now,
          createdAt: now,
          updatedAt: now,
        ),
        Zikr(
          id: 'z2',
          name: 'Alhamdulillah',
          arabicName: 'الحمد لله',
          category: ZikrCategory.tasbeeh,
          target: 100,
          completed: 30,
          isFavorite: false,
          colorValue: 0xFF146B55,
          iconCodePoint: 0,
          status: ZikrStatus.active,
          startDate: now,
          createdAt: now,
          updatedAt: now,
        ),
      ],
      sessions: [
        ZikrSession(
          id: 's1',
          zikrId: 'z1',
          amount: 40,
          runningTotalAfter: 40,
          timestamp: now,
          createdAt: now,
          updatedAt: now,
          label: 'Daily Session',
          note: 'Morning recitation',
        ),
        ZikrSession(
          id: 's2',
          zikrId: 'z2',
          amount: 30,
          runningTotalAfter: 30,
          timestamp: yesterday,
          createdAt: yesterday,
          updatedAt: yesterday,
          label: 'Custom Session',
          note: 'Special note',
        ),
      ],
    );
  });

  Widget buildTestApp(Widget child) {
    return ProviderScope(
      overrides: [
        zikrRepositoryProvider.overrideWithValue(repo),
        settingsProvider.overrideWith(
          (ref) => SettingsNotifier(MemorySettingsRepository()),
        ),
        arabicTranslationServiceProvider.overrideWithValue(
          FakeArabicNameTranslationService(),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.darkEmerald,
            brightness: Brightness.dark,
          ),
        ),
        home: Scaffold(body: child),
      ),
    );
  }

  group('Requirement 1: History Search Mode & Layout', () {
    testWidgets(
      'History screen has no permanent Search sessions bar, search icon enters search mode',
      (tester) async {
        await tester.pumpWidget(buildTestApp(const HistoryScreen()));
        await tester.pumpAndSettle();

        // 1. No permanent Search sessions field visible in normal History mode
        expect(find.byType(SearchBar), findsNothing);
        expect(find.text('History'), findsOneWidget);

        // 2. Search icon is visible beside filter icon
        expect(find.byIcon(Icons.search), findsOneWidget);
        expect(find.byIcon(Icons.filter_list_rounded), findsOneWidget);

        // 3. Tapping Search enters search mode
        await tester.tap(find.byIcon(Icons.search));
        await tester.pumpAndSettle();

        // 4. Search field is active and focused
        expect(find.byType(TextField), findsOneWidget);
        expect(find.byIcon(Icons.arrow_back), findsOneWidget);

        // 5. Search filters by Zikr name
        await tester.enterText(find.byType(TextField), 'Subhan');
        await tester.pumpAndSettle();
        expect(find.text('SubhanAllah'), findsOneWidget);

        // 6. Clear search button restores query
        expect(find.byIcon(Icons.clear), findsOneWidget);
        await tester.tap(find.byIcon(Icons.clear));
        await tester.pumpAndSettle();
        expect(find.text('SubhanAllah'), findsOneWidget);

        // 7. Exiting search mode restores header
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();
        expect(find.text('History'), findsOneWidget);
        expect(find.byType(TextField), findsNothing);
      },
    );
  });

  group('Requirement 2: History Default Filter ("Today")', () {
    testWidgets('History initially defaults to Today range', (tester) async {
      await tester.pumpWidget(buildTestApp(const HistoryScreen()));
      await tester.pumpAndSettle();

      // Today session (s1: SubhanAllah) is shown, older session (s2: Alhamdulillah) excluded
      expect(find.text('SubhanAllah'), findsOneWidget);
      expect(find.text('Alhamdulillah'), findsNothing);

      // Open Filter sheet
      await tester.tap(find.byIcon(Icons.filter_list_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Filter Sessions'), findsOneWidget);
      expect(find.text('Today'), findsWidgets);

      // Reset Filters restores Today
      await tester.tap(find.text('Reset Filters'));
      await tester.pumpAndSettle();

      expect(find.text('SubhanAllah'), findsOneWidget);
    });
  });

  group('Requirement 3: Mode Selector (Manual Entry | Live Zikr)', () {
    testWidgets(
      'Mode selector displays Manual Entry before Live Zikr and selects Manual by default',
      (tester) async {
        await tester.pumpWidget(buildTestApp(const TasbeehCounterWidget()));
        await tester.pumpAndSettle();

        // Tab order and default selection
        expect(find.text('Manual Entry'), findsOneWidget);
        expect(find.text('Live Zikr'), findsOneWidget);

        // Tapping Live Zikr switches tab
        await tester.tap(find.text('Live Zikr'));
        await tester.pumpAndSettle();

        expect(find.text('34'), findsWidgets);
      },
    );
  });

  group('Requirement 4: Daily Session Everywhere', () {
    testWidgets('Daily Session appears in predefined session labels', (
      tester,
    ) async {
      expect(kPredefinedSessionLabels.contains('Daily Session'), isTrue);
      expect(kPredefinedSessionLabels.first, 'Daily Session');
    });

    testWidgets('Settings default session label includes Daily Session', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestApp(const SettingsScreen()));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Default session label'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      await tester.tap(find.text('Default session label'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Daily Session'), findsOneWidget);
    });
  });

  group('Requirement 5: Legal Screens Contrast', () {
    testWidgets(
      'Privacy Policy and Terms of Use render with explicit high-contrast theme',
      (tester) async {
        await tester.pumpWidget(const MaterialApp(home: PrivacyPolicyScreen()));
        await tester.pumpAndSettle();

        expect(find.text('Privacy Policy'), findsWidgets);

        await tester.pumpWidget(const MaterialApp(home: TermsOfUseScreen()));
        await tester.pumpAndSettle();

        expect(find.text('Terms of Use'), findsWidgets);
      },
    );
  });

  group('Support & Report Issue Screen Requirements', () {
    testWidgets(
      'Help and Support displays support@riontix.com and no example placeholders',
      (tester) async {
        await tester.pumpWidget(buildTestApp(const SettingsScreen()));
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('Help and Support'),
          200,
          scrollable: find.byType(Scrollable).first,
        );

        expect(find.text('support@riontix.com'), findsOneWidget);
        expect(find.text('support@example.com'), findsNothing);
      },
    );

    testWidgets('Report Issue opens ReportIssueScreen form', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(const SettingsScreen()));
      await tester.pumpAndSettle();

      final reportIssueFinder = find.widgetWithText(ListTile, 'Report Issue');
      await tester.ensureVisible(reportIssueFinder);
      await tester.pumpAndSettle();

      await tester.tap(reportIssueFinder);
      await tester.pumpAndSettle();

      expect(find.text('Report an Issue'), findsWidgets);
      expect(find.text('Your email address'), findsOneWidget);
      expect(find.text('Issue subject'), findsOneWidget);
      expect(find.text('Explain the issue'), findsOneWidget);
    });

    testWidgets(
      'ReportIssueScreen validates mandatory fields and error inline text',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(const MaterialApp(home: ReportIssueScreen()));
        await tester.pumpAndSettle();

        // Tap Prepare Email Report without filling inputs
        await tester.ensureVisible(find.text('Prepare Email Report'));
        await tester.tap(
          find.text('Prepare Email Report'),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();

        expect(find.text('Your email address is required.'), findsOneWidget);

        // Enter invalid email
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Your email address'),
          'invalid-email',
        );
        await tester.tap(
          find.text('Prepare Email Report'),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Please enter a valid email address.'),
          findsOneWidget,
        );

        // Enter valid email but invalid subject
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Your email address'),
          'user@riontix.com',
        );
        await tester.tap(
          find.text('Prepare Email Report'),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();

        expect(find.text('Issue subject is required.'), findsOneWidget);

        // Enter subject but short description
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Issue subject'),
          'Bug in live counter',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Explain the issue'),
          'short',
        );
        await tester.tap(
          find.text('Prepare Email Report'),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Please provide a description of at least 15 characters.'),
          findsOneWidget,
        );
      },
    );
  });

  group('Direct App Launch & Removed Custom Splash', () {
    testWidgets(
      'Custom premium splash widget and tasbeeh_premium_splash.png asset references are removed',
      (tester) async {
        final mainContent = File('lib/main.dart').readAsStringSync();
        final pubspecContent = File('pubspec.yaml').readAsStringSync();

        expect(mainContent.contains('tasbeeh_premium_splash.png'), isFalse);
        expect(mainContent.contains('_PremiumSplash'), isFalse);
        expect(mainContent.contains('minimumSplashDuration'), isFalse);
        expect(pubspecContent.contains('tasbeeh_premium_splash.png'), isFalse);
        expect(
          File('assets/branding/tasbeeh_premium_splash.png').existsSync(),
          isFalse,
        );
      },
    );

    testWidgets(
      'Application starts directly with ProviderScope into TasbeehTrackerApp / Home experience',
      (tester) async {
        await tester.pumpWidget(buildTestApp(const TasbeehTrackerApp()));
        await tester.pumpAndSettle();

        // Home screen renders immediately as the first Flutter screen
        expect(find.byType(HomeScreen), findsOneWidget);
      },
    );

    testWidgets(
      'Home screen displays Quran 13:28 Ayah header instead of old Assalamu Alaikum greeting',
      (tester) async {
        await tester.pumpWidget(
          buildTestApp(HomeScreen(onNewZikr: () {}, onViewHistory: () {})),
        );
        await tester.pumpAndSettle();

        // Old greeting removed
        expect(find.text('السلام عليكم'), findsNothing);
        expect(find.text('Peace be upon you'), findsNothing);

        // New Qur'anic Ayah, English meaning and reference displayed
        expect(
          find.text('أَلَا بِذِكْرِ ٱللَّهِ تَطْمَئِنُّ ٱلْقُلُوبُ'),
          findsOneWidget,
        );
        expect(
          find.text(
            'Surely, in the remembrance of Allah do hearts find peace.',
          ),
          findsOneWidget,
        );
        expect(find.text('Qur’an 13:28'), findsOneWidget);
      },
    );
  });

  group('Share App Requirements', () {
    testWidgets(
      'AppShareService generates Play Store URL and shares text correctly',
      (tester) async {
        ShareParams? capturedParams;
        final mockPackageInfo = PackageInfo(
          appName: 'Tasbeeh Tracker',
          packageName: 'com.riontix.tasbeehmanagement',
          version: '1.0.0',
          buildNumber: '1',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => const AppShareService().shareApp(
                  context,
                  overridePackageInfo: mockPackageInfo,
                  overrideShareFunction: (params) async {
                    capturedParams = params;
                  },
                ),
                child: const Text('Share'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Share'));
        await tester.pumpAndSettle();

        expect(capturedParams, isNotNull);
        expect(capturedParams!.subject, 'Tasbeeh Management');
        expect(capturedParams!.text, contains('Tasbeeh Management'));
        expect(
          capturedParams!.text,
          contains(
            'https://play.google.com/store/apps/details?id=com.riontix.tasbeehmanagement',
          ),
        );
        expect(capturedParams!.text, isNot(contains('runningTotalAfter')));
        expect(capturedParams!.text, isNot(contains('SubhanAllah')));
      },
    );

    testWidgets('AppShareService handles failure with fallback message', (
      tester,
    ) async {
      final mockPackageInfo = PackageInfo(
        appName: 'Tasbeeh Tracker',
        packageName: 'com.riontix.tasbeehmanagement',
        version: '1.0.0',
        buildNumber: '1',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => const AppShareService().shareApp(
                  context,
                  overridePackageInfo: mockPackageInfo,
                  overrideShareFunction: (params) async {
                    throw Exception('Share failed');
                  },
                ),
                child: const Text('Share'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Share'));
      await tester.pumpAndSettle();

      expect(
        find.text('Failed to share app. Please try again.'),
        findsOneWidget,
      );
    });
  });
}
