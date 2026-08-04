import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_segmented_control.dart';
import '../../domain/zikr_models.dart';
import '../zikr_provider.dart';
import 'zikr_widgets.dart';

enum CounterViewMode { live, manual }

class TasbeehCounterWidget extends ConsumerStatefulWidget {
  const TasbeehCounterWidget({super.key, this.initialZikrId});

  final String? initialZikrId;

  @override
  ConsumerState<TasbeehCounterWidget> createState() =>
      _TasbeehCounterWidgetState();
}

class _TasbeehCounterWidgetState extends ConsumerState<TasbeehCounterWidget> {
  CounterViewMode _viewMode = CounterViewMode.manual;

  // Independent Selection States for Global / Home Mode
  String? _liveSelectedZikrId;
  String? _manualSelectedZikrId;
  int _selectedTarget = 33;

  // Manual Entry State & Controllers
  final _manualFormKey = GlobalKey<FormState>();
  final _manualAmountController = TextEditingController();
  final _manualNotesController = TextEditingController();
  String _manualLabel = 'Daily Session';
  bool _showManualSuccess = false;
  Timer? _successTimer;

  bool get _isFixedMode => widget.initialZikrId != null;

  @override
  void dispose() {
    _successTimer?.cancel();
    _manualAmountController.dispose();
    _manualNotesController.dispose();
    super.dispose();
  }

  String? _resolveLiveZikrId(
    List<Zikr> activeZikrs,
    ActiveCounterSession? activeSession,
  ) {
    if (_isFixedMode) return widget.initialZikrId;
    if (_liveSelectedZikrId != null &&
        activeZikrs.any((z) => z.id == _liveSelectedZikrId)) {
      return _liveSelectedZikrId;
    }
    if (activeSession != null &&
        activeZikrs.any((z) => z.id == activeSession.zikrId)) {
      return activeSession.zikrId;
    }
    return activeZikrs.isNotEmpty ? activeZikrs.first.id : null;
  }

  String? _resolveManualZikrId(List<Zikr> activeZikrs) {
    if (_isFixedMode) return widget.initialZikrId;
    if (_manualSelectedZikrId != null &&
        activeZikrs.any((z) => z.id == _manualSelectedZikrId)) {
      return _manualSelectedZikrId;
    }
    return activeZikrs.isNotEmpty ? activeZikrs.first.id : null;
  }

  Future<void> _promptCustomTarget(BuildContext context) async {
    final controller = TextEditingController(text: '33');
    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          'Set Custom Target',
          style: TextStyle(
            color: AppColors.darkEmerald,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: const TextStyle(color: AppColors.darkEmerald),
          decoration: const InputDecoration(
            labelText: 'Target count',
            hintText: 'e.g. 500',
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.emerald900,
              foregroundColor: AppColors.ivory,
            ),
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null && val > 0) {
                Navigator.of(dialogContext).pop(val);
              }
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (result != null && mounted) {
      setState(() {
        _selectedTarget = result;
      });
      final active = ref.read(zikrProvider).activeCounterSession;
      if (active != null && !active.isCompleted) {
        await ref.read(zikrProvider.notifier).setCounterTarget(result);
      }
    }
  }

  Future<void> _handleTap(String resolvedLiveZikrId) async {
    final active = ref.read(zikrProvider).activeCounterSession;
    if (active != null &&
        !active.isCompleted &&
        active.zikrId == resolvedLiveZikrId) {
      await ref.read(zikrProvider.notifier).incrementCounter();
    }
  }

  Future<void> _startSession(String zikrId, int target) async {
    await ref
        .read(zikrProvider.notifier)
        .startCounterSession(zikrId: zikrId, target: target);
  }

