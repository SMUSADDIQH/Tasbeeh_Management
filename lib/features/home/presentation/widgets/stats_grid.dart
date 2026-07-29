import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../app/theme/app_spacing.dart';
import 'stats_card.dart';

class StatsGrid extends StatelessWidget {
  const StatsGrid({
    required this.todayCount,
    required this.lifetimeCount,
    super.key,
  });

  final int todayCount;
  final int lifetimeCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 560 ? 2 : 1;
        final aspectRatio = columns == 1 ? 2.35 : 1.25;

        return GridView.count(
          crossAxisCount: columns,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: aspectRatio,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children:
              [
                    StatsCard(
                      label: "Today's Count",
                      value: '$todayCount',
                      icon: Icons.today_rounded,
                    ),
                    StatsCard(
                      label: 'Lifetime Count',
                      value: _formatCount(lifetimeCount),
                      icon: Icons.all_inclusive_rounded,
                    ),
                  ]
                  .animate(interval: 100.ms)
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.08, end: 0),
        );
      },
    );
  }

  String _formatCount(int count) {
    final digits = count.toString();
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
}
