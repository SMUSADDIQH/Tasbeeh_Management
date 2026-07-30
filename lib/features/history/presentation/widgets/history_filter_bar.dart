import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../domain/models/history_filter.dart';

class HistoryFilterBar extends StatelessWidget {
  const HistoryFilterBar({
    required this.selectedFilter,
    required this.onSelected,
    super.key,
  });

  final HistoryFilter selectedFilter;
  final ValueChanged<HistoryFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: HistoryFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          final filter = HistoryFilter.values[index];
          return ChoiceChip(
            label: Text(_label(filter)),
            selected: selectedFilter == filter,
            onSelected: (_) => onSelected(filter),
          );
        },
      ),
    );
  }

  String _label(HistoryFilter filter) {
    return switch (filter) {
      HistoryFilter.today => 'Today',
      HistoryFilter.thisWeek => 'This Week',
      HistoryFilter.thisMonth => 'This Month',
      HistoryFilter.allTime => 'All Time',
    };
  }
}
