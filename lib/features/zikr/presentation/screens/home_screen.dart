import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/hijri_date_utils.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/islamic_artwork.dart';
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
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
            ),
            sliver: SliverList.list(
              children: [
                _TodayCard(value: today, date: now),
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
                    if (constraints.maxWidth >= 600) {
                      return Row(
                        children: [
                          for (var index = 0; index < cards.length; index++) ...[
                            Expanded(child: cards[index]),
                            if (index < cards.length - 1)
                              const SizedBox(width: AppSpacing.sm),
                          ],
                        ],
                      );
                    }
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: cards[0]),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(child: cards[1]),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        SizedBox(
                          width: double.infinity,
                          child: cards[2],
                        ),
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
                    color: AppColors.darkCardBg,
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
class _GreetingHeader extends ConsumerWidget {
  const _GreetingHeader({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hijriStr = HijriDateUtils.formatHijriDate(date);
    final gregorianStr = formatDate(date);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.emerald950,
            AppColors.emerald900,
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppColors.goldMuted.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: const GreetingHeaderBackgroundWidget(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
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
                          Semantics(
                            header: true,
                            label: 'Assalamu Alaikum',
                            child: Directionality(
                              textDirection: TextDirection.rtl,
                              child: Text(
                                'السلام عليكم',
                                style: AppTypography.arabicGreeting(
                                  color: AppColors.goldBright,
                                  fontSize: 38,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Peace be upon you',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppColors.gold.withValues(alpha: 0.9),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const IslamicAppLogo(size: 48, borderRadius: 13),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.emerald850.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.goldMuted.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_month_outlined,
                        size: 15,
                        color: AppColors.goldBright,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '$gregorianStr / $hijriStr',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppColors.ivory,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.value, required this.date});
  final int value;
  final DateTime date;

  @override
  Widget build(BuildContext context) => AppCard(
    color: AppColors.lightCardBg,
    borderColor: AppColors.gold,
    padding: const EdgeInsets.all(AppSpacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today’s Completed',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.emerald900,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          formatQuantity(value),
          style: AppTypography.textTheme(AppColors.emerald950).displayMedium?.copyWith(
            color: AppColors.emerald950,
            fontWeight: FontWeight.w800,
            fontSize: 38,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Across all Zikr',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.lightCardTextMuted,
            fontWeight: FontWeight.w500,
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
    color: AppColors.darkCardBg,
    borderColor: AppColors.goldMuted.withValues(alpha: 0.35),
    padding: const EdgeInsets.all(AppSpacing.sm + 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.goldBright, size: 20),
        const SizedBox(height: AppSpacing.sm),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.goldBright,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
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
  Widget build(BuildContext context, WidgetRef ref) {
    final identity = Color(zikr.colorValue);
    final percentText = '${(zikr.progress * 100).toStringAsFixed(1)}%';

    return AppCard(
      color: AppColors.darkCardBg,
      borderColor: AppColors.goldMuted,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (context) => ZikrDetailsScreen(zikrId: zikr.id),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: zikr.progress,
                      strokeWidth: 8,
                      strokeCap: StrokeCap.round,
                      color: identity,
                      backgroundColor: identity.withValues(alpha: 0.18),
                      semanticsLabel: '$percentText complete',
                    ),
                  ),
                  Text(
                    percentText,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.goldBright,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    zikr.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.ivory,
                    ),
                  ),
                  if (zikr.arabicName != null) ...[
                    const SizedBox(height: 2),
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        zikr.arabicName!,
                        style: AppTypography.arabicScript(
                          color: AppColors.goldBright,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${formatQuantity(zikr.completed)} / ${formatQuantity(zikr.target)} Completed',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${formatQuantity(zikr.remaining)} Remaining',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.goldBright,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.goldMuted,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}
