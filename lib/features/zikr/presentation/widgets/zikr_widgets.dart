import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/arabic_name_translation_service.dart';
import '../../domain/zikr_models.dart';
import '../zikr_provider.dart';

const zikrColors = [
  Color(0xFF146B55),
  Color(0xFF8A6A2F),
  Color(0xFF4C6E91),
  Color(0xFF7D5260),
  Color(0xFF5A6F49),
  Color(0xFF65558F),
];

const zikrIcons = [
  Icons.spa_outlined,
  Icons.menu_book_outlined,
  Icons.favorite_outline,
  Icons.auto_awesome_outlined,
  Icons.wb_twilight_outlined,
  Icons.brightness_5_outlined,
];

IconData zikrIcon(int identifier) =>
    zikrIcons[identifier.clamp(0, zikrIcons.length - 1)];

class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    required this.title,
    required this.subtitle,
    super.key,
    this.action,
  });
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.goldBright,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      ?action,
    ],
  );
}

class ZikrCard extends StatelessWidget {
  const ZikrCard({
    required this.zikr,
    required this.onOpen,
    required this.onAddSession,
    required this.onEdit,
    required this.onFavorite,
    required this.onArchive,
    required this.onDelete,
    super.key,
  });

  final Zikr zikr;
  final VoidCallback onOpen;
  final VoidCallback onAddSession;
  final VoidCallback onEdit;
  final VoidCallback onFavorite;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final identity = Color(zikr.colorValue);
    final percentText = '${(zikr.progress * 100).toStringAsFixed(1)}%';

    return Semantics(
      button: true,
      label:
          '${zikr.name}. Completed ${formatQuantity(zikr.completed)} of '
          '${formatQuantity(zikr.target)}. Remaining ${formatQuantity(zikr.remaining)}.',
      hint: 'Open Zikr details',
      child: AppCard(
        onTap: onOpen,
        color: AppColors.lightCardBg,
        borderColor: AppColors.goldMuted,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Circular Progress Indicator Ring on Left
                SizedBox(
                  width: 72,
                  height: 72,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: zikr.progress,
                          strokeWidth: 7,
                          strokeCap: StrokeCap.round,
                          color: identity,
                          backgroundColor: identity.withValues(alpha: 0.15),
                          semanticsLabel: '$percentText complete',
                        ),
                      ),
                      Text(
                        percentText,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppColors.darkEmerald,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // Title and Arabic script on Right
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: identity.withValues(alpha: 0.14),
                              borderRadius: AppRadius.pillBorder,
                            ),
                            child: Icon(
                              zikrIcon(zikr.iconCodePoint),
                              size: 16,
                              color: identity,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              zikr.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: AppColors.darkEmerald,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: zikr.isFavorite
                                ? 'Remove from favorites'
                                : 'Add to favorites',
                            onPressed: onFavorite,
                            icon: Icon(
                              zikr.isFavorite
                                  ? Icons.star_rounded
                                  : Icons.star_outline,
                              color: zikr.isFavorite
                                  ? AppColors.goldMuted
                                  : AppColors.lightCardTextMuted,
                            ),
                          ),
                          const SizedBox(width: 4),
                          PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            iconColor: AppColors.lightCardTextMuted,
                            tooltip: 'More actions for ${zikr.name}',
                            onSelected: (value) {
                              switch (value) {
                                case 'edit':
                                  onEdit();
                                case 'archive':
                                  onArchive();
                                case 'delete':
                                  onDelete();
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit'),
                              ),
                              PopupMenuItem(
                                value: 'archive',
                                child: Text(
                                  zikr.status == ZikrStatus.archived
                                      ? 'Restore'
                                      : 'Archive',
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (zikr.arabicName != null) ...[
                        const SizedBox(height: 2),
                        Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(
                            zikr.arabicName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.arabicScript(
                              color: AppColors.primaryEmerald,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.sm),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '${formatQuantity(zikr.completed)} ',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: AppColors.darkEmerald,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(
                              text: '/ ${formatQuantity(zikr.target)} ',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.mutedEmerald,
                              ),
                            ),
                            TextSpan(
                              text: 'Completed',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.mutedEmerald,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: identity.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${formatQuantity(zikr.remaining)} Remaining',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: identity,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (zikr.status != ZikrStatus.archived) ...[
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.darkEmerald,
                    side: BorderSide(
                      color: AppColors.goldMuted.withValues(alpha: 0.6),
                    ),
                    backgroundColor: AppColors.emerald900.withValues(
                      alpha: 0.08,
                    ),
                  ),
                  onPressed: onAddSession,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Session'),
                ),
              ),
            ],
          ],
        ),
      ).animate().fadeIn(duration: 220.ms).slideY(begin: 0.025, end: 0),
    );
  }
}

