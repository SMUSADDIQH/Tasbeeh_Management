import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/islamic_artwork.dart';
import '../../../zikr/data/backup_service.dart';
import '../../../zikr/presentation/widgets/zikr_widgets.dart';
import '../../../zikr/presentation/zikr_provider.dart';
import '../../domain/models/app_settings.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_section.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsProvider);
    final settings = state.settings;
    return ListView(
      key: const PageStorageKey('settings-scroll'),
      children: [
        const _SettingsHeader(),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
            120,
          ),
          child: Column(
            children: [
              SettingsSection(
                title: 'Appearance',
                children: [_ThemeTile(settings: settings)],
              ),
              const SizedBox(height: AppSpacing.lg),
              SettingsSection(
                title: 'Preferences',
                children: [
                  const ListTile(
                    leading: Icon(Icons.language_outlined),
                    title: Text('Language'),
                    subtitle: Text('English · more languages coming later'),
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.vibration_outlined),
                    title: const Text('Haptic feedback'),
                    value: settings.hapticFeedbackEnabled,
                    onChanged: ref.read(settingsProvider.notifier).setHaptics,
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.animation_outlined),
                    title: const Text('Animations'),
                    value: settings.animationsEnabled,
                    onChanged: ref
                        .read(settingsProvider.notifier)
                        .setAnimations,
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.translate_rounded),
                    title: const Text('Auto-translate Zikr names'),
                    subtitle: const Text(
                      'Translate English Zikr names into Arabic while typing.',
                    ),
                    value: settings.autoTranslateZikrName,
                    onChanged: ref
                        .read(settingsProvider.notifier)
                        .setAutoTranslateZikrName,
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications_none_rounded),
                    title: const Text('Reminders'),
                    subtitle: const Text(
                      'Unavailable until reminders are configured',
                    ),
                    value: settings.remindersEnabled,
                    onChanged: null,
                  ),
                  ListTile(
                    leading: const Icon(Icons.label_outline),
                    title: const Text('Default session label'),
                    subtitle: Text(settings.defaultSessionLabel),
                    onTap: () => _chooseLabel(context, ref, settings),
                  ),
                  ListTile(
                    leading: const Icon(Icons.flag_outlined),
                    title: const Text('Default Zikr target'),
                    subtitle: Text('${settings.defaultTarget}'),
                    onTap: () => _changeTarget(context, ref, settings),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              SettingsSection(
                title: 'Zikr & Data',
                children: [
                  ListTile(
                    leading: const Icon(Icons.backup_outlined),
                    title: const Text('Backup and Restore'),
                    subtitle: const Text('Version 2 JSON · merge or replace'),
                    onTap: () => _dataSheet(context, ref, settings),
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_sweep_outlined),
                    title: const Text('Clear History'),
                    onTap: () => _clearHistory(context, ref),
                  ),
                  ListTile(
                    leading: const Icon(Icons.restart_alt_rounded),
                    title: const Text('Clear All Data'),
                    onTap: () => _clearAll(context, ref),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              SettingsSection(
                title: 'Support',
                children: [
                  const ListTile(
                    leading: Icon(Icons.help_outline),
                    title: Text('Help and Support'),
                    subtitle: Text('support@example.com'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.bug_report_outlined),
                    title: const Text('Report Issue'),
                    onTap: () => SharePlus.instance.share(
                      ShareParams(
                        text:
                            'Issue report for app version ${state.appVersion} '
                            '(${state.buildNumber})',
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.star_outline),
                    title: const Text('Rate App'),
                    onTap: InAppReview.instance.openStoreListing,
                  ),
                  ListTile(
                    leading: const Icon(Icons.share_outlined),
                    title: const Text('Share App'),
                    onTap: () => SharePlus.instance.share(
                      ShareParams(
                        text:
                            'A calm, offline-first way to manage Zikr goals and sessions.',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              SettingsSection(
                title: 'About',
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('Version'),
                    subtitle: Text(
                      '${state.appVersion} (${state.buildNumber})',
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.balance_outlined),
                    title: const Text('Licenses'),
                    onTap: () => showLicensePage(context: context),
                  ),
                  const ListTile(
                    leading: Icon(Icons.privacy_tip_outlined),
                    title: Text('Privacy Policy'),
                    subtitle: Text('All Zikr data remains on this device'),
                  ),
                  const ListTile(
                    leading: Icon(Icons.description_outlined),
                    title: Text('Terms'),
                    subtitle: Text('Personal reflection and record keeping'),
                  ),
                  const ListTile(
                    leading: Icon(Icons.code_outlined),
                    title: Text('Developer'),
                    subtitle: Text('Musaddiq'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _chooseLabel(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) async {
    final label = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: RadioGroup<String>(
          groupValue: settings.defaultSessionLabel,
          onChanged: (value) => Navigator.pop(context, value),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final item in const [
                'Morning',
                'After Fajr',
                'Afternoon',
                'Evening',
                'Night',
                'Custom',
              ])
                RadioListTile<String>(title: Text(item), value: item),
            ],
          ),
        ),
      ),
    );
    if (label != null) {
      await ref.read(settingsProvider.notifier).setDefaultLabel(label);
    }
  }

  Future<void> _changeTarget(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) async {
    final controller = TextEditingController(text: '${settings.defaultTarget}');
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Default Zikr target'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(labelText: 'Target'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (await ref
                  .read(settingsProvider.notifier)
                  .setDefaultTarget(controller.text)) {
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
  }

  Future<void> _dataSheet(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Backup and Restore',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.tonalIcon(
              onPressed: () async {
                final data = await ref
                    .read(zikrProvider.notifier)
                    .exportBackup(preferences: settings.toMap());
                await Clipboard.setData(ClipboardData(text: data));
                if (sheetContext.mounted) {
                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                    const SnackBar(
                      content: Text('Version 2 backup copied to clipboard.'),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.copy_outlined),
              label: const Text('Export Data'),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () async {
                Navigator.pop(sheetContext);
                await _importDialog(context, ref);
              },
              icon: const Icon(Icons.restore_outlined),
              label: const Text('Import Data'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    var mode = ImportMode.merge;
    String? error;
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Import Version 2 backup'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  maxLines: 8,
                  decoration: InputDecoration(
                    labelText: 'Paste backup JSON',
                    errorText: error,
                  ),
                ),
                RadioGroup<ImportMode>(
                  groupValue: mode,
                  onChanged: (value) {
                    if (value != null) setDialogState(() => mode = value);
                  },
                  child: const Column(
                    children: [
                      RadioListTile<ImportMode>(
                        title: Text('Merge'),
                        subtitle: Text(
                          'Keep existing IDs and add backup records',
                        ),
                        value: ImportMode.merge,
                      ),
                      RadioListTile<ImportMode>(
                        title: Text('Replace'),
                        subtitle: Text('Replace all current Zikr and sessions'),
                        value: ImportMode.replace,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                try {
                  final summary = await ref
                      .read(zikrProvider.notifier)
                      .importBackup(controller.text, mode);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Imported ${summary.zikrCount} Zikr and '
                          '${summary.sessionCount} sessions.',
                        ),
                      ),
                    );
                  }
                } on FormatException catch (exception) {
                  setDialogState(() => error = exception.message);
                }
              },
              child: const Text('Import'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
  }

  Future<void> _clearHistory(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Clear session history?',
      message: 'All completed totals will return to zero.',
      confirmLabel: 'Clear History',
      destructive: true,
    );
    if (confirmed) await ref.read(zikrProvider.notifier).clearHistory();
  }

  Future<void> _clearAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Clear all data?',
      message:
          'Every Zikr, session, and preference will be permanently removed.',
      confirmLabel: 'Clear All Data',
      destructive: true,
    );
    if (confirmed) {
      await ref.read(zikrProvider.notifier).clearAll();
      await ref.read(settingsProvider.notifier).reset();
    }
  }
}

class _SettingsHeader extends ConsumerWidget {
  const _SettingsHeader();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.goldMuted.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: GreetingHeaderBackgroundWidget()),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Settings',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: AppColors.goldBright,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Customize your experience',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.gold.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                const IslamicAppLogo(size: 48, borderRadius: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeTile extends ConsumerWidget {
  const _ThemeTile({required this.settings});
  final AppSettings settings;
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      RadioGroup<AppThemePreference>(
        groupValue: settings.theme,
        onChanged: (value) {
          if (value != null) {
            ref.read(settingsProvider.notifier).setTheme(value);
          }
        },
        child: Column(
          children: [
            for (final theme in AppThemePreference.values)
              RadioListTile<AppThemePreference>(
                title: Text(switch (theme) {
                  AppThemePreference.system => 'System',
                  AppThemePreference.light => 'Light',
                  AppThemePreference.dark => 'Dark',
                }),
                value: theme,
              ),
          ],
        ),
      );
}
