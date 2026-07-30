import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/zikr_models.dart';
import '../widgets/zikr_widgets.dart';
import '../zikr_provider.dart';

class ReflectionScreen extends ConsumerStatefulWidget {
  const ReflectionScreen({super.key});

  @override
  ConsumerState<ReflectionScreen> createState() => _ReflectionScreenState();
}

class _ReflectionScreenState extends ConsumerState<ReflectionScreen> {
  ReflectionPeriod _period = ReflectionPeriod.month;
  String? _zikrId;

  @override
  Widget build(BuildContext context) {
    final revision = ref.watch(zikrProvider.select((state) => state.revision));
    final zikr = ref.watch(zikrProvider.select((state) => state.zikr));
    return ListView(
      key: const PageStorageKey('reflection-scroll'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const ScreenHeader(
          title: 'Reflection',
          subtitle: 'Your spiritual journey insights',
        ),
        const SizedBox(height: AppSpacing.lg),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<ReflectionPeriod>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: ReflectionPeriod.today,
                label: Text('Today'),
              ),
              ButtonSegment(value: ReflectionPeriod.week, label: Text('Week')),
              ButtonSegment(
                value: ReflectionPeriod.month,
                label: Text('Month'),
              ),
              ButtonSegment(value: ReflectionPeriod.year, label: Text('Year')),
              ButtonSegment(value: ReflectionPeriod.all, label: Text('All')),
            ],
            selected: {_period},
            onSelectionChanged: (value) =>
                setState(() => _period = value.first),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<String?>(
          initialValue: _zikrId,
          decoration: const InputDecoration(labelText: 'Reflect on'),
          items: [
            const DropdownMenuItem(value: null, child: Text('All Zikr')),
            for (final item in zikr)
              DropdownMenuItem(value: item.id, child: Text(item.name)),
          ],
          onChanged: (value) => setState(() => _zikrId = value),
        ),
        const SizedBox(height: AppSpacing.lg),
        FutureBuilder<ReflectionSummary>(
          key: ValueKey('$revision:${_period.name}:$_zikrId'),
          future: ref
              .read(zikrProvider.notifier)
              .reflection(_period, zikrId: _zikrId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xxl),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            final data = snapshot.data!;
            return Column(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth >= 760
                        ? (constraints.maxWidth - AppSpacing.md * 2) / 3
                        : (constraints.maxWidth - AppSpacing.md) / 2;
                    return Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.md,
                      children: [
                        _ReflectionMetric(
                          width: width,
                          label: 'Total Completed',
                          value: formatQuantity(data.total),
                          icon: Icons.auto_awesome_outlined,
                        ),
                        _ReflectionMetric(
                          width: width,
                          label: 'Average per active day',
                          value: formatQuantity(data.averagePerActiveDay),
                          icon: Icons.calendar_today_outlined,
                        ),
                        _ReflectionMetric(
                          width: width,
                          label: 'Best Day',
                          value: data.bestDay == null
                              ? '—'
                              : weekdayName(data.bestDay!),
                          icon: Icons.workspace_premium_outlined,
                        ),
                        _ReflectionMetric(
                          width: width,
                          label: 'Overall Completion',
                          value:
                              '${(data.overallCompletion * 100).toStringAsFixed(1)}%',
                          icon: Icons.donut_large_outlined,
                        ),
                        _ReflectionMetric(
                          width: width,
                          label: 'Current Streak',
                          value: '${data.currentStreak} days',
                          icon: Icons.local_fire_department_outlined,
                        ),
                        _ReflectionMetric(
                          width: width,
                          label: 'Longest Streak',
                          value: '${data.longestStreak} days',
                          icon: Icons.timeline_outlined,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                _WeeklyChart(values: data.weeklyTotals),
                const SizedBox(height: AppSpacing.lg),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Journey Highlights',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _Highlight(
                        label: 'Closest Zikr to Completion',
                        value: data.closestZikr?.name ?? 'Begin an active Zikr',
                      ),
                      _Highlight(
                        label: 'Most Active Zikr',
                        value: data.mostActiveZikr?.name ?? 'No activity yet',
                      ),
                      _Highlight(
                        label: 'Projected Completion',
                        value: data.projectedCompletion == null
                            ? 'More sessions are needed'
                            : formatDate(data.projectedCompletion!),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppCard(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  child: Row(
                    children: [
                      Icon(
                        Icons.spa_outlined,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSecondaryContainer,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      const Expanded(
                        child: Text(
                          'Small, consistent acts can shape a lasting journey.',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ReflectionMetric extends StatelessWidget {
  const _ReflectionMetric({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
  });
  final double width;
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: AppSpacing.md),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    ),
  );
}

class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({required this.values});
  final List<int> values;

  @override
  Widget build(BuildContext context) {
    final total = values.fold<int>(0, (sum, item) => sum + item);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Consistency',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          Semantics(
            image: true,
            label:
                'Weekly completed sessions chart. Total ${formatQuantity(total)}. '
                'Monday through Sunday: ${values.map(formatQuantity).join(', ')}.',
            child: ExcludeSemantics(
              child: SizedBox(
                height: 210,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(),
                      rightTitles: const AxisTitles(),
                      leftTitles: const AxisTitles(),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) => Text(
                            const ['M', 'T', 'W', 'T', 'F', 'S', 'S'][value
                                .toInt()
                                .clamp(0, 6)],
                          ),
                        ),
                      ),
                    ),
                    barGroups: [
                      for (var index = 0; index < values.length; index++)
                        BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: values[index].toDouble(),
                              width: 18,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Highlight extends StatelessWidget {
  const _Highlight({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        const SizedBox(width: AppSpacing.md),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
      ],
    ),
  );
}
