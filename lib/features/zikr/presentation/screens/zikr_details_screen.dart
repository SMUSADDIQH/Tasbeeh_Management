import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/zikr_models.dart';
import '../widgets/zikr_widgets.dart';
import '../zikr_provider.dart';

class ZikrDetailsScreen extends ConsumerWidget {
  const ZikrDetailsScreen({required this.zikrId, super.key});
  final String zikrId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(zikrProvider);
    final zikr = state.zikr.where((item) => item.id == zikrId).firstOrNull;
    if (zikr == null) {
      return const Scaffold(body: Center(child: Text('Zikr not found.')));
    }
    final sessions = state.sessions
        .where((session) => session.zikrId == zikrId)
        .toList();
    final now = DateTime.now();
    final today = sessions
        .where(
          (item) =>
              item.timestamp.year == now.year &&
              item.timestamp.month == now.month &&
              item.timestamp.day == now.day,
        )
        .fold<int>(0, (sum, item) => sum + item.amount);
    final weekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final weekly = sessions
        .where((item) => !item.timestamp.isBefore(weekStart))
        .fold<int>(0, (sum, item) => sum + item.amount);
    final activeDays = sessions
        .map(
          (item) => DateTime(
            item.timestamp.year,
            item.timestamp.month,
            item.timestamp.day,
          ),
        )
        .toSet()
        .length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zikr Details'),
        actions: [
          IconButton(
            tooltip: zikr.isFavorite
                ? 'Remove from favorites'
                : 'Add to favorites',
            onPressed: () =>
                ref.read(zikrProvider.notifier).toggleFavorite(zikr.id),
            icon: Icon(
              zikr.isFavorite ? Icons.star_rounded : Icons.star_outline,
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'edit') {
                final draft = await showZikrForm(
                  context,
                  existing: zikr,
                  defaultTarget: zikr.target,
                );
                if (draft != null) {
                  await ref.read(zikrProvider.notifier).edit(zikr.id, draft);
                }
              } else if (value == 'archive') {
                await ref
                    .read(zikrProvider.notifier)
                    .setArchived(zikr.id, zikr.status != ZikrStatus.archived);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(
                value: 'archive',
                child: Text(
                  zikr.status == ZikrStatus.archived ? 'Restore' : 'Archive',
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: zikr.status == ZikrStatus.archived
          ? null
          : FloatingActionButton.extended(
              onPressed: () => showSessionForm(context, ref, zikr),
              icon: const Icon(Icons.add),
              label: const Text('Add Session'),
            ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AppCard(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Color(
                    zikr.colorValue,
                  ).withValues(alpha: 0.15),
                  child: Icon(
                    zikrIcon(zikr.iconCodePoint),
                    size: 32,
                    color: Color(zikr.colorValue),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Semantics(
                  header: true,
                  child: Text(
                    zikr.name,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                if (zikr.arabicName != null)
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      zikr.arabicName!,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                if (zikr.description != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(zikr.description!, textAlign: TextAlign.center),
                ],
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: 176,
                  height: 176,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: zikr.progress,
                          strokeWidth: 16,
                          strokeCap: StrokeCap.round,
                          color: Color(zikr.colorValue),
                          backgroundColor: Color(
                            zikr.colorValue,
                          ).withValues(alpha: 0.12),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(zikr.progress * 100).toStringAsFixed(1)}%',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const Text('Completed'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppSpacing.xl,
                  runSpacing: AppSpacing.md,
                  children: [
                    _DetailValue(
                      label: 'Completed',
                      value: formatQuantity(zikr.completed),
                    ),
                    _DetailValue(
                      label: 'Target',
                      value: formatQuantity(zikr.target),
                    ),
                    _DetailValue(
                      label: 'Remaining',
                      value: formatQuantity(zikr.remaining),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              _Insight(
                label: 'Today’s Completed',
                value: formatQuantity(today),
              ),
              _Insight(
                label: 'Weekly Completed',
                value: formatQuantity(weekly),
              ),
              _Insight(
                label: 'Average per active day',
                value: activeDays == 0
                    ? '0'
                    : formatQuantity(zikr.completed / activeDays),
              ),
            ],
          ),
          if (zikr.notes != null) ...[
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.notes_outlined),
                title: const Text('Notes'),
                subtitle: Text(zikr.notes!),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          ScreenHeader(
            title: 'Session History',
            subtitle: 'Recent progress for this Zikr',
            action: sessions.isEmpty
                ? null
                : TextButton(
                    onPressed: () async {
                      final confirmed = await showConfirmDialog(
                        context,
                        title: 'Undo latest session?',
                        message: 'The most recent session will be removed.',
                        confirmLabel: 'Undo',
                      );
                      if (confirmed) {
                        await ref
                            .read(zikrProvider.notifier)
                            .undoLatest(zikr.id);
                      }
                    },
                    child: const Text('Undo latest'),
                  ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (sessions.isEmpty)
            const EmptyJourney(
              title: 'No sessions yet',
              message: 'Add a completed quantity to begin your progress.',
            )
          else
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final session in sessions.take(10))
                    SessionTile(
                      session: session,
                      zikr: zikr,
                      onEdit: () => showSessionForm(
                        context,
                        ref,
                        zikr,
                        existing: session,
                      ),
                      onDelete: () async {
                        final confirmed = await showConfirmDialog(
                          context,
                          title: 'Delete session?',
                          message: 'The Zikr total will be recalculated.',
                          confirmLabel: 'Delete',
                          destructive: true,
                        );
                        if (confirmed) {
                          await ref
                              .read(zikrProvider.notifier)
                              .deleteSession(session.id);
                        }
                      },
                    ),
                ],
              ),
            ),
          const SizedBox(height: 96),
        ],
      ),
    );
  }
}

class _DetailValue extends StatelessWidget {
  const _DetailValue({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: Theme.of(context).textTheme.titleLarge),
      Text(label, style: Theme.of(context).textTheme.labelSmall),
    ],
  );
}

class _Insight extends StatelessWidget {
  const _Insight({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 190,
    child: AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    ),
  );
}