class SessionTile extends StatelessWidget {
  const SessionTile({
    required this.session,
    required this.zikr,
    super.key,
    this.onEdit,
    this.onDelete,
  });
  final ZikrSession session;
  final Zikr zikr;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label:
        '${zikr.name}, completed ${formatQuantity(session.amount)}, '
        '${formatTime(session.timestamp)}, running total '
        '${formatQuantity(session.runningTotalAfter)}'
        '${session.note == null ? '' : ', ${session.note}'}',
    child: ExcludeSemantics(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        leading: CircleAvatar(
          backgroundColor: Color(zikr.colorValue).withValues(alpha: 0.14),
          child: Icon(
            zikrIcon(zikr.iconCodePoint),
            color: Color(zikr.colorValue),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                zikr.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '+${formatQuantity(session.amount)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        subtitle: Text(
          [
            if (session.label != null) session.label!,
            if (session.note != null) session.note!,
            'Total ${formatQuantity(session.runningTotalAfter)}',
          ].join(' · '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: onEdit == null
            ? Text(formatTime(session.timestamp))
            : PopupMenuButton<String>(
                tooltip: 'Session actions',
                onSelected: (value) =>
                    value == 'edit' ? onEdit?.call() : onDelete?.call(),
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit session')),
                  PopupMenuItem(value: 'delete', child: Text('Delete session')),
                ],
              ),
      ),
    ),
  );
}

class EmptyJourney extends StatelessWidget {
  const EmptyJourney({
    required this.title,
    required this.message,
    super.key,
    this.action,
  });
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.spa_outlined,
            size: 56,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.xl),
            action!,
          ],
        ],
      ),
    ),
  );
}

Future<ZikrDraft?> showZikrForm(
  BuildContext context, {
  Zikr? existing,
  required int defaultTarget,
}) {
  return showModalBottomSheet<ZikrDraft>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) =>
        _ZikrFormSheet(existing: existing, defaultTarget: defaultTarget),
  );
}

class _ZikrFormSheet extends ConsumerStatefulWidget {
  const _ZikrFormSheet({this.existing, required this.defaultTarget});

  final Zikr? existing;
  final int defaultTarget;

  @override
  ConsumerState<_ZikrFormSheet> createState() => _ZikrFormSheetState();
}

