import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tasbeeh_tracker/core/widgets/section_title.dart';
import 'package:tasbeeh_tracker/features/history/domain/models/counter_history_entry.dart';
import 'package:tasbeeh_tracker/features/history/presentation/widgets/history_entry_card.dart';
import 'package:tasbeeh_tracker/features/home/presentation/widgets/counter_controls.dart';
import 'package:tasbeeh_tracker/features/settings/presentation/widgets/settings_section.dart';
import 'package:tasbeeh_tracker/features/statistics/domain/models/statistics_models.dart';
import 'package:tasbeeh_tracker/features/statistics/presentation/widgets/statistics_charts.dart';

void main() {
  testWidgets('section title exposes a semantic header', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SectionTitle(title: 'Statistics')),
      ),
    );

    expect(
      tester.getSemantics(find.text('Statistics')),
      matchesSemantics(label: 'Statistics', isHeader: true),
    );
    semantics.dispose();
  });

  testWidgets('history entry announces action and count transition', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final entry = CounterHistoryEntry(
      action: CounterHistoryAction.increment,
      timestamp: DateTime(2026, 7, 30, 9, 42),
      previousCount: 4,
      newCount: 5,
      target: 100,
      todayCount: 5,
      lifetimeCount: 50,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: HistoryEntryCard(entry: entry)),
      ),
    );

    expect(
      find.bySemanticsLabel(
        RegExp(r'Increment at .* Previous count 4\. New count 5\.'),
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('counter exposes value, action, and long-press hint', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CounterControls(
            count: 42,
            hapticsEnabled: false,
            animationsEnabled: false,
            onIncrement: () {},
            onContinuousCountStart: () {},
            onContinuousCountEnd: () {},
            onUndo: () {},
            onReset: () {},
            onSetTarget: () {},
            canUndo: true,
            canReset: true,
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Tasbeeh counter'), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Tasbeeh counter')),
      matchesSemantics(
        label: 'Tasbeeh counter',
        value: '42',
        hint: 'Double tap to add one. Touch and hold for continuous counting.',
        hasTapAction: true,
        hasLongPressAction: true,
        isButton: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('charts and settings sections provide semantic containers', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              SizedBox(
                height: 340,
                child: SevenDayBarChart(
                  points: [
                    DailyCountPoint(date: DateTime(2026, 7, 30), count: 10),
                  ],
                ),
              ),
              const SettingsSection(
                title: 'Appearance',
                children: [ListTile(title: Text('System Theme'))],
              ),
            ],
          ),
        ),
      ),
    );

    expect(
      find.bySemanticsLabel(RegExp('Seven day count bar chart.*Total 10')),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('Appearance'),
      200,
      scrollable: find.byType(Scrollable),
    );
    await tester.pump();
    expect(
      find.bySemanticsLabel(RegExp('Appearance settings')),
      findsOneWidget,
    );
    semantics.dispose();
  });
}
