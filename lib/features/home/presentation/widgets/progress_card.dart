import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import 'progress_ring.dart';

class ProgressCard extends StatelessWidget {
  const ProgressCard({
    required this.tasbeehName,
    required this.currentCount,
    required this.target,
    required this.lastUpdated,
    super.key,
  });

  final String tasbeehName;
  final int currentCount;
  final int target;
  final String lastUpdated;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final safeTarget = target <= 0 ? 1 : target;
    final remaining = (safeTarget - currentCount).clamp(0, safeTarget);

    return AppCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Text(
                'Current Tasbeeh',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                tasbeehName,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              ProgressRing(
                progress: currentCount / safeTarget,
                currentCount: currentCount,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: _ProgressMetric(
                      label: 'Target',
                      value: '$safeTarget',
                    ),
                  ),
                  SizedBox(
                    height: 44,
                    child: VerticalDivider(
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
                  Expanded(
                    child: _ProgressMetric(
                      label: 'Remaining',
                      value: '$remaining',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      'Last updated $lastUpdated',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 500.ms)
        .scale(
          begin: const Offset(0.97, 0.97),
          end: const Offset(1, 1),
          curve: Curves.easeOutCubic,
        );
  }
}

class _ProgressMetric extends StatelessWidget {
  const _ProgressMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(value, style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
