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
  final _searchFocusNode = FocusNode();
  final _searchKey = GlobalKey();
  final _searchController = TextEditingController();
  bool _isSearching = false;

  ScrollController get _effectiveController =>
      widget.scrollController ?? (_internalController ??= ScrollController());

  @override
  void initState() {
    super.initState();
    _effectiveController.addListener(_onScroll);
    _searchController.text = ref.read(zikrProvider).search;
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
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _enterSearchMode() {
    setState(() {
      _isSearching = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  void _exitSearchMode() {
    _searchController.clear();
    ref.read(zikrProvider.notifier).setSearch('');
    _searchFocusNode.unfocus();
    FocusScope.of(context).unfocus();
    setState(() {
      _isSearching = false;
    });
  }

  Future<void> _onFilterIconPressed() async {
    final state = ref.read(zikrProvider);
    var period = state.historyPeriod;
    var zikrId = state.historyZikrId;
    var sortOrder = state.historySortOrder;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter Sessions',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(zikrProvider.notifier).resetHistoryFilters();
                          _searchController.clear();
                          Navigator.pop(sheetContext);
                        },
                        child: const Text('Reset Filters'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Date Range',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
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
                    selected: period,
                    onChanged: (val) => setSheetState(() => period = val),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Zikr Filter',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  DropdownButtonFormField<String?>(
                    initialValue: zikrId,
                    decoration: const InputDecoration(labelText: 'Zikr'),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Zikr'),
                      ),
                      for (final item in state.zikr)
                        DropdownMenuItem(value: item.id, child: Text(item.name)),
                    ],
                    onChanged: (val) => setSheetState(() => zikrId = val),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Sort Order',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  RadioGroup<HistorySortOrder>(
                    groupValue: sortOrder,
                    onChanged: (val) {
                      if (val != null) setSheetState(() => sortOrder = val);
                    },
                    child: Column(
                      children: [
                        RadioListTile<HistorySortOrder>(
                          title: const Text('Newest first'),
                          value: HistorySortOrder.newestFirst,
                        ),
                        RadioListTile<HistorySortOrder>(
                          title: const Text('Oldest first'),
                          value: HistorySortOrder.oldestFirst,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton(
                    onPressed: () {
                      ref.read(zikrProvider.notifier).setHistoryPeriod(period);
                      ref.read(zikrProvider.notifier).setHistoryZikr(zikrId);
                      ref
                          .read(zikrProvider.notifier)
                          .setHistorySortOrder(sortOrder);
                      Navigator.pop(sheetContext);
                    },
                    child: const Text('Apply Filters'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(zikrProvider);
    final sessions = state.filteredSessions(DateTime.now());
    DateTime? lastDay;

    if (_searchController.text != state.search) {
      _searchController.value = _searchController.value.copyWith(
        text: state.search,
        selection: TextSelection.collapsed(offset: state.search.length),
      );
    }

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
                if (_isSearching)
                  Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Close search',
                          icon: const Icon(Icons.arrow_back),
                          onPressed: _exitSearchMode,
                        ),
                        Expanded(
                          child: TextField(
                            key: _searchKey,
                            focusNode: _searchFocusNode,
                            controller: _searchController,
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: 'Search sessions...',
                              suffixIcon: state.search.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _searchController.clear();
                                        ref.read(zikrProvider.notifier).setSearch('');
                                      },
                                    )
                                  : null,
                            ),
                            onChanged: ref.read(zikrProvider.notifier).setSearch,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ScreenHeader(
                    title: 'History',
                    subtitle: 'Your completed sessions',
                    action: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton.filledTonal(
                          tooltip: 'Search sessions',
                          onPressed: _enterSearchMode,
                          icon: const Icon(Icons.search),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          tooltip: 'Filter sessions',
                          onPressed: _onFilterIconPressed,
                          icon: const Icon(Icons.filter_list_rounded),
                        ),
                      ],
                    ),
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
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyJourney(
                title: state.search.isNotEmpty
                    ? 'No matching sessions'
                    : 'No completed sessions',
                message: state.search.isNotEmpty
                    ? 'Try adjusting your search query or filters.'
                    : 'Record an Add Session entry and it will appear here.',
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
