import 'package:flutter/material.dart';

import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/models/counter_history_entry.dart';

class HistoryEntryCard extends StatelessWidget {
  const HistoryEntryCard({required this.entry, super.key});

  final CounterHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = MaterialLocalizations.of(context);
    final time = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(entry.timestamp.toLocal()),
    );
    final actionLabel = _actionLabel(entry.action);

    return Semantics(
      container: true,
      label:
          '$actionLabel at $time. Previous count ${entry.previousCount}. '
          'New count ${entry.newCount}.',
      child: ExcludeSemantics(
        child: AppCard(
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(AppRadius.md),
                  ),
                ),
                child: Icon(
                  _actionIcon(entry.action),
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            actionLabel,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        Text(
                          time,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        _CountValue(
                          label: 'Previous',
                          value: entry.previousCount,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        _CountValue(label: 'New', value: entry.newCount),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _actionLabel(CounterHistoryAction action) {
    return switch (action) {
      CounterHistoryAction.increment => 'Increment',
      CounterHistoryAction.undo => 'Undo',
      CounterHistoryAction.reset => 'Reset',
      CounterHistoryAction.targetChanged => 'Target Changed',
      CounterHistoryAction.dailyRollover => 'Daily Rollover',
    };
  }

  IconData _actionIcon(CounterHistoryAction action) {
    return switch (action) {
      CounterHistoryAction.increment => Icons.add_rounded,
      CounterHistoryAction.undo => Icons.undo_rounded,
      CounterHistoryAction.reset => Icons.refresh_rounded,
      CounterHistoryAction.targetChanged => Icons.flag_outlined,
      CounterHistoryAction.dailyRollover => Icons.calendar_today_rounded,
    };
  }
}

class _CountValue extends StatelessWidget {
  const _CountValue({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$value', style: theme.textTheme.titleMedium),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
