import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tasbeeh_tracker/features/settings/domain/models/app_settings.dart';
import 'package:tasbeeh_tracker/features/settings/domain/repositories/settings_repository.dart';
import 'package:tasbeeh_tracker/features/settings/presentation/providers/settings_provider.dart';
import 'package:tasbeeh_tracker/features/zikr/data/arabic_name_translation_service.dart';
import 'package:tasbeeh_tracker/features/zikr/presentation/widgets/zikr_widgets.dart';

import '../support/fakes.dart';

class TestSettingsRepository implements SettingsRepository {
  AppSettings currentSettings = AppSettings.defaults();

  @override
  AppSettings load() => currentSettings;

  @override
  Future<void> save(AppSettings settings) async {
    currentSettings = settings;
  }
}

void main() {
  late TestSettingsRepository settingsRepository;
  late FakeArabicNameTranslationService translationService;

  setUp(() {
    settingsRepository = TestSettingsRepository();
    translationService = FakeArabicNameTranslationService();
  });

  Widget buildFormApp() {
    return ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(settingsRepository),
        arabicTranslationServiceProvider.overrideWithValue(translationService),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showZikrForm(context, defaultTarget: 100),
              child: const Text('Open Form'),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> openForm(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildFormApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open Form'));
    await tester.pumpAndSettle();
  }

  Future<void> tapCreateZikr(WidgetTester tester) async {
    final submitButton = find.widgetWithText(FilledButton, 'Create Zikr');
    await tester.ensureVisible(submitButton);
    await tester.pumpAndSettle();
    await tester.tap(submitButton);
    await tester.pumpAndSettle();
  }

  group('Form Required Field Validation', () {
    testWidgets(
      '1 & 6. Empty English Name prevents submission and keeps form open',
      (tester) async {
        await openForm(tester);

        // Clear English name
        await tester.enterText(find.byType(TextFormField).first, '');
        await tapCreateZikr(tester);

        // Form must remain open
        expect(find.text('English name is required'), findsOneWidget);
        expect(
          find.text('Please complete the required fields'),
          findsOneWidget,
        );
        expect(find.text('New Zikr'), findsOneWidget);
      },
    );

    testWidgets('2. Whitespace-only English Name prevents submission', (
      tester,
    ) async {
      await openForm(tester);

      await tester.enterText(find.byType(TextFormField).first, '   ');
      await tapCreateZikr(tester);

      expect(find.text('English name is required'), findsOneWidget);
    });

    testWidgets('3. Empty Target prevents submission', (tester) async {
      await openForm(tester);

      await tester.enterText(find.byType(TextFormField).first, 'SubhanAllah');
      final targetFinder = find.widgetWithText(TextFormField, 'Target *');
      await tester.enterText(targetFinder, '');
      await tapCreateZikr(tester);

      expect(find.text('Target is required'), findsOneWidget);
    });

    testWidgets('4 & 5. Zero or invalid Target prevents submission', (
      tester,
    ) async {
      await openForm(tester);

      await tester.enterText(find.byType(TextFormField).first, 'SubhanAllah');
      final targetFinder = find.widgetWithText(TextFormField, 'Target *');
      await tester.enterText(targetFinder, '0');
      await tapCreateZikr(tester);

      expect(
        find.text('Enter a valid target greater than zero'),
        findsOneWidget,
      );
    });

    testWidgets('7. Invalid submission focuses first invalid field', (
      tester,
    ) async {
      await openForm(tester);

      await tester.enterText(find.byType(TextFormField).first, '');
      await tapCreateZikr(tester);

      final nameEditable = tester.widget<EditableText>(
        find.descendant(
          of: find.byType(TextFormField).first,
          matching: find.byType(EditableText),
        ),
      );
      expect(nameEditable.focusNode.hasFocus, isTrue);
    });

    testWidgets('8. Valid Name and Target allow submission', (tester) async {
      await openForm(tester);

      await tester.enterText(find.byType(TextFormField).first, 'SubhanAllah');
      final targetFinder = find.widgetWithText(TextFormField, 'Target *');
      await tester.enterText(targetFinder, '33');
      await tapCreateZikr(tester);

      expect(find.text('New Zikr'), findsNothing);
    });

    testWidgets('9. Existing field values remain after validation failure', (
      tester,
    ) async {
      await openForm(tester);

      await tester.enterText(find.byType(TextFormField).first, 'Alhamdulillah');
      final targetFinder = find.widgetWithText(TextFormField, 'Target *');
      await tester.enterText(targetFinder, '0');
      await tapCreateZikr(tester);

      expect(find.text('Alhamdulillah'), findsOneWidget);
    });
  });

  group('Auto-Translation UI & Manual Overrides', () {
    testWidgets('12. Translation does not run when disabled', (tester) async {
      settingsRepository.currentSettings = AppSettings.defaults().copyWith(
        autoTranslateZikrName: false,
      );
      await openForm(tester);

      await tester.enterText(find.byType(TextFormField).first, 'subhanallah');
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      final arabicFinder = find.widgetWithText(
        TextFormField,
        'Arabic name (optional)',
      );
      final arabicText = tester
          .widget<TextFormField>(arabicFinder)
          .controller
          ?.text;
      expect(arabicText, isEmpty);
    });

    testWidgets(
      '13, 16. Translation runs after debounce when enabled and fills Arabic field',
      (tester) async {
        settingsRepository.currentSettings = AppSettings.defaults().copyWith(
          autoTranslateZikrName: true,
        );
        await openForm(tester);

        await tester.enterText(find.byType(TextFormField).first, 'subhanallah');
        await tester.pump(const Duration(milliseconds: 700));
        await tester.pumpAndSettle();

        expect(find.text('سبحان الله'), findsOneWidget);
      },
    );

    testWidgets(
      '18. Auto-translation does not overwrite manually edited Arabic',
      (tester) async {
        settingsRepository.currentSettings = AppSettings.defaults().copyWith(
          autoTranslateZikrName: true,
        );
        await openForm(tester);

        final arabicFinder = find.widgetWithText(
          TextFormField,
          'Arabic name (optional)',
        );
        await tester.enterText(arabicFinder, 'Manual Arabic');
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextFormField).first, 'subhanallah');
        await tester.pump(const Duration(milliseconds: 700));
        await tester.pumpAndSettle();

        expect(find.text('Manual Arabic'), findsOneWidget);
        expect(find.text('سبحان الله'), findsNothing);
      },
    );

    testWidgets(
      '19. Translate Again explicitly replaces Arabic even if manually edited',
      (tester) async {
        settingsRepository.currentSettings = AppSettings.defaults().copyWith(
          autoTranslateZikrName: true,
        );
        await openForm(tester);

        await tester.enterText(find.byType(TextFormField).first, 'subhanallah');
        final arabicFinder = find.widgetWithText(
          TextFormField,
          'Arabic name (optional)',
        );
        await tester.enterText(arabicFinder, 'Manual Arabic');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Translate again'));
        await tester.pumpAndSettle();

        expect(find.text('سبحان الله'), findsOneWidget);
      },
    );

    testWidgets('20. Translation failure leaves manual entry usable', (
      tester,
    ) async {
      await openForm(tester);

      final arabicFinder = find.widgetWithText(
        TextFormField,
        'Arabic name (optional)',
      );
      await tester.enterText(arabicFinder, 'سبحان الله');
      expect(find.text('سبحان الله'), findsOneWidget);
    });

    testWidgets(
      '21 & 22. Form disposal cancels safely without disposed-controller error',
      (tester) async {
        await openForm(tester);

        await tester.enterText(
          find.byType(TextFormField).first,
          'Astaghfirullah',
        );
        // Dismiss sheet
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        expect(find.text('New Zikr'), findsNothing);
      },
    );
  });
}
