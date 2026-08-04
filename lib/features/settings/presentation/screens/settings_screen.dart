import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/islamic_artwork.dart';
import '../../../zikr/data/arabic_name_translation_service.dart';
import '../../../zikr/data/backup_service.dart';
import '../../../zikr/domain/zikr_models.dart';
import '../../../zikr/presentation/widgets/zikr_widgets.dart';
import '../../../zikr/presentation/zikr_provider.dart';
import '../../domain/models/app_settings.dart';
import '../providers/settings_provider.dart';
import '../services/app_share_service.dart';
import '../widgets/settings_section.dart';
import 'privacy_policy_screen.dart';
import 'report_issue_screen.dart';
import 'terms_of_use_screen.dart';

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
                    secondary: const Icon(Icons.animation_outlined),
                    title: const Text('Animations'),
                    value: settings.animationsEnabled,
                    onChanged: ref
                        .read(settingsProvider.notifier)
                        .setAnimations,
                  ),
                  _AutoTranslateTile(settings: settings),
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
                  ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: const Text('Help and Support'),
                    subtitle: const Text('support@riontix.com'),
                    onTap: () => _launchHelpSupportEmail(context),
                  ),
                  ListTile(
                    leading: const Icon(Icons.bug_report_outlined),
                    title: const Text('Report Issue'),
                    subtitle: const Text('Describe an issue and email support'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const ReportIssueScreen(),
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
                    onTap: () => const AppShareService().shareApp(context),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              SettingsSection(
                title: 'About',
                children: [
                  const ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('Version'),
                    subtitle: Text('v1.0.0'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.balance_outlined),
                    title: const Text('Licenses'),
                    onTap: () => showLicensePage(context: context),
                  ),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: const Text('Privacy Policy'),
                    subtitle: const Text('All Zikr data remains on this device'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const PrivacyPolicyScreen(),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: const Text('Terms of Use'),
                    subtitle: const Text('Personal reflection and record keeping'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const TermsOfUseScreen(),
                      ),
                    ),
                  ),
                  const ListTile(
                    leading: Icon(Icons.code_outlined),
                    title: Text('Developer'),
                    subtitle: Text('Syed Musaddiq Hussainy'),
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

  Future<void> _launchHelpSupportEmail(BuildContext context) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@riontix.com',
      queryParameters: {
        'subject': 'Tasbeeh Management — Help and Support',
        'body': 'Hi Riontix Support,\n\nI need assistance with:\n\n',
      },
    );
    bool launched = false;
    try {
      if (await canLaunchUrl(emailUri)) {
        launched = await launchUrl(emailUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      launched = false;
    }
    if (!launched && context.mounted) {
      _showNoEmailAppDialog(context);
    }
  }

  void _showNoEmailAppDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.emerald900,
        title: const Text(
          'No email app found',
          style: TextStyle(
            color: AppColors.goldBright,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'No email app was found. Please contact support@riontix.com manually.',
          style: TextStyle(color: AppColors.ivory),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Close',
              style: TextStyle(color: AppColors.softGold),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.goldBright,
              foregroundColor: AppColors.emerald950,
            ),
            onPressed: () {
              Clipboard.setData(
                const ClipboardData(text: 'support@riontix.com'),
              );
              Navigator.pop(dialogContext);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Copied support@riontix.com to clipboard.'),
                  ),
                );
              }
            },
            child: const Text('Copy Email'),
          ),
        ],
      ),
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
              for (final item in kPredefinedSessionLabels)
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

class _AutoTranslateTile extends ConsumerStatefulWidget {
  const _AutoTranslateTile({required this.settings});
  final AppSettings settings;

  @override
  ConsumerState<_AutoTranslateTile> createState() => _AutoTranslateTileState();
}

class _AutoTranslateTileState extends ConsumerState<_AutoTranslateTile> {
  bool _isChecking = false;
  bool _isDownloading = false;
  bool? _isReady;
  String? _statusText;

  @override
  void initState() {
    super.initState();
    if (widget.settings.autoTranslateZikrName) {
      _checkAndPrepare(force: false);
    }
  }

  Future<void> _checkAndPrepare({bool force = false}) async {
    if (!mounted) return;
    setState(() {
      _isChecking = !force;
      _isDownloading = force;
      _statusText = force ? 'Downloading offline translation…' : null;
    });

    final service = ref.read(arabicTranslationServiceProvider);
    final ready = await service.prepareModels(
      onProgress: (msg) {
        if (mounted) setState(() => _statusText = msg);
      },
      force: force,
    );

    if (mounted) {
      setState(() {
        _isChecking = false;
        _isDownloading = false;
        _isReady = ready;
        _statusText = ready
            ? 'Offline Arabic translation ready'
            : 'Translation model unavailable';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.settings.autoTranslateZikrName;
    return Column(
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.translate_rounded),
          title: const Text('Auto-translate Zikr names'),
          subtitle: const Text(
            'Translate English Zikr names into Arabic while typing.',
          ),
          value: enabled,
          onChanged: (val) async {
            await ref.read(settingsProvider.notifier).setAutoTranslateZikrName(val);
            if (val) {
              _checkAndPrepare(force: true);
            } else {
              setState(() {
                _isReady = null;
                _statusText = null;
              });
            }
          },
        ),
        if (enabled && (_statusText != null || _isChecking || _isDownloading)) ...[
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                const SizedBox(width: 40),
                Expanded(
                  child: Text(
                    _statusText ?? 'Checking offline translation models…',
                    style: TextStyle(
                      fontSize: 12,
                      color: _isReady == true
                          ? AppColors.goldBright
                          : AppColors.mutedGold,
                    ),
                  ),
                ),
                if (_isReady == false && !_isDownloading)
                  TextButton(
                    onPressed: () => _checkAndPrepare(force: true),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Retry Download',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
