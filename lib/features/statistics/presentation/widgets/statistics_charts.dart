import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/models/statistics_models.dart';

class SevenDayBarChart extends StatelessWidget {
  const SevenDayBarChart({required this.points, super.key});

  final List<DailyCountPoint> points;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxCount = points.fold<int>(
      0,
      (maximum, point) => point.count > maximum ? point.count : maximum,
    );

    return _ChartCard(
      title: 'Last 7 Days',
      semanticLabel:
          'Seven day count bar chart. Total ${points.fold<int>(0, (sum, point) => sum + point.count)}.',
      child: BarChart(
        BarChartData(
          maxY: (maxCount <= 0 ? 1 : maxCount * 1.2).toDouble(),
          alignment: BarChartAlignment.spaceAround,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= points.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      _weekdayShort(points[index].date.weekday),
                      style: theme.textTheme.labelSmall,
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var index = 0; index < points.length; index++)
              BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: points[index].count.toDouble(),
                    width: 16,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6),
                    ),
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class MonthlyLineChart extends StatelessWidget {
  const MonthlyLineChart({required this.points, super.key});

  final List<DailyCountPoint> points;

  @override
  Widget build(BuildContext context) {
    return _LineChartCard(
      title: 'This Month',
      semanticLabel:
          'Monthly daily count line chart with ${points.length} days.',
      spots: [
        for (var index = 0; index < points.length; index++)
          FlSpot((index + 1).toDouble(), points[index].count.toDouble()),
      ],
      bottomLabel: (value) {
        final day = value.toInt();
        return day == 1 || day % 7 == 0 ? '$day' : '';
      },
    );
  }
}

class WeeklyTrendChart extends StatelessWidget {
  const WeeklyTrendChart({required this.points, super.key});

  final List<WeeklyCountPoint> points;

  @override
  Widget build(BuildContext context) {
    return _LineChartCard(
      title: 'Weekly Trend',
      semanticLabel:
          'Eight week trend chart. Latest week ${points.isEmpty ? 0 : points.last.count} counts.',
      spots: [
        for (var index = 0; index < points.length; index++)
          FlSpot(index.toDouble(), points[index].count.toDouble()),
      ],
      bottomLabel: (value) {
        final index = value.toInt();
        if (index < 0 || index >= points.length || index.isOdd) {
          return '';
        }
        final date = points[index].weekStart;
        return '${date.month}/${date.day}';
      },
    );
  }
}

class CompletionDonutChart extends StatelessWidget {
  const CompletionDonutChart({required this.completion, super.key});

  final CompletionBreakdown completion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = (completion.percentage * 100).round();

    return _ChartCard(
      title: 'Target Completion',
      semanticLabel:
          'Target completion donut chart. $percentage percent completed, '
          '${completion.completed} completed days.',
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              centerSpaceRadius: 56,
              sectionsSpace: AppSpacing.xxs,
              startDegreeOffset: -90,
              sections: [
                PieChartSectionData(
                  value: completion.completed.toDouble(),
                  color: theme.colorScheme.primary,
                  radius: 28,
                  showTitle: false,
                ),
                PieChartSectionData(
                  value: completion.notCompleted.toDouble(),
                  color: theme.colorScheme.surfaceContainerHighest,
                  radius: 24,
                  showTitle: false,
                ),
                if (completion.total == 0)
                  PieChartSectionData(
                    value: 1,
                    color: theme.colorScheme.surfaceContainerHighest,
                    radius: 24,
                    showTitle: false,
                  ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$percentage%', style: theme.textTheme.headlineSmall),
              Text(
                'completed',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LineChartCard extends StatelessWidget {
  const _LineChartCard({
    required this.title,
    required this.semanticLabel,
    required this.spots,
    required this.bottomLabel,
  });

  final String title;
  final String semanticLabel;
  final List<FlSpot> spots;
  final String Function(double value) bottomLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxY = spots.fold<double>(
      0,
      (maximum, spot) => spot.y > maximum ? spot.y : maximum,
    );

    return _ChartCard(
      title: title,
      semanticLabel: semanticLabel,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY <= 0 ? 1 : maxY * 1.2,
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: theme.colorScheme.outlineVariant, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: true),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      bottomLabel(value),
                      style: theme.textTheme.labelSmall,
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: theme.colorScheme.primary,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.semanticLabel,
    required this.child,
  });

  final String title;
  final String semanticLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: Semantics(
              image: true,
              label: semanticLabel,
              child: ExcludeSemantics(child: child),
            ),
          ),
        ],
      ),
    );
  }
}

String _weekdayShort(int weekday) {
  return const ['M', 'T', 'W', 'T', 'F', 'S', 'S'][weekday - 1];
}
