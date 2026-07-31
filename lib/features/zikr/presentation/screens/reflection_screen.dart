import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_segmented_control.dart';
import '../../domain/zikr_models.dart';
import '../widgets/zikr_widgets.dart';
import '../zikr_provider.dart';

class ReflectionScreen extends ConsumerStatefulWidget {
  const ReflectionScreen({super.key, this.scrollController});
  final ScrollController? scrollController;

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
      controller: widget.scrollController,
      key: const PageStorageKey('reflection-scroll'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        120,
      ),
      children: [
        ScreenHeader(
          title: 'Reflection',
          subtitle: 'Your spiritual journey insights',
          action: IconButton.filledTonal(
            tooltip: 'Choose period',
            onPressed: () {},
            icon: const Icon(Icons.calendar_today_rounded),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppSegmentedControl<ReflectionPeriod>(
          isDarkBackground: true,
          tabs: const [
            AppSegmentedTab(value: ReflectionPeriod.today, label: 'Today'),
            AppSegmentedTab(value: ReflectionPeriod.week, label: 'Week'),
            AppSegmentedTab(value: ReflectionPeriod.month, label: 'Month'),
            AppSegmentedTab(value: ReflectionPeriod.year, label: 'Year'),
            AppSegmentedTab(value: ReflectionPeriod.all, label: 'All'),
          ],
          selected: _period,
          onChanged: (value) => setState(() => _period = value),
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
            final activeZikrs = zikr
                .where((z) => z.status == ZikrStatus.active)
                .toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Monthly Overview Card
                AppCard(
                  color: AppColors.darkCardBg,
                  borderColor: AppColors.gold,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monthly Overview',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppColors.goldBright,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        'July 2025',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Completed',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.auto_awesome_rounded,
                                      size: 14,
                                      color: AppColors.goldBright,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      formatQuantity(data.total),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            color: AppColors.ivory,
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Average / Day',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  formatQuantity(data.averagePerActiveDay),
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        color: AppColors.ivory,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Best Day',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  data.bestDay == null
                                      ? '—'
                                      : formatDate(data.bestDay!),
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: AppColors.goldBright,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Completion %',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${(data.overallCompletion * 100).round()}% (All Zikr)',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: AppColors.success,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const SizedBox(height: AppSpacing.lg),
                // Progress Over Time smooth line chart card
                _ProgressLineChartCard(
                  values: data.weeklyTotals,
                  total: data.total,
                ),
                const SizedBox(height: AppSpacing.lg),
                // Closest to Completion Section
                if (activeZikrs.isNotEmpty) ...[
                  Text(
                    'Closest to Completion',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.goldBright,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  for (final item in activeZikrs.take(2)) ...[
                    AppCard(
                      color: AppColors.darkCardBg,
                      borderColor: AppColors.goldMuted.withValues(alpha: 0.3),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            color: AppColors.ivory,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    if (item.arabicName != null)
                                      Directionality(
                                        textDirection: TextDirection.rtl,
                                        child: Text(
                                          item.arabicName!,
                                          style: AppTypography.arabicScript(
                                            color: AppColors.goldBright,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${formatQuantity(item.remaining)} to go',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                  Text(
                                    '${(item.progress * 100).round()}%',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          color: Color(item.colorValue),
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: item.progress,
                              minHeight: 6,
                              color: Color(item.colorValue),
                              backgroundColor: Color(
                                item.colorValue,
                              ).withValues(alpha: 0.15),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  const SizedBox(height: AppSpacing.md),
                ],
                // Spiritual Reminder Quranic Calligraphy Card
                AppCard(
                  color: AppColors.emerald900,
                  borderColor: AppColors.gold,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Spiritual Reminder',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.goldBright,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(
                          'وَاذْكُرْ رَبَّكَ كَثِيرًا',
                          style: AppTypography.arabicScript(
                            color: AppColors.goldGlow,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '"And remember Allah with much remembrance."',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.ivory.withValues(alpha: 0.9),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      Text(
                        '(Al-Ahzab 33:41)',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.gold.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ProgressLineChartCard extends StatelessWidget {
  const _ProgressLineChartCard({required this.values, required this.total});

  final List<int> values;
  final int total;

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    for (var i = 0; i < values.length; i++) {
      spots.add(FlSpot(i.toDouble(), values[i].toDouble()));
    }
    final maxY = values.isEmpty
        ? 10.0
        : (values.reduce((a, b) => a > b ? a : b) * 1.2).clamp(10.0, 100000.0);

    return Semantics(
      image: true,
      label:
          'Weekly completed sessions chart. Total ${formatQuantity(total)}. '
          'Monday through Sunday: ${values.map(formatQuantity).join(', ')}.',
      child: AppCard(
        color: AppColors.darkCardBg,
        borderColor: AppColors.goldMuted.withValues(alpha: 0.3),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Progress Over Time',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.goldBright,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.emerald850,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.goldMuted.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'Last 7 Days',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.goldBright,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 180,
              child: ExcludeSemantics(
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: AppColors.goldMuted.withValues(alpha: 0.12),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(),
                      rightTitles: const AxisTitles(),
                      leftTitles: const AxisTitles(),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 24,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            const labels = [
                              '1 Jul',
                              '8 Jul',
                              '15 Jul',
                              '22 Jul',
                              '29 Jul',
                              '30 Jul',
                              '31 Jul',
                            ];
                            final idx = value.toInt().clamp(
                              0,
                              labels.length - 1,
                            );
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                labels[idx],
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: (spots.length - 1).toDouble(),
                    minY: 0,
                    maxY: maxY,
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        curveSmoothness: 0.35,
                        color: AppColors.goldBright,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: AppColors.goldBright,
                              strokeWidth: 2,
                              strokeColor: AppColors.emerald950,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.goldBright.withValues(alpha: 0.32),
                              AppColors.gold.withValues(alpha: 0.05),
                            ],
                          ),
                        ),
                      ),
                    ],
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
