import 'package:flutter/material.dart';

class ProgressRing extends StatelessWidget {
  const ProgressRing({
    required this.progress,
    required this.progressPercent,
    required this.currentCount,
    this.size = 190,
    super.key,
  });

  final double progress;
  final int progressPercent;
  final int currentCount;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final normalizedProgress = progress.clamp(0.0, 1.0);

    return Semantics(
      label: 'Tasbeeh progress',
      value: '${(normalizedProgress * 100).round()} percent',
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 1200),
        curve: Curves.easeOutCubic,
        tween: Tween(end: normalizedProgress),
        builder: (context, value, _) {
          return SizedBox.square(
            dimension: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: value,
                    strokeWidth: 14,
                    strokeCap: StrokeCap.round,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$currentCount',
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      '$progressPercent%',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
