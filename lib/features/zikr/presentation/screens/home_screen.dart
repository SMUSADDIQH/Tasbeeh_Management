import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/islamic_pattern.dart';
import '../../domain/zikr_models.dart';
import '../widgets/zikr_widgets.dart';
import '../zikr_provider.dart';
import 'zikr_details_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({
    required this.onNewZikr,
    required this.onViewHistory,
    super.key,
  });
  final VoidCallback onNewZikr;
  final VoidCallback onViewHistory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(zikrProvider);
    final now = DateTime.now();
    final active = state.zikr
        .where((item) => item.status == ZikrStatus.active)
        .toList();
    final today = state.sessions
        .where(
          (item) =>
              item.timestamp.year == now.year &&
              item.timestamp.month == now.month &&
              item.timestamp.day == now.day,
        )
        .fold<int>(0, (sum, item) => sum + item.amount);
    final target = active.fold<int>(0, (sum, item) => sum + item.target);
    final completed = active.fold<int>(
      0,
      (sum, item) => sum + min(item.completed, item.target),
    );
    final featured = active.isEmpty ? null : active.first;
    return RefreshIndicator(
      onRefresh: ref.read(zikrProvider.notifier).refresh,
      child: CustomScrollView(
        key: const PageStorageKey('home-scroll'),
        slivers: [
          SliverToBoxAdapter(child: _GreetingHeader(date: now)),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            sliver: SliverList.list(
              children: [
                _TodayCard(value: today),
                const SizedBox(height: AppSpacing.lg),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cards = [
                      _MetricCard(
                        icon: Icons.spa_outlined,
                        label: 'Active Zikr',
                        value: '${active.length}',
                      ),
                      _MetricCard(
                        icon: Icons.donut_large_outlined,
                        label: 'Overall Progress',
                        value: target == 0
                            ? '0%'
                            : '${(completed / target * 100).round()}%',
                      ),
                      _StreakCard(ref: ref),
                    ];
                    if (constraints.maxWidth >= 680) {
                      return Row(
                        children: [
                          for (
                            var index = 0;
                            index < cards.length;
                            index++
                          ) ...[
                            Expanded(child: cards[index]),
                            if (index < cards.length - 1)
                              const SizedBox(width: AppSpacing.md),
                          ],
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: cards[0]),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(child: cards[1]),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
                ScreenHeader(
                  title: 'Continue Your Journey',
                  subtitle: 'Steady progress, one session at a time',
                  action: FilledButton.icon(
                    onPressed: onNewZikr,
                    icon: const Icon(Icons.add),
                    label: const Text('New Zikr'),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (featured == null)
                  EmptyJourney(
                    title: 'Begin your journey',
                    message:
                        'Create your first Zikr goal and record completed quantities as sessions.',
                    action: FilledButton.icon(
                      onPressed: onNewZikr,
                      icon: const Icon(Icons.add),
                      label: const Text('New Zikr'),
                    ),
                  )
                else
                  _FeaturedZikr(zikr: featured),
                const SizedBox(height: AppSpacing.xl),
                ScreenHeader(
                  title: 'Recent Activity',
                  subtitle: 'Your latest completed sessions',
                  action: TextButton(
                    onPressed: onViewHistory,
                    child: const Text('View All'),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (state.sessions.isEmpty)
                  const EmptyJourney(
                    title: 'No sessions yet',
                    message: 'Your completed sessions will appear here.',
                  )
                else
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (final session in state.sessions.take(4))
                          if (state.zikr
                                  .where((item) => item.id == session.zikrId)
                                  .firstOrNull
                              case final zikr?)
                            SessionTile(session: session, zikr: zikr),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          MediaQuery.paddingOf(context).top + AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(32),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Directionality(
              textDirection: TextDirection.rtl,
              child: Semantics(
                header: true,
                label: 'Assalamu Alaikum',
                child: Text(
                  'السلام عليكم',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              formatDate(date),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onPrimary.withValues(alpha: 0.82),
              ),
            ),
          ],
        ),
      ),
      const Positioned.fill(child: IslamicPattern(opacity: 0.1)),
    ],
  );
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.value});
  final int value;

  @override
  Widget build(BuildContext context) => AppCard(
    color: Theme.of(context).colorScheme.primaryContainer,
    child: Row(
      children: [
        Icon(
          Icons.auto_awesome_rounded,
          size: 36,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Today’s Completed',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              Text(
                formatQuantity(value),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: AppSpacing.md),
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    ),
  );
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) => FutureBuilder<ReflectionSummary>(
    future: ref.read(zikrProvider.notifier).reflection(ReflectionPeriod.all),
    builder: (context, snapshot) => _MetricCard(
      icon: Icons.local_fire_department_outlined,
      label: 'Longest Streak',
      value: '${snapshot.data?.longestStreak ?? 0} days',
    ),
  );
}

class _FeaturedZikr extends ConsumerWidget {
  const _FeaturedZikr({required this.zikr});
  final Zikr zikr;

  @override
  Widget build(BuildContext context, WidgetRef ref) => AppCard(
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => ZikrDetailsScreen(zikrId: zikr.id),
      ),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) => Flex(
        direction: constraints.maxWidth > 560 ? Axis.horizontal : Axis.vertical,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 132,
            height: 132,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: zikr.progress,
                    strokeWidth: 12,
                    strokeCap: StrokeCap.round,
                    color: Color(zikr.colorValue),
                    backgroundColor: Color(
                      zikr.colorValue,
                    ).withValues(alpha: 0.12),
                    semanticsLabel:
                        '${(zikr.progress * 100).round()} percent complete',
                  ),
                ),
                Text(
                  '${(zikr.progress * 100).round()}%',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xl, height: AppSpacing.lg),
          Expanded(
            flex: constraints.maxWidth > 560 ? 1 : 0,
            child: Column(
              crossAxisAlignment: constraints.maxWidth > 560
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              children: [
                Text(zikr.name, style: Theme.of(context).textTheme.titleLarge),
                if (zikr.arabicName != null)
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      zikr.arabicName!,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  '${formatQuantity(zikr.completed)} Completed · '
                  '${formatQuantity(zikr.remaining)} Remaining',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: () => showSessionForm(context, ref, zikr),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Session'),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
