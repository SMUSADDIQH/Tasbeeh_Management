import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/section_title.dart';
import '../../domain/models/statistics_models.dart';
import '../providers/statistics_provider.dart';
import '../widgets/statistics_charts.dart';
import '../widgets/statistics_metric_card.dart';
import '../widgets/statistics_period_selector.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(statisticsProvider);
    final notifier = ref.read(statisticsProvider.notifier);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: notifier.refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: AppSpacing.pagePadding,
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionTitle(
                          title: 'Statistics',
                          subtitle:
                              'See your consistency, progress, and momentum.',
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        StatisticsPeriodSelector(
                          selectedPeriod: state.selectedPeriod,
                          onSelected: notifier.selectPeriod,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        if (state.isLoading && state.data == null)
                          const SizedBox(
                            height: 420,
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (state.errorMessage != null &&
                            state.data == null)
                          _StatisticsError(
                            message: state.errorMessage!,
                            onRetry: notifier.refresh,
                          )
                        else if (state.data case final data?)
                          _StatisticsContent(
                            data: data,
                            metrics: state.selectedMetrics!,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatisticsContent extends StatelessWidget {
  const _StatisticsContent({required this.data, required this.metrics});

  final StatisticsData data;
  final StatisticsMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetricsGrid(metrics: metrics),
        const SizedBox(height: AppSpacing.xl),
        Text('Trends', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        _ChartsGrid(data: data),
        const SizedBox(height: AppSpacing.xl),
        Text('Insights', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        for (var index = 0; index < data.insights.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _InsightCard(message: data.insights[index])
                .animate(delay: (index * 80).ms)
                .fadeIn(duration: 320.ms)
                .slideX(begin: 0.04, end: 0),
          ),
      ],
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.metrics});

  final StatisticsMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Total Count', _formatNumber(metrics.totalCount), Icons.tag_rounded),
      (
        'Daily Average',
        _formatNumber(metrics.averageDailyCount.round()),
        Icons.analytics_outlined,
      ),
      (
        'Highest Day',
        _formatNumber(metrics.highestDailyCount),
        Icons.trending_up_rounded,
      ),
      (
        'Lowest Day',
        _formatNumber(metrics.lowestDailyCount),
        Icons.trending_down_rounded,
      ),
      ('Current Streak', '${metrics.currentStreak} days', Icons.bolt_rounded),
      (
        'Longest Streak',
        '${metrics.longestStreak} days',
        Icons.local_fire_department_outlined,
      ),
      (
        'Completion',
        '${metrics.completionPercentage.round()}%',
        Icons.donut_large_rounded,
      ),
      ('Targets Completed', '${metrics.targetsCompleted}', Icons.flag_rounded),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 560
            ? 3
            : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: columns == 2 ? 1.18 : 1.25,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return StatisticsMetricCard(
              label: item.$1,
              value: item.$2,
              icon: item.$3,
            );
          },
        );
      },
    );
  }
}

class _ChartsGrid extends StatelessWidget {
  const _ChartsGrid({required this.data});

  final StatisticsData data;

  @override
  Widget build(BuildContext context) {
    final charts = [
      SevenDayBarChart(points: data.sevenDayCounts),
      MonthlyLineChart(points: data.monthlyCounts),
      WeeklyTrendChart(points: data.weeklyTrend),
      CompletionDonutChart(completion: data.completion),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 840 ? 2 : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: charts.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            mainAxisExtent: 340,
          ),
          itemBuilder: (context, index) => charts[index],
        );
      },
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: 'Insight. $message',
      child: ExcludeSemantics(
        child: AppCard(
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiaryContainer,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(AppRadius.md),
                  ),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: theme.colorScheme.onTertiaryContainer,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(message, style: theme.textTheme.bodyLarge)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatisticsError extends StatelessWidget {
  const _StatisticsError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 360,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: AppSpacing.md),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

String _formatNumber(int value) {
  final digits = value.toString();
  final formatted = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    final positionFromEnd = digits.length - index;
    formatted.write(digits[index]);
    if (positionFromEnd > 1 && positionFromEnd % 3 == 1) {
      formatted.write(',');
    }
  }
  return formatted.toString();
}
