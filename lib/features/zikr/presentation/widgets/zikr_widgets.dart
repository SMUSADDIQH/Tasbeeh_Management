import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
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
                style: Theme.of(context).textTheme.headlineSmall,
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
    return Semantics(
      button: true,
      label:
          '${zikr.name}. Completed ${formatQuantity(zikr.completed)} of '
          '${formatQuantity(zikr.target)}. Remaining ${formatQuantity(zikr.remaining)}.',
      hint: 'Open Zikr details',
      child: AppCard(
        onTap: onOpen,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: identity.withValues(alpha: 0.14),
                  foregroundColor: identity,
                  child: Icon(zikrIcon(zikr.iconCodePoint)),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        zikr.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                      if (zikr.arabicName != null)
                        Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(
                            zikr.arabicName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: zikr.isFavorite
                      ? 'Remove from favorites'
                      : 'Add to favorites',
                  onPressed: onFavorite,
                  icon: Icon(
                    zikr.isFavorite ? Icons.star_rounded : Icons.star_outline,
                    color: zikr.isFavorite ? theme.colorScheme.secondary : null,
                  ),
                ),
                PopupMenuButton<String>(
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
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(
                      value: 'archive',
                      child: Text(
                        zikr.status == ZikrStatus.archived
                            ? 'Restore'
                            : 'Archive',
                      ),
                    ),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            if (zikr.description != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                zikr.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            ClipRRect(
              borderRadius: AppRadius.pillBorder,
              child: LinearProgressIndicator(
                value: zikr.progress,
                minHeight: 8,
                color: identity,
                backgroundColor: identity.withValues(alpha: 0.12),
                semanticsLabel:
                    '${(zikr.progress * 100).round()} percent complete',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _Value(
                    label: 'Completed',
                    value: formatQuantity(zikr.completed),
                  ),
                ),
                Expanded(
                  child: _Value(
                    label: 'Remaining',
                    value: formatQuantity(zikr.remaining),
                  ),
                ),
                Text(
                  '${(zikr.progress * 100).toStringAsFixed(1)}%',
                  style: theme.textTheme.titleSmall?.copyWith(color: identity),
                ),
              ],
            ),
            if (zikr.status != ZikrStatus.archived) ...[
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onAddSession,
                  icon: const Icon(Icons.add_rounded),
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

class _Value extends StatelessWidget {
  const _Value({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(value, style: Theme.of(context).textTheme.titleSmall),
      Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );
}

Future<ZikrDraft?> showZikrForm(
  BuildContext context, {
  Zikr? existing,
  required int defaultTarget,
}) async {
  final name = TextEditingController(text: existing?.name);
  final arabic = TextEditingController(text: existing?.arabicName);
  final description = TextEditingController(text: existing?.description);
  final target = TextEditingController(
    text: (existing?.target ?? defaultTarget).toString(),
  );
  final starting = TextEditingController(text: '0');
  final notes = TextEditingController(text: existing?.notes);
  var category = existing?.category ?? ZikrCategory.custom;
  var favorite = existing?.isFavorite ?? false;
  var color = existing?.colorValue ?? zikrColors.first.toARGB32();
  var icon = existing?.iconCodePoint ?? 0;
  var startDate = existing?.startDate ?? DateTime.now();
  var targetDate = existing?.targetDate;
  final formKey = GlobalKey<FormState>();
  final result = await showModalBottomSheet<ZikrDraft>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
        ),
        child: Form(
          key: formKey,
          child: ListView(
            shrinkWrap: true,
            children: [
              Text(
                existing == null ? 'New Zikr' : 'Edit Zikr',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: name,
                autofocus: true,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Name is required'
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: arabic,
                textDirection: TextDirection.rtl,
                decoration: const InputDecoration(
                  labelText: 'Arabic name (optional)',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: description,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: target,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(labelText: 'Target'),
                      validator: (value) =>
                          (int.tryParse(value ?? '') ?? 0) <= 0
                          ? 'Enter a positive target'
                          : null,
                    ),
                  ),
                  if (existing == null) ...[
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: TextFormField(
                        controller: starting,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Starting completed',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<ZikrCategory>(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: [
                  for (final item in ZikrCategory.values)
                    DropdownMenuItem(value: item, child: Text(item.label)),
                ],
                onChanged: (value) =>
                    setModalState(() => category = value ?? category),
              ),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.play_circle_outline),
                title: const Text('Start date'),
                subtitle: Text(formatDate(startDate)),
                trailing: const Icon(Icons.edit_calendar_outlined),
                onTap: () async {
                  final selected = await showDatePicker(
                    context: context,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    initialDate: startDate,
                  );
                  if (selected != null) {
                    setModalState(() => startDate = selected);
                  }
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_available_outlined),
                title: const Text('Target completion date'),
                subtitle: Text(
                  targetDate == null ? 'Optional' : formatDate(targetDate!),
                ),
                trailing: targetDate == null
                    ? const Icon(Icons.add)
                    : IconButton(
                        tooltip: 'Clear target completion date',
                        onPressed: () => setModalState(() => targetDate = null),
                        icon: const Icon(Icons.close),
                      ),
                onTap: () async {
                  final selected = await showDatePicker(
                    context: context,
                    firstDate: startDate,
                    lastDate: DateTime(2200),
                    initialDate:
                        targetDate ?? startDate.add(const Duration(days: 30)),
                  );
                  if (selected != null) {
                    setModalState(() => targetDate = selected);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Color', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final item in zikrColors)
                    Semantics(
                      label: 'Choose Zikr color',
                      selected: color == item.toARGB32(),
                      child: InkWell(
                        borderRadius: AppRadius.pillBorder,
                        onTap: () =>
                            setModalState(() => color = item.toARGB32()),
                        child: CircleAvatar(
                          backgroundColor: item,
                          child: color == item.toARGB32()
                              ? const Icon(Icons.check, color: Colors.white)
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Symbol', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (var index = 0; index < zikrIcons.length; index++)
                    IconButton.filledTonal(
                      tooltip: 'Choose Zikr symbol ${index + 1}',
                      isSelected: icon == index,
                      onPressed: () => setModalState(() => icon = index),
                      icon: Icon(zikrIcons[index]),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: notes,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Favorite'),
                value: favorite,
                onChanged: (value) => setModalState(() => favorite = value),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final targetValue = int.parse(target.text);
                  final startValue = int.tryParse(starting.text) ?? 0;
                  if (startValue > targetValue) {
                    final proceed = await showConfirmDialog(
                      context,
                      title: 'Starting amount exceeds target',
                      message:
                          'This Zikr will begin as completed. Continue anyway?',
                      confirmLabel: 'Continue',
                    );
                    if (!proceed || !context.mounted) return;
                  }
                  Navigator.pop(
                    context,
                    ZikrDraft(
                      name: name.text,
                      arabicName: arabic.text.trim().isEmpty
                          ? null
                          : arabic.text.trim(),
                      description: description.text.trim().isEmpty
                          ? null
                          : description.text.trim(),
                      target: targetValue,
                      startingCompleted: startValue,
                      category: category,
                      isFavorite: favorite,
                      colorValue: color,
                      iconCodePoint: icon,
                      startDate: startDate,
                      targetDate: targetDate,
                      notes: notes.text.trim().isEmpty
                          ? null
                          : notes.text.trim(),
                    ),
                  );
                },
                child: Text(existing == null ? 'Create Zikr' : 'Save Changes'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  name.dispose();
  arabic.dispose();
  description.dispose();
  target.dispose();
  starting.dispose();
  notes.dispose();
  return result;
}

Future<void> showSessionForm(
  BuildContext context,
  WidgetRef ref,
  Zikr zikr, {
  ZikrSession? existing,
}) async {
  final amount = TextEditingController(text: existing?.amount.toString());
  final note = TextEditingController(text: existing?.note);
  final settings = ref.read(settingsProvider).settings;
  var label = existing?.label ?? settings.defaultSessionLabel;
  var timestamp = existing?.timestamp ?? DateTime.now();
  var submitted = false;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              existing == null ? 'Add Session' : 'Edit Session',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(zikr.name),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: amount,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Completed amount',
                prefixIcon: Icon(Icons.add_task_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final suggestion in [33, 100, 313, 500, 1000])
                  ActionChip(
                    label: Text(formatQuantity(suggestion)),
                    onPressed: () => amount.text = suggestion.toString(),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: label,
              decoration: const InputDecoration(labelText: 'Session label'),
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
                        (item) =>
                            DropdownMenuItem(value: item, child: Text(item)),
                      )
                      .toList(),
              onChanged: (value) {
                if (value != null) setModalState(() => label = value);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: const Text('Session date and time'),
              subtitle: Text(
                '${formatDate(timestamp)} · ${formatTime(timestamp)}',
              ),
              trailing: const Icon(Icons.edit_calendar_outlined),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now().add(const Duration(days: 1)),
                  initialDate: timestamp,
                );
                if (date == null || !context.mounted) return;
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(timestamp),
                );
                if (time == null) return;
                setModalState(
                  () => timestamp = DateTime(
                    date.year,
                    date.month,
                    date.day,
                    time.hour,
                    time.minute,
                  ),
                );
              },
            ),
            TextField(
              controller: note,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'For example, after Fajr',
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: () async {
                if (submitted) return;
                final value = int.tryParse(amount.text);
                if (value == null || value <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Enter a positive amount.')),
                  );
                  return;
                }
                if (value >= 1000000 || zikr.completed + value > zikr.target) {
                  final proceed = await showConfirmDialog(
                    context,
                    title: value >= 1000000
                        ? 'Unusually large session'
                        : 'This exceeds the target',
                    message: 'Review the amount before saving.',
                    confirmLabel: 'Save Session',
                  );
                  if (!proceed || !context.mounted) return;
                }
                submitted = true;
                if (existing == null) {
                  await ref
                      .read(zikrProvider.notifier)
                      .addSession(
                        zikr.id,
                        value,
                        timestamp: timestamp,
                        note: note.text,
                        label: label,
                      );
                } else {
                  await ref
                      .read(zikrProvider.notifier)
                      .editSession(
                        existing,
                        amount: value,
                        timestamp: timestamp,
                        note: note.text,
                        label: label,
                      );
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save Session'),
            ),
          ],
        ),
      ),
    ),
  );
  amount.dispose();
  note.dispose();
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
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: destructive
                  ? FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                    )
                  : null,
              onPressed: () => Navigator.pop(context, true),
              child: Text(confirmLabel),
            ),
          ],
        ),
      ) ??
      false;
}
