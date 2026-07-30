import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/section_title.dart';
import '../../domain/models/app_settings.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_input_sheets.dart';
import '../widgets/settings_section.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: AppSpacing.pagePadding,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle(
                  title: 'Settings',
                  subtitle: 'Make Tasbeeh Tracker feel like your own.',
                ),
                const SizedBox(height: AppSpacing.lg),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final sectionWidth = constraints.maxWidth >= 760
                        ? (constraints.maxWidth - AppSpacing.lg) / 2
                        : constraints.maxWidth;
                    return Wrap(
                      spacing: AppSpacing.lg,
                      runSpacing: AppSpacing.lg,
                      children: [
                        SizedBox(
                          width: sectionWidth,
                          child: const _AppearanceSection(),
                        ),
                        SizedBox(
                          width: sectionWidth,
                          child: const _CounterSection(),
                        ),
                        SizedBox(
                          width: sectionWidth,
                          child: const _DataSection(),
                        ),
                        SizedBox(
                          width: sectionWidth,
                          child: const _AboutSection(),
                        ),
                        SizedBox(
                          width: sectionWidth,
                          child: const _SupportSection(),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppearanceSection extends ConsumerWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(
      settingsProvider.select((state) => state.settings.theme),
    );
    final notifier = ref.read(settingsProvider.notifier);

    return SettingsSection(
      title: 'Appearance',
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<AppThemePreference>(
              segments: const [
                ButtonSegment(
                  value: AppThemePreference.system,
                  icon: Icon(Icons.brightness_auto_rounded),
                  label: Text('System'),
                ),
                ButtonSegment(
                  value: AppThemePreference.light,
                  icon: Icon(Icons.light_mode_outlined),
                  label: Text('Light'),
                ),
                ButtonSegment(
                  value: AppThemePreference.dark,
                  icon: Icon(Icons.dark_mode_outlined),
                  label: Text('Dark'),
                ),
              ],
              selected: {theme},
              onSelectionChanged: (selection) {
                notifier.setTheme(selection.first);
              },
              showSelectedIcon: false,
            ),
          ),
        ),
      ],
    );
  }
}

class _CounterSection extends ConsumerWidget {
  const _CounterSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(
      settingsProvider.select((state) => state.settings),
    );
    final notifier = ref.read(settingsProvider.notifier);

    return SettingsSection(
      title: 'Counter',
      children: [
        ListTile(
          leading: const Icon(Icons.flag_outlined),
          title: const Text('Default Target'),
          subtitle: Text('${settings.defaultTarget}'),
          onTap: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (context) => DefaultTargetSheet(
              currentTarget: settings.defaultTarget,
              onSubmit: notifier.setDefaultTarget,
            ),
          ),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.vibration_rounded),
          title: const Text('Haptic Feedback'),
          value: settings.hapticFeedbackEnabled,
          onChanged: notifier.setHapticFeedback,
        ),
        SwitchListTile(
          secondary: const Icon(Icons.animation_rounded),
          title: const Text('Counter Animation'),
          value: settings.counterAnimationEnabled,
          onChanged: notifier.setCounterAnimation,
        ),
        ListTile(
          leading: const Icon(Icons.speed_rounded),
          title: const Text('Continuous Count Speed'),
          subtitle: Text(_speedLabel(settings.continuousCountSpeed)),
          onTap: () => _showSpeedSheet(
            context,
            settings.continuousCountSpeed,
            notifier.setContinuousCountSpeed,
          ),
        ),
      ],
    );
  }

  String _speedLabel(ContinuousCountSpeed speed) {
    return switch (speed) {
      ContinuousCountSpeed.slow => 'Slow',
      ContinuousCountSpeed.normal => 'Normal',
      ContinuousCountSpeed.fast => 'Fast',
    };
  }

  Future<void> _showSpeedSheet(
    BuildContext context,
    ContinuousCountSpeed selected,
    ValueChanged<ContinuousCountSpeed> onSelected,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final speed in ContinuousCountSpeed.values)
              ListTile(
                title: Text(_speedLabel(speed)),
                selected: speed == selected,
                trailing: speed == selected
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () {
                  onSelected(speed);
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _DataSection extends ConsumerWidget {
  const _DataSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isProcessing = ref.watch(
      settingsProvider.select((state) => state.isProcessingData),
    );
    final notifier = ref.read(settingsProvider.notifier);

    return SettingsSection(
      title: 'Data',
      children: [
        ListTile(
          enabled: !isProcessing,
          leading: const Icon(Icons.ios_share_rounded),
          title: const Text('Export Data'),
          onTap: () async {
            final backup = await notifier.exportData();
            if (context.mounted) {
              await SharePlus.instance.share(
                ShareParams(
                  subject: 'Tasbeeh Tracker Backup',
                  text: backup,
                  sharePositionOrigin: _shareOrigin(context),
                ),
              );
            }
          },
        ),
        ListTile(
          enabled: !isProcessing,
          leading: const Icon(Icons.settings_backup_restore_rounded),
          title: const Text('Import Backup'),
          onTap: () async {
            final imported = await showModalBottomSheet<bool>(
              context: context,
              isScrollControlled: true,
              builder: (context) =>
                  ImportBackupSheet(onSubmit: notifier.importData),
            );
            if (context.mounted && imported == true) {
              _showMessage(context, 'Backup imported successfully.');
            }
          },
        ),
        _DestructiveTile(
          title: 'Reset History',
          icon: Icons.delete_sweep_outlined,
          enabled: !isProcessing,
          onConfirmed: notifier.resetHistory,
        ),
        _DestructiveTile(
          title: 'Reset Statistics',
          icon: Icons.restart_alt_rounded,
          enabled: !isProcessing,
          onConfirmed: notifier.resetStatistics,
        ),
        _DestructiveTile(
          title: 'Reset Everything',
          icon: Icons.delete_forever_outlined,
          enabled: !isProcessing,
          onConfirmed: notifier.resetEverything,
        ),
      ],
    );
  }
}

class _AboutSection extends ConsumerWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(
      settingsProvider.select((state) => state.appVersion),
    );
    final build = ref.watch(
      settingsProvider.select((state) => state.buildNumber),
    );

    return SettingsSection(
      title: 'About',
      children: [
        ListTile(
          leading: const Icon(Icons.info_outline_rounded),
          title: const Text('App Version'),
          trailing: Text(version),
        ),
        ListTile(
          leading: const Icon(Icons.numbers_rounded),
          title: const Text('Build Number'),
          trailing: Text(build),
        ),
        ListTile(
          leading: const Icon(Icons.description_outlined),
          title: const Text('Licenses'),
          onTap: () => showLicensePage(
            context: context,
            applicationName: 'Tasbeeh Tracker',
            applicationVersion: '$version ($build)',
          ),
        ),
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: const Text('Privacy Policy'),
          onTap: () => _showInformationSheet(
            context,
            'Privacy Policy',
            'Tasbeeh Tracker stores counter data locally on your device. '
                'Backups are shared only when you explicitly export them.',
          ),
        ),
        ListTile(
          leading: const Icon(Icons.gavel_outlined),
          title: const Text('Terms'),
          onTap: () => _showInformationSheet(
            context,
            'Terms',
            'Tasbeeh Tracker is provided as a personal remembrance aid. '
                'You remain responsible for safeguarding exported backups.',
          ),
        ),
        ListTile(
          leading: const Icon(Icons.code_rounded),
          title: const Text('Developer'),
          subtitle: const Text('Musaddiq'),
          onTap: () => _showInformationSheet(
            context,
            'Developer',
            'Designed and developed with care by Musaddiq.',
          ),
        ),
      ],
    );
  }
}

