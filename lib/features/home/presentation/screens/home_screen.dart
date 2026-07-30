import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/section_title.dart';
import '../providers/counter_provider.dart';
import '../widgets/counter_controls.dart';
import '../widgets/custom_target_dialog.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/progress_card.dart';
import '../widgets/stats_grid.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counter = ref.watch(counterProvider);
    final notifier = ref.read(counterProvider.notifier);
    final lastUpdated = _lastUpdatedLabel(context, counter.lastUpdated);
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: isLandscape ? AppSpacing.md : AppSpacing.lg,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const DashboardHeader(
                        greeting: 'Assalamu Alaikum',
                        subtitle: 'May every remembrance bring you peace.',
                      )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: -0.08, end: 0),
                  const SizedBox(height: AppSpacing.xl),
                  const SectionTitle(
                    title: 'Your Dhikr',
                    subtitle: 'Stay present. Keep your heart connected.',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final progressCard = ProgressCard(
                        tasbeehName: counter.tasbeehName,
                        currentCount: counter.currentCount,
                        target: counter.target,
                        remaining: counter.remaining,
                        progress: counter.progress,
                        progressPercent: counter.progressPercent,
                        lastUpdated: lastUpdated,
                      );
                      final controls = CounterControls(
                        count: counter.currentCount,
                        onIncrement: notifier.increment,
                        onContinuousCountStart: notifier.startContinuousCount,
                        onContinuousCountEnd: notifier.stopContinuousCount,
                        onUndo: notifier.undo,
                        onReset: notifier.reset,
                        onSetTarget: () => _showTargetDialog(
                          context,
                          counter.target,
                          notifier.setCustomTarget,
                        ),
                        canUndo: counter.canUndo,
                        canReset: counter.currentCount > 0,
                      );
                      final statsGrid = StatsGrid(
                        todayCount: counter.todayCount,
                        lifetimeCount: counter.lifetimeCount,
                      );

                      if (constraints.maxWidth < 760) {
                        return Column(
                          children: [
                            progressCard,
                            SizedBox(height: AppSpacing.md),
                            controls,
                            SizedBox(height: AppSpacing.lg),
                            statsGrid,
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: Column(
                              children: [
                                progressCard,
                                const SizedBox(height: AppSpacing.md),
                                controls,
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(flex: 4, child: statsGrid),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _lastUpdatedLabel(BuildContext context, DateTime? lastUpdated) {
    if (lastUpdated == null) {
      return 'never';
    }

    final localizations = MaterialLocalizations.of(context);
    final local = lastUpdated.toLocal();
    final now = DateTime.now();
    final time = localizations.formatTimeOfDay(TimeOfDay.fromDateTime(local));
    final isToday =
        local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;

    if (isToday) {
      return 'today at $time';
    }

    return '${localizations.formatCompactDate(local)} at $time';
  }

  Future<void> _showTargetDialog(
    BuildContext context,
    int currentTarget,
    bool Function(String value) onSubmit,
  ) {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return CustomTargetDialog(
          currentTarget: currentTarget,
          onSubmit: onSubmit,
        );
      },
    );
  }
}