class _ZikrFormSheetState extends ConsumerState<_ZikrFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _nameFocusNode = FocusNode();
  final _targetFocusNode = FocusNode();
  final _nameKey = GlobalKey();
  final _targetKey = GlobalKey();

  late final TextEditingController _nameController;
  late final TextEditingController _arabicController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _targetController;
  late final TextEditingController _startingController;
  late final TextEditingController _notesController;
  late final TextEditingController _vibrationIntervalController;

  late ZikrCategory _category;
  late bool _favorite;
  late int _color;
  late int _icon;
  late DateTime _startDate;
  DateTime? _targetDate;
  late CountVibrationMode _vibrationMode;

  Timer? _debounceTimer;
  int _translationRequestToken = 0;
  String? _lastAutoGeneratedArabic;
  bool _isArabicManuallyEdited = false;
  bool _isProgrammaticUpdate = false;
  bool _isTranslating = false;
  String? _translationStatusMessage;
  String? _translationError;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name);
    _arabicController = TextEditingController(text: existing?.arabicName);
    _descriptionController = TextEditingController(text: existing?.description);
    _targetController = TextEditingController(
      text: (existing?.target ?? widget.defaultTarget).toString(),
    );
    _startingController = TextEditingController(text: '0');
    _notesController = TextEditingController(text: existing?.notes);
    _vibrationIntervalController = TextEditingController(
      text: existing?.vibrationInterval?.toString() ?? '',
    );

    _category = existing?.category ?? ZikrCategory.custom;
    _favorite = existing?.isFavorite ?? false;
    _color = existing?.colorValue ?? zikrColors.first.toARGB32();
    _icon = existing?.iconCodePoint ?? 0;
    _startDate = existing?.startDate ?? DateTime.now();
    _targetDate = existing?.targetDate;
    _vibrationMode = existing?.countVibrationMode ?? CountVibrationMode.off;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _scrollController.dispose();
    _nameFocusNode.dispose();
    _targetFocusNode.dispose();
    _nameController.dispose();
    _arabicController.dispose();
    _descriptionController.dispose();
    _targetController.dispose();
    _startingController.dispose();
    _notesController.dispose();
    _vibrationIntervalController.dispose();
    super.dispose();
  }

  void _onNameChanged(String text, bool autoTranslateEnabled) {
    if (!autoTranslateEnabled) {
      _debounceTimer?.cancel();
      if (_isTranslating) {
        setState(() {
          _isTranslating = false;
          _translationStatusMessage = null;
        });
      }
      return;
    }
    _debounceTimer?.cancel();
    if (text.trim().isEmpty) {
      if (_isTranslating) {
        setState(() {
          _isTranslating = false;
          _translationStatusMessage = null;
        });
      }
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 600), () {
      _triggerAutoTranslation(forceReplace: false);
    });
  }

  void _onArabicChanged() {
    if (_isProgrammaticUpdate) return;
    final text = _arabicController.text;
    if (text != _lastAutoGeneratedArabic) {
      _isArabicManuallyEdited = true;
    }
  }

  Future<void> _triggerAutoTranslation({bool forceReplace = false}) async {
    final text = _nameController.text.trim();
    if (text.isEmpty) {
      if (mounted) {
        setState(() {
          _isTranslating = false;
          _translationStatusMessage = null;
        });
      }
      return;
    }

    if (!forceReplace) {
      if (_isArabicManuallyEdited) return;
      final currentArabic = _arabicController.text.trim();
      final canAutoUpdate =
          currentArabic.isEmpty || currentArabic == _lastAutoGeneratedArabic;
      if (!canAutoUpdate) return;
    }

    final requestToken = ++_translationRequestToken;
    final service = ref.read(arabicTranslationServiceProvider);

    if (mounted) {
      setState(() {
        _isTranslating = true;
        _translationStatusMessage = null;
        _translationError = null;
      });
    }

    try {
      final result = await service.translate(
        text,
        onProgress: (message) {
          if (mounted && requestToken == _translationRequestToken) {
            setState(() {
              _translationStatusMessage = message;
            });
          }
        },
      );

      if (!mounted || requestToken != _translationRequestToken) return;

      if (result.isSuccess && result.arabicText != null) {
        _isProgrammaticUpdate = true;
        _arabicController.text = result.arabicText!;
        _isProgrammaticUpdate = false;

        setState(() {
          _lastAutoGeneratedArabic = result.arabicText;
          if (forceReplace) {
            _isArabicManuallyEdited = false;
          }
        });
      } else {
        setState(() {
          _translationError =
              result.errorMessage ??
              'Translation unavailable. Enter Arabic manually or retry.';
        });
      }
    } on Object catch (e, st) {
      debugPrint('Translation error: $e\n$st');
      if (mounted && requestToken == _translationRequestToken) {
        setState(() {
          _translationError =
              'Translation unavailable. Enter Arabic manually or retry.';
        });
      }
    } finally {
      if (mounted && requestToken == _translationRequestToken) {
        setState(() {
          _isTranslating = false;
          _translationStatusMessage = null;
        });
      }
    }
  }

  Future<void> _submit() async {
    final nameText = _nameController.text.trim();
    final targetText = _targetController.text.trim();
    final targetVal = int.tryParse(targetText);

    final isNameValid = nameText.isNotEmpty;
    final isTargetValid = targetVal != null && targetVal > 0;
    final isFormValid = _formKey.currentState?.validate() ?? false;

    if (!isNameValid || !isTargetValid || !isFormValid) {
      FocusNode? focusToRequest;
      BuildContext? targetContext;

      if (!isNameValid) {
        focusToRequest = _nameFocusNode;
        targetContext = _nameKey.currentContext;
      } else if (!isTargetValid) {
        focusToRequest = _targetFocusNode;
        targetContext = _targetKey.currentContext;
      }

      if (targetContext != null) {
        Scrollable.ensureVisible(
          targetContext,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
      focusToRequest?.requestFocus();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete the required fields'),
          duration: Duration(seconds: 2),
          backgroundColor: AppColors.emerald900,
        ),
      );
      return;
    }

    final targetValue = targetVal;
    final startValue = int.tryParse(_startingController.text) ?? 0;

    if (startValue > targetValue) {
      final proceed = await showConfirmDialog(
        context,
        title: 'Starting amount exceeds target',
        message: 'This Zikr will begin as completed. Continue anyway?',
        confirmLabel: 'Continue',
      );
      if (!proceed || !mounted) return;
    }

    FocusScope.of(context).unfocus();

    final draft = ZikrDraft(
      name: nameText,
      arabicName: _arabicController.text.trim().isEmpty
          ? null
          : _arabicController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      target: targetValue,
      startingCompleted: startValue,
      category: _category,
      isFavorite: _favorite,
      colorValue: _color,
      iconCodePoint: _icon,
      startDate: _startDate,
      targetDate: _targetDate,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      countVibrationMode: _vibrationMode,
      vibrationInterval: _vibrationMode == CountVibrationMode.customInterval
          ? int.tryParse(_vibrationIntervalController.text)
          : null,
    );

    Navigator.of(context).pop(draft);
  }

  @override
  Widget build(BuildContext context) {
    final autoTranslateEnabled = ref
        .watch(settingsProvider)
        .settings
        .autoTranslateZikrName;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: KeyedSubtree(
        key: const ValueKey('new-zikr-form'),
        child: Form(
          key: _formKey,
          child: ListView(
            controller: _scrollController,
            shrinkWrap: true,
            children: [
              Text(
                widget.existing == null ? 'New Zikr' : 'Edit Zikr',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.goldBright,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                key: _nameKey,
                focusNode: _nameFocusNode,
                controller: _nameController,
                autofocus: true,
                textInputAction: TextInputAction.next,
                style: const TextStyle(color: AppColors.softGold),
                decoration: const InputDecoration(
                  labelText: 'English Name *',
                  labelStyle: TextStyle(color: AppColors.premiumGold),
                  hintStyle: TextStyle(color: AppColors.mutedGold),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'English name is required';
                  }
                  return null;
                },
                onChanged: (val) => _onNameChanged(val, autoTranslateEnabled),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _arabicController,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(color: AppColors.softGold),
                      decoration: InputDecoration(
                        labelText: 'Arabic name (optional)',
                        labelStyle: const TextStyle(
                          color: AppColors.premiumGold,
                        ),
                        hintStyle: const TextStyle(color: AppColors.mutedGold),
                        suffixIcon: _isTranslating
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.goldBright,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      onChanged: (_) => _onArabicChanged(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  TextButton.icon(
                    onPressed: _isTranslating
                        ? null
                        : () => _triggerAutoTranslation(forceReplace: true),
                    icon: const Icon(Icons.translate, size: 16),
                    label: const Text('Translate again'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.goldBright,
                    ),
                  ),
                ],
              ),
              if (_isTranslating && _translationStatusMessage != null) ...[
                const SizedBox(height: 4),
                Text(
                  _translationStatusMessage!,
                  style: const TextStyle(
                    color: AppColors.mutedGold,
                    fontSize: 12,
                  ),
                ),
              ],
              if (_translationError != null) ...[
                const SizedBox(height: 4),
                Text(
                  _translationError!,
                  style: const TextStyle(
                    color: AppColors.goldMuted,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                style: const TextStyle(color: AppColors.softGold),
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  labelStyle: TextStyle(color: AppColors.premiumGold),
                  hintStyle: TextStyle(color: AppColors.mutedGold),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      key: _targetKey,
                      focusNode: _targetFocusNode,
                      controller: _targetController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(color: AppColors.softGold),
                      decoration: const InputDecoration(
                        labelText: 'Target *',
                        labelStyle: TextStyle(color: AppColors.premiumGold),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Target is required';
                        }
                        final parsed = int.tryParse(value.trim());
                        if (parsed == null || parsed <= 0) {
                          return 'Enter a valid target greater than zero';
                        }
                        return null;
                      },
                    ),
                  ),
                  if (widget.existing == null) ...[
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: TextFormField(
                        controller: _startingController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: const TextStyle(color: AppColors.softGold),
                        decoration: const InputDecoration(
                          labelText: 'Starting completed',
                          labelStyle: TextStyle(color: AppColors.premiumGold),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<ZikrCategory>(
                initialValue: _category,
                dropdownColor: AppColors.emerald850,
                style: const TextStyle(color: AppColors.softGold),
                decoration: const InputDecoration(
                  labelText: 'Category',
                  labelStyle: TextStyle(color: AppColors.premiumGold),
                ),
                items: [
                  for (final item in ZikrCategory.values)
                    DropdownMenuItem(
                      value: item,
                      child: Text(
                        item.label,
                        style: const TextStyle(color: AppColors.softGold),
                      ),
                    ),
                ],
                onChanged: (value) =>
                    setState(() => _category = value ?? _category),
              ),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.play_circle_outline,
                  color: AppColors.premiumGold,
                ),
                title: const Text(
                  'Start date',
                  style: TextStyle(color: AppColors.softGold),
                ),
                subtitle: Text(
                  formatDate(_startDate),
                  style: const TextStyle(color: AppColors.mutedGold),
                ),
                trailing: const Icon(
                  Icons.edit_calendar_outlined,
                  color: AppColors.premiumGold,
                ),
                onTap: () async {
                  final selected = await showDatePicker(
                    context: context,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    initialDate: _startDate,
                  );
                  if (selected != null && mounted) {
                    setState(() => _startDate = selected);
                  }
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.event_available_outlined,
                  color: AppColors.premiumGold,
                ),
                title: const Text(
                  'Target completion date',
                  style: TextStyle(color: AppColors.softGold),
                ),
                subtitle: Text(
                  _targetDate == null ? 'Optional' : formatDate(_targetDate!),
                  style: const TextStyle(color: AppColors.mutedGold),
                ),
                trailing: _targetDate == null
                    ? const Icon(Icons.add, color: AppColors.premiumGold)
                    : IconButton(
                        tooltip: 'Clear target completion date',
                        onPressed: () => setState(() => _targetDate = null),
                        icon: const Icon(
                          Icons.close,
                          color: AppColors.premiumGold,
                        ),
                      ),
                onTap: () async {
                  final selected = await showDatePicker(
                    context: context,
                    firstDate: _startDate,
                    lastDate: DateTime(2200),
                    initialDate:
                        _targetDate ?? _startDate.add(const Duration(days: 30)),
                  );
                  if (selected != null && mounted) {
                    setState(() => _targetDate = selected);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Color',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: AppColors.premiumGold),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final item in zikrColors)
                    Semantics(
                      label: 'Choose Zikr color',
                      selected: _color == item.toARGB32(),
                      child: InkWell(
                        borderRadius: AppRadius.pillBorder,
                        onTap: () => setState(() => _color = item.toARGB32()),
                        child: CircleAvatar(
                          backgroundColor: item,
                          child: _color == item.toARGB32()
                              ? const Icon(Icons.check, color: Colors.white)
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Symbol',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: AppColors.premiumGold),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (var index = 0; index < zikrIcons.length; index++)
                    IconButton.filledTonal(
                      tooltip: 'Choose Zikr symbol ${index + 1}',
                      isSelected: _icon == index,
                      onPressed: () => setState(() => _icon = index),
                      icon: Icon(zikrIcons[index]),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Count Vibration',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: AppColors.premiumGold),
              ),
              const SizedBox(height: AppSpacing.xs),
              DropdownButtonFormField<CountVibrationMode>(
                initialValue: _vibrationMode,
                dropdownColor: AppColors.emerald850,
                style: const TextStyle(color: AppColors.softGold),
                decoration: const InputDecoration(
                  labelText: 'Vibration Mode',
                  labelStyle: TextStyle(color: AppColors.premiumGold),
                ),
                items: const [
                  DropdownMenuItem(
                    value: CountVibrationMode.off,
                    child: Text(
                      'Off',
                      style: TextStyle(color: AppColors.softGold),
                    ),
                  ),
                  DropdownMenuItem(
                    value: CountVibrationMode.tasbeeh100,
                    child: Text(
                      'Tasbeeh 100',
                      style: TextStyle(color: AppColors.softGold),
                    ),
                  ),
                  DropdownMenuItem(
                    value: CountVibrationMode.customInterval,
                    child: Text(
                      'Every N Counts',
                      style: TextStyle(color: AppColors.softGold),
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _vibrationMode = value);
                  }
                },
              ),
              if (_vibrationMode == CountVibrationMode.tasbeeh100) ...[
                const SizedBox(height: 4),
                Text(
                  'Vibrates at 33, 66 and 100.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.mutedGold),
                ),
              ],
              if (_vibrationMode == CountVibrationMode.customInterval) ...[
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _vibrationIntervalController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(color: AppColors.softGold),
                  decoration: const InputDecoration(
                    labelText: 'Vibration Interval',
                    labelStyle: TextStyle(color: AppColors.premiumGold),
                    hintText: 'e.g. 10 or 33',
                    hintStyle: TextStyle(color: AppColors.mutedGold),
                  ),
                  validator: (value) {
                    if (_vibrationMode != CountVibrationMode.customInterval) {
                      return null;
                    }
                    if (value == null || value.trim().isEmpty) {
                      return 'Interval is required';
                    }
                    final parsed = int.tryParse(value);
                    if (parsed == null || parsed <= 0) {
                      return 'Enter an interval greater than 0';
                    }
                    final targetVal =
                        int.tryParse(_targetController.text) ?? 1000000;
                    if (parsed > targetVal) {
                      return 'Interval cannot exceed main target';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 4),
                Text(
                  'Vibrates every N completed live counts.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.mutedGold),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                style: const TextStyle(color: AppColors.softGold),
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  labelStyle: TextStyle(color: AppColors.premiumGold),
                  hintStyle: TextStyle(color: AppColors.mutedGold),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Favorite',
                  style: TextStyle(color: AppColors.softGold),
                ),
                value: _favorite,
                onChanged: (value) => setState(() => _favorite = value),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.premiumGold,
                  foregroundColor: AppColors.emerald950,
                ),
                onPressed: _submit,
                child: Text(
                  widget.existing == null ? 'Create Zikr' : 'Save Changes',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionDraft {
  const _SessionDraft({
    required this.amount,
    required this.timestamp,
    this.label,
    this.note,
  });

  final int amount;
  final DateTime timestamp;
  final String? label;
  final String? note;
}

Future<void> showSessionForm(
  BuildContext context,
  WidgetRef ref,
  Zikr zikr, {
  ZikrSession? existing,
}) async {
  final defaultLabel = ref.read(settingsProvider).settings.defaultSessionLabel;
  final draft = await showModalBottomSheet<_SessionDraft>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => _SessionFormSheet(
      zikr: zikr,
      existing: existing,
      defaultLabel: defaultLabel,
    ),
  );

  if (draft != null && context.mounted) {
    if (existing == null) {
      await ref
          .read(zikrProvider.notifier)
          .addSession(
            zikr.id,
            draft.amount,
            timestamp: draft.timestamp,
            label: draft.label,
            note: draft.note,
          );
    } else {
      await ref
          .read(zikrProvider.notifier)
          .editSession(
            existing,
            amount: draft.amount,
            timestamp: draft.timestamp,
            label: draft.label,
            note: draft.note,
          );
    }
  }
}

class _SessionFormSheet extends StatefulWidget {
  const _SessionFormSheet({
    required this.zikr,
    this.existing,
    required this.defaultLabel,
  });

  final Zikr zikr;
  final ZikrSession? existing;
  final String defaultLabel;

  @override
  State<_SessionFormSheet> createState() => _SessionFormSheetState();
}

class _SessionFormSheetState extends State<_SessionFormSheet> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  late String _label;
  late DateTime _timestamp;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _amountController = TextEditingController(
      text: existing?.amount.toString(),
    );
    _noteController = TextEditingController(text: existing?.note);
    _label = existing?.label ?? widget.defaultLabel;
    _timestamp = existing?.timestamp ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitted) return;
    final value = int.tryParse(_amountController.text);
    if (value == null || value <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a positive amount.')));
      return;
    }
    if (value >= 1000000 ||
        widget.zikr.completed + value > widget.zikr.target) {
      final proceed = await showConfirmDialog(
        context,
        title: value >= 1000000
            ? 'Unusually large session'
            : 'This exceeds the target',
        message: 'Review the amount before saving.',
        confirmLabel: 'Save Session',
      );
      if (!proceed || !mounted) return;
    }
    _submitted = true;
    FocusScope.of(context).unfocus();

    Navigator.of(context).pop(
      _SessionDraft(
        amount: value,
        timestamp: _timestamp,
        label: _label,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: KeyedSubtree(
        key: const ValueKey('add-session-form'),
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              widget.existing == null ? 'Add Session' : 'Edit Session',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: AppColors.goldBright),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              widget.zikr.name,
              style: const TextStyle(
                color: AppColors.softGold,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _amountController,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(color: AppColors.softGold),
              decoration: const InputDecoration(
                labelText: 'Completed amount',
                labelStyle: TextStyle(color: AppColors.premiumGold),
                hintStyle: TextStyle(color: AppColors.mutedGold),
                prefixIcon: Icon(
                  Icons.add_task_rounded,
                  color: AppColors.premiumGold,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final suggestion in [33, 100, 313, 500, 1000])
                  ActionChip(
                    label: Text(
                      formatQuantity(suggestion),
                      style: const TextStyle(color: AppColors.softGold),
                    ),
                    backgroundColor: AppColors.emerald850,
                    side: BorderSide(
                      color: AppColors.premiumGold.withValues(alpha: 0.4),
                    ),
                    onPressed: () =>
                        _amountController.text = suggestion.toString(),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: _label,
              dropdownColor: AppColors.emerald850,
              style: const TextStyle(color: AppColors.softGold),
              decoration: const InputDecoration(
                labelText: 'Session label',
                labelStyle: TextStyle(color: AppColors.premiumGold),
              ),
              items:
                  const [
                        'Morning',
                        'After Fajr',
                        'Afternoon',
                        'Evening',
                        'Night',
                        'Custom',
                      ]
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(
                            item,
                            style: const TextStyle(color: AppColors.softGold),
                          ),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _label = value);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.event_outlined,
                color: AppColors.premiumGold,
              ),
              title: const Text(
                'Session date and time',
                style: TextStyle(color: AppColors.softGold),
              ),
              subtitle: Text(
                '${formatDate(_timestamp)} · ${formatTime(_timestamp)}',
                style: const TextStyle(color: AppColors.mutedGold),
              ),
              trailing: const Icon(
                Icons.edit_calendar_outlined,
                color: AppColors.premiumGold,
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now().add(const Duration(days: 1)),
                  initialDate: _timestamp,
                );
                if (date == null || !context.mounted) return;
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(_timestamp),
                );
                if (time == null || !context.mounted) return;
                setState(
                  () => _timestamp = DateTime(
                    date.year,
                    date.month,
                    date.day,
                    time.hour,
                    time.minute,
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _noteController,
              maxLines: 2,
              style: const TextStyle(color: AppColors.softGold),
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                labelStyle: TextStyle(color: AppColors.premiumGold),
                hintStyle: TextStyle(color: AppColors.mutedGold),
                hintText: 'For example, after Fajr',
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.premiumGold,
                foregroundColor: AppColors.emerald950,
              ),
              onPressed: _submit,
              child: Text(
                widget.existing == null ? 'Save Session' : 'Update Session',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: destructive
                  ? FilledButton.styleFrom(
                      backgroundColor: Theme.of(
                        dialogContext,
                      ).colorScheme.error,
                    )
                  : null,
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        ),
      ) ??
      false;
}
