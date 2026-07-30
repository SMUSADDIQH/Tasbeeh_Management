import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/section_title.dart';
import '../providers/history_provider.dart';
import '../widgets/history_empty_state.dart';
import '../widgets/history_entry_card.dart';
import '../widgets/history_filter_bar.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(historyProvider);
    final notifier = ref.read(historyProvider.notifier);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: notifier.refresh,
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.metrics.extentAfter < 320) {
              notifier.loadMore();
            }
            return false;
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 920),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionTitle(
                          title: 'History',
                          subtitle: 'Every moment of remembrance, preserved.',
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        TextField(
                          onChanged: notifier.search,
                          textInputAction: TextInputAction.search,
                          decoration: const InputDecoration(
                            hintText: 'Search actions or counts',
                            prefixIcon: Icon(Icons.search_rounded),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        HistoryFilterBar(
                          selectedFilter: state.filter,
                          onSelected: notifier.setFilter,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  ),
                ),
              ),
              if (state.isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state.errorMessage != null && state.items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppErrorState(
                    message: state.errorMessage!,
                    onRetry: notifier.refresh,
                  ),
                )
              else if (state.items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: HistoryEmptyState(
                    hasSearch: state.searchTerm.trim().isNotEmpty,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = state.items[index];
                        return switch (item) {
                          HistoryDateHeaderItem(:final date) => _DateHeader(
                            date: date,
                          ),
                          HistoryEventItem(:final entry) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child:
                                HistoryEntryCard(
                                      key: ValueKey(
                                        entry.timestamp.microsecondsSinceEpoch,
                                      ),
                                      entry: entry,
                                    )
                                    .animate()
                                    .fadeIn(duration: 260.ms)
                                    .slideY(
                                      begin: 0.06,
                                      end: 0,
                                      curve: Curves.easeOutCubic,
                                    ),
                          ),
                        };
                      },
                      childCount: state.items.length,
                      addAutomaticKeepAlives: false,
                    ),
                  ),
                ),
              if (state.isLoadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = MaterialLocalizations.of(context).formatMediumDate(date);

    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.only(
          top: AppSpacing.sm,
          bottom: AppSpacing.sm,
        ),
        child: Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