class _SupportSection extends ConsumerWidget {
  const _SupportSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(
      settingsProvider.select((state) => state.appVersion),
    );

    return SettingsSection(
      title: 'Support',
      children: [
        ListTile(
          leading: const Icon(Icons.star_outline_rounded),
          title: const Text('Rate App'),
          onTap: () async {
            final review = InAppReview.instance;
            if (await review.isAvailable()) {
              await review.requestReview();
            } else if (context.mounted) {
              _showMessage(context, 'Rating is unavailable on this device.');
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.share_outlined),
          title: const Text('Share App'),
          onTap: () => SharePlus.instance.share(
            ShareParams(
              text: 'Tasbeeh Tracker — a mindful companion for daily dhikr.',
              sharePositionOrigin: _shareOrigin(context),
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.bug_report_outlined),
          title: const Text('Report Issue'),
          onTap: () => SharePlus.instance.share(
            ShareParams(
              subject: 'Tasbeeh Tracker Issue',
              text:
                  'I found an issue in Tasbeeh Tracker v$version.\n\n'
                  'What happened:\n',
              sharePositionOrigin: _shareOrigin(context),
            ),
          ),
        ),
      ],
    );
  }
}

class _DestructiveTile extends StatelessWidget {
  const _DestructiveTile({
    required this.title,
    required this.icon,
    required this.enabled,
    required this.onConfirmed,
  });

  final String title;
  final IconData icon;
  final bool enabled;
  final Future<void> Function() onConfirmed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      enabled: enabled,
      leading: Icon(icon, color: theme.colorScheme.error),
      title: Text(title, style: TextStyle(color: theme.colorScheme.error)),
      onTap: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(
              'This action cannot be undone. Do you want to continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Continue'),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await onConfirmed();
          if (context.mounted) {
            _showMessage(context, '$title completed.');
          }
        }
      },
    );
  }
}

Future<void> _showInformationSheet(
  BuildContext context,
  String title,
  String body,
) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            Text(body),
            const SizedBox(height: AppSpacing.lg),
            if (title == 'Developer')
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(
                    const ClipboardData(text: 'support@tasbeehtracker.app'),
                  );
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Copy Support Email'),
              ),
          ],
        ),
      ),
    ),
  );
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Rect? _shareOrigin(BuildContext context) {
  final renderObject = context.findRenderObject();
  if (renderObject is! RenderBox || !renderObject.hasSize) {
    return null;
  }
  return renderObject.localToGlobal(Offset.zero) & renderObject.size;
}
