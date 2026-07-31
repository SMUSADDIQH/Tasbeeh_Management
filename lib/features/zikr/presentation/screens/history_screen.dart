import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_segmented_control.dart';
import '../../domain/zikr_models.dart';
import '../widgets/zikr_widgets.dart';
import '../zikr_provider.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key, this.scrollController});
  final ScrollController? scrollController;

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  ScrollController? _internalController;

  ScrollController get _effectiveController =>
      widget.scrollController ?? (_internalController ??= ScrollController());

  @override
  void initState() {
    super.initState();
    _effectiveController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant HistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController?.removeListener(_onScroll);
      _internalController?.removeListener(_onScroll);
      _effectiveController.addListener(_onScroll);
    }
  }

  void _onScroll() {
    if (_effectiveController.hasClients &&
        _effectiveController.position.extentAfter < 420) {
      ref.read(zikrProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _effectiveController.removeListener(_onScroll);
    _internalController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(zikrProvider);
    final sessions = state.filteredSessions(DateTime.now());
    DateTime? lastDay;
    return RefreshIndicator(
      onRefresh: ref.read(zikrProvider.notifier).refresh,
      child: CustomScrollView(
        controller: _effectiveController,
        key: const PageStorageKey('history-scroll'),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            sliver: SliverList.list(
              children: [
                ScreenHeader(
                  title: 'History',
                  subtitle: 'Your completed sessions',
                  action: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton.filledTonal(
                        tooltip: 'Search sessions',
                        onPressed: () {},
                        icon: const Icon(Icons.search),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        tooltip: 'Filter sessions',
                        onPressed: () {},
                        icon: const Icon(Icons.filter_list_rounded),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SearchBar(
                  hintText: 'Search sessions',
                  leading: const Icon(Icons.search),
                  onChanged: ref.read(zikrProvider.notifier).setSearch,
                ),
                const SizedBox(height: AppSpacing.md),
                AppSegmentedControl<HistoryPeriod>(
                  isDarkBackground: true,
                  tabs: const [
                    AppSegmentedTab(value: HistoryPeriod.today, label: 'Today'),
                    AppSegmentedTab(
                      value: HistoryPeriod.week,
                      label: 'This Week',
                    ),
                    AppSegmentedTab(
                      value: HistoryPeriod.month,
                      label: 'This Month',
                    ),
                    AppSegmentedTab(
                      value: HistoryPeriod.all,
                      label: 'All Time',
                    ),
                  ],
                  selected: state.historyPeriod,
                  onChanged: (value) =>
                      ref.read(zikrProvider.notifier).setHistoryPeriod(value),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String?>(
                  initialValue: state.historyZikrId,
                  decoration: const InputDecoration(
                    labelText: 'Filter by Zikr',
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All Zikr'),
                    ),
                    for (final item in state.zikr)
                      DropdownMenuItem(value: item.id, child: Text(item.name)),
                  ],
                  onChanged: ref.read(zikrProvider.notifier).setHistoryZikr,
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
          if (state.isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (sessions.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyJourney(
                title: 'No completed sessions',
                message: 'Record an Add Session entry and it will appear here.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                120,
              ),
              sliver: SliverList.builder(
                itemCount: sessions.length + (state.isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == sessions.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  final session = sessions[index];
                  final zikr = state.zikr
                      .where((item) => item.id == session.zikrId)
                      .firstOrNull;
                  if (zikr == null) return const SizedBox.shrink();
                  final day = DateTime(
                    session.timestamp.year,
                    session.timestamp.month,
                    session.timestamp.day,
                  );
                  final showHeader = day != lastDay;
                  lastDay = day;

                  final dayTotal = sessions
                      .where(
                        (s) =>
                            s.timestamp.year == day.year &&
                            s.timestamp.month == day.month &&
                            s.timestamp.day == day.day,
                      )
                      .fold<int>(0, (sum, s) => sum + s.amount);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showHeader)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.xs,
                            AppSpacing.md,
                            AppSpacing.xs,
                            AppSpacing.sm,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  formatDate(day),
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Total: ${formatQuantity(dayTotal)}',
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      AppCard(
                        padding: EdgeInsets.zero,
                        child: SessionTile(
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
                              message:
                                  'The completed total and progress will be recalculated.',
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
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
