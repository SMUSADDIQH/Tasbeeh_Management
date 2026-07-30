import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../domain/models/statistics_models.dart';

class StatisticsPeriodSelector extends StatelessWidget {
  const StatisticsPeriodSelector({
    required this.selectedPeriod,
    required this.onSelected,
    super.key,
  });

  final StatisticsPeriod selectedPeriod;
  final ValueChanged<StatisticsPeriod> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: StatisticsPeriod.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          final period = StatisticsPeriod.values[index];
          return ChoiceChip(
            label: Text(_label(period)),
            selected: selectedPeriod == period,
            onSelected: (_) => onSelected(period),
          );
        },
      ),
    );
  }

  String _label(StatisticsPeriod period) {
    return switch (period) {
      StatisticsPeriod.today => 'Today',
      StatisticsPeriod.yesterday => 'Yesterday',
      StatisticsPeriod.thisWeek => 'This Week',
      StatisticsPeriod.thisMonth => 'This Month',
      StatisticsPeriod.thisYear => 'This Year',
      StatisticsPeriod.lifetime => 'Lifetime',
    };
  }
}
