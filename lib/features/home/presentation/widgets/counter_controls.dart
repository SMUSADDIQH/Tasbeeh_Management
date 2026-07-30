import 'package:flutter/material.dart';

import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/secondary_button.dart';

class CounterControls extends StatelessWidget {
  const CounterControls({
    required this.onIncrement,
    required this.onContinuousCountStart,
    required this.onContinuousCountEnd,
    required this.onUndo,
    required this.onReset,
    required this.onSetTarget,
    required this.canUndo,
    super.key,
  });

  final VoidCallback onIncrement;
  final VoidCallback onContinuousCountStart;
  final VoidCallback onContinuousCountEnd;
  final VoidCallback? onUndo;
  final VoidCallback onReset;
  final VoidCallback onSetTarget;
  final bool canUndo;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CountButton(
          onTap: onIncrement,
          onLongPressStart: onContinuousCountStart,
          onLongPressEnd: onContinuousCountEnd,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: SecondaryButton(
                label: 'Undo',
                icon: Icons.undo_rounded,
                onPressed: canUndo ? onUndo : null,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: SecondaryButton(
                label: 'Reset',
                icon: Icons.refresh_rounded,
                onPressed: onReset,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: SecondaryButton(
                label: 'Target',
                icon: Icons.flag_outlined,
                onPressed: onSetTarget,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CountButton extends StatelessWidget {
  const _CountButton({
    required this.onTap,
    required this.onLongPressStart,
    required this.onLongPressEnd,
  });

  final VoidCallback onTap;
  final VoidCallback onLongPressStart;
  final VoidCallback onLongPressEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: 'Add one Tasbeeh count',
      hint: 'Tap once or hold for continuous counting',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPressStart: (_) => onLongPressStart(),
        onLongPressEnd: (_) => onLongPressEnd(),
        onLongPressCancel: onLongPressEnd,
        child: Material(
          color: theme.colorScheme.primary,
          borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xl)),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: double.infinity,
            height: 112,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '+1',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Tap to count · Hold to continue',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