  Future<void> _confirmReset() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Reset session?',
      message: 'This will reset your current counting session to 0.',
      confirmLabel: 'Reset',
      destructive: true,
    );
    if (confirmed && mounted) {
      await ref.read(zikrProvider.notifier).resetCounterSession();
    }
  }

  Future<void> _confirmAbandon() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Abandon session?',
      message: 'Your active counting session will be discarded.',
      confirmLabel: 'Abandon',
      destructive: true,
    );
    if (confirmed && mounted) {
      await ref.read(zikrProvider.notifier).abandonCounterSession();
    }
  }

  Future<void> _submitManualEntry(String zikrId) async {
    if (!(_manualFormKey.currentState?.validate() ?? false)) return;
    final amount = int.tryParse(_manualAmountController.text);
    if (amount == null || amount <= 0) return;

    await ref
        .read(zikrProvider.notifier)
        .addSession(
          zikrId,
          amount,
          label: _manualLabel,
          note: _manualNotesController.text.trim().isEmpty
              ? null
              : _manualNotesController.text.trim(),
        );

    if (mounted) {
      _manualAmountController.clear();
      _manualNotesController.clear();
      setState(() {
        _showManualSuccess = true;
      });
      _successTimer?.cancel();
      _successTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showManualSuccess = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(zikrProvider);
    final activeZikrs = state.zikr
        .where((item) => item.status != ZikrStatus.archived)
        .toList();
    final activeSession = state.activeCounterSession;

    if (activeZikrs.isEmpty) {
      return const EmptyJourney(
        title: 'No Zikr Available',
        message: 'Create a Zikr goal first to record your spiritual progress.',
      );
    }

    final liveZikrId = _resolveLiveZikrId(activeZikrs, activeSession);
    final manualZikrId = _resolveManualZikrId(activeZikrs);

    final liveZikr = activeZikrs
        .where((item) => item.id == liveZikrId)
        .firstOrNull;
    final manualZikr = activeZikrs
        .where((item) => item.id == manualZikrId)
        .firstOrNull;

    return AppCard(
      color: AppColors.lightCardBg,
      borderColor: AppColors.goldMuted.withValues(alpha: 0.45),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Mode Switcher Segmented Control
          AppSegmentedControl<CounterViewMode>(
            tabs: const [
              AppSegmentedTab(
                value: CounterViewMode.manual,
                label: 'Manual Entry',
                icon: Icons.edit_note_outlined,
              ),
              AppSegmentedTab(
                value: CounterViewMode.live,
                label: 'Live Zikr',
                icon: Icons.touch_app_outlined,
              ),
            ],
            selected: _viewMode,
            onChanged: (mode) => setState(() => _viewMode = mode),
          ),
          const SizedBox(height: 12),

          // Render Mode View
          if (_viewMode == CounterViewMode.live)
            _buildLiveCounterView(
              context: context,
              activeZikrs: activeZikrs,
              activeSession: activeSession,
              currentZikr: liveZikr,
              currentZikrId: liveZikrId,
            )
          else
            _buildManualEntryView(
              context: context,
              activeZikrs: activeZikrs,
              currentZikr: manualZikr,
              currentZikrId: manualZikrId,
            ),
        ],
      ),
    );
  }

  Future<void> _selectLiveZikr(String newId) async {
    if (_isFixedMode || newId == _liveSelectedZikrId) return;

    if (mounted) {
      setState(() {
        _liveSelectedZikrId = newId;
      });
    }
    await ref.read(zikrProvider.notifier).selectLiveZikr(newId);
  }

  Future<void> _confirmSubmitLiveSession(
    BuildContext context,
    Zikr currentZikr,
    int count,
  ) async {
    if (count <= 0) return;
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.darkCardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.goldMuted),
        ),
        title: const Text(
          'Submit Live Session?',
          style: TextStyle(
            color: AppColors.goldBright,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Submit the current count of $count for "${currentZikr.name}" as a completed session?',
          style: const TextStyle(color: AppColors.ivory),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.goldBright,
            ),
            child: const Text('Continue Counting'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.goldBright,
              foregroundColor: AppColors.emerald950,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Submit Session',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(zikrProvider.notifier)
          .submitLiveSession(currentZikr.id);

      if (success && mounted) {
        unawaited(HapticFeedback.lightImpact());
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Live session submitted successfully'),
            duration: Duration(seconds: 2),
            backgroundColor: AppColors.emerald900,
          ),
        );
      }
    }
  }

  Future<void> _promptChangeLiveZikr(
    BuildContext context,
    List<Zikr> activeZikrs,
  ) async {
    if (_isFixedMode) return;

    final liveDrafts = ref.read(zikrProvider).liveDrafts;

    final selectedId = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text(
          'Select Live Zikr',
          style: TextStyle(
            color: AppColors.darkEmerald,
            fontWeight: FontWeight.bold,
          ),
        ),
        children: [
          for (final zikr in activeZikrs) ...[
            SimpleDialogOption(
              onPressed: () => Navigator.of(dialogContext).pop(zikr.id),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.spa_outlined,
                      color: AppColors.primaryEmerald,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        zikr.name,
                        style: const TextStyle(
                          color: AppColors.darkEmerald,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (liveDrafts.containsKey(zikr.id) &&
                        liveDrafts[zikr.id]!.count > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.goldBright.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          'Resumed at ${liveDrafts[zikr.id]!.count}',
                          style: const TextStyle(
                            color: AppColors.darkEmerald,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );

    if (selectedId != null && mounted) {
      await _selectLiveZikr(selectedId);
    }
  }

  Widget _buildLiveCounterView({
    required BuildContext context,
    required List<Zikr> activeZikrs,
    required ActiveCounterSession? activeSession,
    required Zikr? currentZikr,
    required String? currentZikrId,
  }) {
    final activeSessionMatches =
        activeSession != null && activeSession.zikrId == currentZikrId;

    if (!activeSessionMatches || currentZikr == null) {
      final savedDraft = currentZikrId != null
          ? ref.watch(zikrProvider).liveDrafts[currentZikrId]
          : null;

      return KeyedSubtree(
        key: const ValueKey('live-setup-view'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (savedDraft != null && savedDraft.count > 0)
              Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.goldBright.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: AppColors.goldMuted.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.restore_rounded,
                      size: 18,
                      color: AppColors.darkEmerald,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Resumed at ${savedDraft.count} with Live Target ${savedDraft.target}.',
                        style: const TextStyle(
                          color: AppColors.darkEmerald,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (_isFixedMode && currentZikr != null)
              Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryEmerald.withValues(alpha: 0.08),
                  borderRadius: AppRadius.input,
                  border: Border.all(
                    color: AppColors.goldMuted.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      size: 18,
                      color: AppColors.darkEmerald,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'Target Zikr: ${currentZikr.name}',
                        style: const TextStyle(
                          color: AppColors.darkEmerald,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              Text(
                'Select Zikr:',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.darkEmerald,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: currentZikrId,
                dropdownColor: AppColors.lightCardBg,
                style: const TextStyle(
                  color: AppColors.darkEmerald,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  labelText: 'Select Zikr',
                  labelStyle: const TextStyle(
                    color: AppColors.darkEmerald,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  floatingLabelStyle: const TextStyle(
                    color: AppColors.darkEmerald,
                    fontWeight: FontWeight.bold,
                  ),
                  hintStyle: const TextStyle(color: AppColors.mutedEmerald),
                  prefixIcon: const Icon(
                    Icons.spa_outlined,
                    color: AppColors.darkEmerald,
                  ),
                  filled: true,
                  fillColor: AppColors.lightCardBg,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadius.input,
                    borderSide: BorderSide(
                      color: AppColors.goldMuted.withValues(alpha: 0.6),
                    ),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: AppRadius.input,
                    borderSide: BorderSide(
                      color: AppColors.primaryEmerald,
                      width: 1.5,
                    ),
                  ),
                ),
                items: [
                  for (final item in activeZikrs)
                    DropdownMenuItem(
                      value: item.id,
                      child: Text(
                        item.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.darkEmerald,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
                onChanged: (id) {
                  if (id != null) {
                    _selectLiveZikr(id);
                  }
                },
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Text(
              'Select Target / Threshold:',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.darkEmerald,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final targetPreset in [33, 34, 100, 1000])
                  ChoiceChip(
                    label: Text('$targetPreset'),
                    labelStyle: TextStyle(
                      color: _selectedTarget == targetPreset
                          ? AppColors.ivory
                          : AppColors.darkEmerald,
                      fontWeight: FontWeight.bold,
                    ),
                    selectedColor: AppColors.emerald900,
                    backgroundColor: AppColors.lightCardBg,
                    side: BorderSide(
                      color: _selectedTarget == targetPreset
                          ? AppColors.gold
                          : AppColors.goldMuted.withValues(alpha: 0.4),
                    ),
                    selected: _selectedTarget == targetPreset,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedTarget = targetPreset);
                      }
                    },
                  ),
                ActionChip(
                  avatar: const Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: AppColors.darkEmerald,
                  ),
                  label: Text(
                    _selectedTarget != 33 &&
                            _selectedTarget != 34 &&
                            _selectedTarget != 100 &&
                            _selectedTarget != 1000
                        ? 'Custom ($_selectedTarget)'
                        : 'Custom',
                    style: const TextStyle(
                      color: AppColors.darkEmerald,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: AppColors.lightCardBg,
                  side: BorderSide(
                    color: AppColors.goldMuted.withValues(alpha: 0.4),
                  ),
                  onPressed: () => _promptCustomTarget(context),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: currentZikrId == null
                  ? null
                  : () => _startSession(currentZikrId, _selectedTarget),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(
                savedDraft != null && savedDraft.count > 0
                    ? 'Resume Live Session'
                    : 'Start Live Session',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(AppSpacing.md),
                backgroundColor: AppColors.emerald900,
                foregroundColor: AppColors.ivory,
                elevation: 2,
              ),
            ),
          ],
        ),
      );
    }

    final count = activeSession.count;
    final target = activeSession.target;
    final remaining = activeSession.remaining;
    final progress = activeSession.progress;
    final isCompleted = activeSession.isCompleted;
    final percentText = '${(progress * 100).toStringAsFixed(1)}%';

    final mainTarget = currentZikr.target;
    final persistedCompleted = currentZikr.completed;
    final activeLiveCount = (activeSession.zikrId == currentZikr.id)
        ? count
        : 0;
    final effectiveCompleted = persistedCompleted + activeLiveCount;
    final mainRemaining = (mainTarget - effectiveCompleted).clamp(
      0,
      mainTarget,
    );
    final mainPercentage = mainTarget <= 0
        ? 0.0
        : ((effectiveCompleted / mainTarget) * 100);

    return KeyedSubtree(
      key: const ValueKey('live-active-view'),
      child: Column(
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentZikr.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.darkEmerald,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (currentZikr.arabicName != null)
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(
                          currentZikr.arabicName!,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.primaryEmerald,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_isFixedMode) ...[
                    InkWell(
                      onTap: () => _promptChangeLiveZikr(context, activeZikrs),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryEmerald.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: AppColors.primaryEmerald.withValues(
                              alpha: 0.4,
                            ),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.swap_horiz_rounded,
                              size: 14,
                              color: AppColors.darkEmerald,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Change Zikr',
                              style: TextStyle(
                                color: AppColors.darkEmerald,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppColors.goldBright.withValues(alpha: 0.25)
                          : AppColors.primaryEmerald.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: isCompleted
                            ? AppColors.gold
                            : AppColors.primaryEmerald,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isCompleted
                              ? Icons.stars_rounded
                              : Icons.timer_outlined,
                          size: 14,
                          color: AppColors.darkEmerald,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isCompleted ? 'Completed' : 'Active',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppColors.darkEmerald,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Top Stats Row (MAIN Zikr Metrics)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: _StatItem(
                  label: 'Target',
                  value: formatQuantity(mainTarget),
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: 'Remaining',
                  value: formatQuantity(mainRemaining),
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: 'Percentage',
                  value: '${mainPercentage.toStringAsFixed(1)}%',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Main Tap Control Button
          Semantics(
            button: true,
            label:
                'Counter control. Current count $count of $target. Remaining $remaining.',
            hint: isCompleted
                ? 'Session completed'
                : 'Tap to increment count by 1',
            child: GestureDetector(
              onTap: () => _handleTap(currentZikrId!),
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFF003B2F), Color(0xFF00281F)],
                  ),
                  border: Border.all(
                    color: isCompleted
                        ? AppColors.goldBright
                        : AppColors.goldMuted,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.goldBright.withValues(alpha: 0.25),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Circular Progress
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 10,
                        strokeCap: StrokeCap.round,
                        color: AppColors.goldBright,
                        backgroundColor: AppColors.goldMuted.withValues(
                          alpha: 0.2,
                        ),
                      ),
                    ),
                    // Center Count Text
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          formatQuantity(count),
                          style: Theme.of(context).textTheme.displayMedium
                              ?.copyWith(
                                color: AppColors.goldBright,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          'Live Target: ${formatQuantity(target)}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          percentText,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: AppColors.goldMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Completion or Active Stats
          if (isCompleted) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primaryEmerald.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.primaryEmerald),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    color: AppColors.darkEmerald,
                    size: 32,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'MashaAllah! Threshold Reached',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.darkEmerald,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Session saved automatically to History & Reflection.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primaryEmerald,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              onPressed: () => _startSession(currentZikr.id, _selectedTarget),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Start New Session'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.emerald900,
                foregroundColor: AppColors.ivory,
              ),
            ),
          ] else ...[
            // Bottom Stats Row (LIVE Session Metrics)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: _StatItem(
                    label: 'Live Remaining',
                    value: formatQuantity(remaining),
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    label: 'Live Target',
                    value: formatQuantity(target),
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    label: 'Live Percentage',
                    value: percentText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // Target Preset Chips during Active Session
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.xs,
              children: [
                for (final preset in [33, 34, 100, 1000])
                  ChoiceChip(
                    label: Text('$preset'),
                    labelStyle: TextStyle(
                      color: target == preset
                          ? AppColors.ivory
                          : AppColors.darkEmerald,
                      fontWeight: FontWeight.bold,
                    ),
                    selectedColor: AppColors.emerald900,
                    backgroundColor: AppColors.lightCardBg,
                    side: BorderSide(
                      color: target == preset
                          ? AppColors.gold
                          : AppColors.goldMuted.withValues(alpha: 0.4),
                    ),
                    selected: target == preset,
                    onSelected: (selected) {
                      if (selected) {
                        ref
                            .read(zikrProvider.notifier)
                            .setCounterTarget(preset);
                      }
                    },
                  ),
                ActionChip(
                  avatar: const Icon(
                    Icons.edit_outlined,
                    size: 14,
                    color: AppColors.darkEmerald,
                  ),
                  label: const Text(
                    'Custom',
                    style: TextStyle(
                      color: AppColors.darkEmerald,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: AppColors.lightCardBg,
                  side: BorderSide(
                    color: AppColors.goldMuted.withValues(alpha: 0.4),
                  ),
                  onPressed: () => _promptCustomTarget(context),
                ),
              ],
            ),
          ],

          const Divider(height: AppSpacing.xl),
          // Action Buttons: 1. Submit Live Session, 2. Abandon / Reset
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: count <= 0
                      ? null
                      : () => _confirmSubmitLiveSession(
                          context,
                          currentZikr,
                          count,
                        ),
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: Text(
                    count > 0
                        ? 'Submit Live Session ($count)'
                        : 'Submit Live Session',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                      horizontal: AppSpacing.lg,
                    ),
                    backgroundColor: AppColors.emerald900,
                    foregroundColor: AppColors.ivory,
                    disabledBackgroundColor: AppColors.emerald900.withValues(
                      alpha: 0.3,
                    ),
                    disabledForegroundColor: AppColors.ivory.withValues(
                      alpha: 0.5,
                    ),
                    elevation: 2,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: _confirmAbandon,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Abandon'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _confirmReset,
                    icon: const Icon(Icons.restart_alt_rounded, size: 18),
                    label: const Text('Reset Count'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryEmerald,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildManualEntryView({
    required BuildContext context,
    required List<Zikr> activeZikrs,
    required Zikr? currentZikr,
    required String? currentZikrId,
  }) {
    final targetZikrId = currentZikrId ?? activeZikrs.first.id;

    return KeyedSubtree(
      key: const ValueKey('manual-entry-view'),
      child: Form(
        key: _manualFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isFixedMode && currentZikr != null)
              Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryEmerald.withValues(alpha: 0.08),
                  borderRadius: AppRadius.input,
                  border: Border.all(
                    color: AppColors.goldMuted.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      size: 18,
                      color: AppColors.darkEmerald,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'Target Zikr: ${currentZikr.name}',
                        style: const TextStyle(
                          color: AppColors.darkEmerald,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              Text(
                'Select Zikr:',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.darkEmerald,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: targetZikrId,
                dropdownColor: AppColors.lightCardBg,
                style: const TextStyle(
                  color: AppColors.darkEmerald,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  labelText: 'Select Zikr',
                  labelStyle: const TextStyle(
                    color: AppColors.darkEmerald,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  floatingLabelStyle: const TextStyle(
                    color: AppColors.darkEmerald,
                    fontWeight: FontWeight.bold,
                  ),
                  hintStyle: const TextStyle(color: AppColors.mutedEmerald),
                  prefixIcon: const Icon(
                    Icons.spa_outlined,
                    color: AppColors.darkEmerald,
                  ),
                  filled: true,
                  fillColor: AppColors.lightCardBg,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadius.input,
                    borderSide: BorderSide(
                      color: AppColors.goldMuted.withValues(alpha: 0.6),
                    ),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: AppRadius.input,
                    borderSide: BorderSide(
                      color: AppColors.primaryEmerald,
                      width: 1.5,
                    ),
                  ),
                ),
                items: [
                  for (final item in activeZikrs)
                    DropdownMenuItem(
                      value: item.id,
                      child: Text(
                        item.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.darkEmerald,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
                onChanged: (id) {
                  if (id != null) {
                    setState(() => _manualSelectedZikrId = id);
                  }
                },
              ),
            ],
            const SizedBox(height: 12),

            // Completed Count Input
            TextFormField(
              controller: _manualAmountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                color: AppColors.darkEmerald,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              cursorColor: AppColors.primaryEmerald,
              decoration: InputDecoration(
                labelText: 'Completed Count',
                labelStyle: const TextStyle(
                  color: AppColors.darkEmerald,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                floatingLabelStyle: const TextStyle(
                  color: AppColors.darkEmerald,
                  fontWeight: FontWeight.bold,
                ),
                hintText: 'e.g. 100',
                hintStyle: const TextStyle(color: AppColors.mutedEmerald),
                prefixIcon: const Icon(
                  Icons.add_task_rounded,
                  color: AppColors.darkEmerald,
                ),
                filled: true,
                fillColor: AppColors.lightCardBg,
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.input,
                  borderSide: BorderSide(
                    color: AppColors.goldMuted.withValues(alpha: 0.6),
                  ),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: AppRadius.input,
                  borderSide: BorderSide(
                    color: AppColors.primaryEmerald,
                    width: 1.5,
                  ),
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Count is required';
                }
                final numVal = int.tryParse(val);
                if (numVal == null || numVal <= 0) {
                  return 'Enter a positive number';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Label Presets
            Text(
              'Session Label:',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.darkEmerald,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final label in [
                  'Daily Session',
                  'After Fajr',
                  'After Maghrib',
                  'Night Zikr',
                ])
                  ChoiceChip(
                    label: Text(label),
                    labelStyle: TextStyle(
                      color: _manualLabel == label
                          ? AppColors.ivory
                          : AppColors.darkEmerald,
                      fontWeight: FontWeight.bold,
                    ),
                    selectedColor: AppColors.emerald900,
                    backgroundColor: AppColors.lightCardBg,
                    side: BorderSide(
                      color: _manualLabel == label
                          ? AppColors.gold
                          : AppColors.goldMuted.withValues(alpha: 0.4),
                    ),
                    selected: _manualLabel == label,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _manualLabel = label);
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Notes (Optional)
            TextFormField(
              controller: _manualNotesController,
              style: const TextStyle(
                color: AppColors.darkEmerald,
                fontSize: 14,
              ),
              cursorColor: AppColors.primaryEmerald,
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                labelStyle: const TextStyle(
                  color: AppColors.darkEmerald,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                floatingLabelStyle: const TextStyle(
                  color: AppColors.darkEmerald,
                  fontWeight: FontWeight.bold,
                ),
                hintText: 'e.g. After evening prayer',
                hintStyle: const TextStyle(color: AppColors.mutedEmerald),
                prefixIcon: const Icon(
                  Icons.note_alt_outlined,
                  color: AppColors.darkEmerald,
                ),
                filled: true,
                fillColor: AppColors.lightCardBg,
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.input,
                  borderSide: BorderSide(
                    color: AppColors.goldMuted.withValues(alpha: 0.6),
                  ),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: AppRadius.input,
                  borderSide: BorderSide(
                    color: AppColors.primaryEmerald,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Success Confirmation Banner
            if (_showManualSuccess)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primaryEmerald.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.primaryEmerald),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.darkEmerald,
                    ),
                    SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'Session recorded and added to History!',
                        style: TextStyle(
                          color: AppColors.darkEmerald,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Submit Button
            ElevatedButton.icon(
              onPressed: () => _submitManualEntry(targetZikrId),
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text('Save Completed Session'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(AppSpacing.md),
                backgroundColor: AppColors.emerald900,
                foregroundColor: AppColors.ivory,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.darkEmerald,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.mutedEmerald,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
