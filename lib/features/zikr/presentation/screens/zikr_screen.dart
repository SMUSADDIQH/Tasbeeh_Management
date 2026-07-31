import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_segmented_control.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../domain/zikr_models.dart';
import '../widgets/zikr_widgets.dart';
import '../zikr_provider.dart';
import 'zikr_details_screen.dart';

class ZikrScreen extends ConsumerWidget {
  const ZikrScreen({super.key, this.scrollController});
  final ScrollController? scrollController;

  Future<void> _newZikr(BuildContext context, WidgetRef ref) async {
    final draft = await showZikrForm(
      context,
      defaultTarget: ref.read(settingsProvider).settings.defaultTarget,
    );
    if (draft != null) await ref.read(zikrProvider.notifier).create(draft);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(zikrProvider);
    final items = state.visibleZikr;
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _newZikr(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New Zikr'),
      ),
      body: SafeArea(
        child: CustomScrollView(
          controller: scrollController,
          key: const PageStorageKey('zikr-scroll'),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              sliver: SliverList.list(
                children: [
                  ScreenHeader(
                    title: 'My Zikr',
                    subtitle: 'Manage your spiritual goals',
                    action: IconButton.filledTonal(
                      tooltip: 'Create New Zikr',
                      onPressed: () => _newZikr(context, ref),
                      icon: const Icon(Icons.add),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SearchBar(
                    hintText: 'Search Zikr',
                    leading: const Icon(Icons.search),
                    onChanged: ref.read(zikrProvider.notifier).setSearch,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppSegmentedControl<ZikrFilter>(
                    isDarkBackground: true,
                    tabs: [
                      AppSegmentedTab(
                        value: ZikrFilter.active,
                        label:
                            'Active (${state.zikr.where((i) => i.status == ZikrStatus.active).length})',
                      ),
                      AppSegmentedTab(
                        value: ZikrFilter.completed,
                        label:
                            'Completed (${state.zikr.where((i) => i.status == ZikrStatus.completed).length})',
                      ),
                      AppSegmentedTab(
                        value: ZikrFilter.archived,
                        label:
                            'Archived (${state.zikr.where((i) => i.status == ZikrStatus.archived).length})',
                      ),
                    ],
                    selected: state.zikrFilter,
                    onChanged: (value) =>
                        ref.read(zikrProvider.notifier).setZikrFilter(value),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
            if (state.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyJourney(
                  title: 'No ${state.zikrFilter.name} Zikr',
                  message: state.zikrFilter == ZikrFilter.active
                      ? 'Create a meaningful goal to begin your journey.'
                      : 'Items in this state will appear here.',
                  action: state.zikrFilter == ZikrFilter.active
                      ? FilledButton.icon(
                          onPressed: () => _newZikr(context, ref),
                          icon: const Icon(Icons.add),
                          label: const Text('New Zikr'),
                        )
                      : null,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  104,
                ),
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.crossAxisExtent >= 1000
                        ? 3
                        : constraints.crossAxisExtent >= 650
                        ? 2
                        : 1;
                    if (columns == 1) {
                      return SliverList.separated(
                        itemCount: items.length,
                        itemBuilder: (context, index) =>
                            _buildCard(context, ref, items[index]),
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.md),
                      );
                    }
                    return SliverGrid.builder(
                      itemCount: items.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: AppSpacing.md,
                        mainAxisSpacing: AppSpacing.md,
                        mainAxisExtent: 310,
                      ),
                      itemBuilder: (context, index) =>
                          _buildCard(context, ref, items[index]),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, WidgetRef ref, Zikr item) {
    return ZikrCard(
      zikr: item,
      onOpen: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (context) => ZikrDetailsScreen(zikrId: item.id),
        ),
      ),
      onAddSession: () => showSessionForm(context, ref, item),
      onEdit: () async {
        final draft = await showZikrForm(
          context,
          existing: item,
          defaultTarget: item.target,
        );
        if (draft != null) {
          await ref.read(zikrProvider.notifier).edit(item.id, draft);
        }
      },
      onFavorite: () => ref.read(zikrProvider.notifier).toggleFavorite(item.id),
      onArchive: () => ref
          .read(zikrProvider.notifier)
          .setArchived(item.id, item.status != ZikrStatus.archived),
      onDelete: () async {
        final confirmed = await showConfirmDialog(
          context,
          title: 'Delete ${item.name}?',
          message: 'This also deletes every session for this Zikr.',
          confirmLabel: 'Delete',
          destructive: true,
        );
        if (confirmed) {
          await ref.read(zikrProvider.notifier).deleteZikr(item.id);
        }
      },
    );
  }
}
