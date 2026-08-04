import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const String displayedVersion = 'v1.0.0';
  static const String developerName = 'Syed Musaddiq Hussainy';
  static const String lastUpdated = 'August 1, 2026';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.emerald950,
      appBar: AppBar(
        backgroundColor: AppColors.emerald950,
        foregroundColor: AppColors.goldBright,
        iconTheme: const IconThemeData(color: AppColors.goldBright),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            color: AppColors.goldBright,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Privacy Policy',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.goldBright,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Last updated: $lastUpdated',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.softGold,
                      fontStyle: FontStyle.italic,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Developer: $developerName',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.softGold,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Divider(
                height: AppSpacing.xl,
                color: AppColors.goldMuted.withValues(alpha: 0.4),
              ),
              _buildSection(
                context,
                '1. Offline-First Operation',
                'The application is primarily designed as an offline-first Zikr management and reflection application. Your spiritual tracking experience functions locally on your device without requiring continuous internet connectivity.',
              ),
              _buildSection(
                context,
                '2. Local Data Storage',
                'Zikr records, main targets, Live Zikr progress, completed count histories, custom session labels, optional reflection notes, and application preferences are stored locally on your device using Hive storage.',
              ),
              _buildSection(
                context,
                '3. No Account Requirement',
                'No account registration, user profile, password, or login is required to use this application.',
              ),
              _buildSection(
                context,
                '4. Translation Language Models',
                'When automatic Arabic translation is enabled in Preferences, the application may request and download English and Arabic Google ML Kit language models over the internet.',
              ),
              _buildSection(
                context,
                '5. On-Device Translation',
                'After the required translation models are downloaded onto your device, translation operations run on-device and function offline.',
              ),
              _buildSection(
                context,
                '6. Translation Limitations',
                'Automatic machine translation may not always be completely accurate or nuanced. Users should review and verify translated Arabic names before relying on them.',
              ),
              _buildSection(
                context,
                '7. Platform Actions',
                'The application may invoke standard system sharing dialogs or app-store review interfaces only when explicitly requested by you.',
              ),
              _buildSection(
                context,
                '8. Internet and Network Permissions',
                'Network access is used for downloading translation language models and executing explicit user sharing or review requests. The application does not upload your personal Zikr data to external servers.',
              ),
              _buildSection(
                context,
                '9. No Intentional Sale of Information',
                'The developer does not collect, track, or intentionally sell users\' personal information.',
              ),
              _buildSection(
                context,
                '10. Data Removal and Clearing',
                'Uninstalling the application or selecting "Clear All Data" in Settings permanently removes locally stored application data from your device.',
              ),
              _buildSection(
                context,
                '11. Device Backups',
                'Automatic device backups may be managed by Android or iOS according to your operating system settings and platform backup configuration.',
              ),
              _buildSection(
                context,
                '12. Sensitive Information in Notes',
                'Users are advised not to store highly sensitive financial, medical, or confidential personal identification numbers in optional session notes.',
              ),
              _buildSection(
                context,
                '13. Security Limitations',
                'Local database files are stored within the application\'s isolated app storage sandbox. Local encryption is not applied to standard Hive storage unless specified.',
              ),
              _buildSection(
                context,
                '14. Third-Party Technologies',
                'The application utilizes verified third-party technologies such as Google ML Kit for on-device machine translation, Flutter SDK libraries, and native device haptic hardware.',
              ),
              _buildSection(
                context,
                '15. Policy Updates',
                'This Privacy Policy may be updated periodically to reflect new features or platform requirements.',
              ),
              _buildSection(
                context,
                '16. Developer Contact',
                'Developer: $developerName\nApp Version: $displayedVersion\nSupport Email: support@riontix.com',
              ),
              _buildSection(
                context,
                '17. Customer Support & Issue Reports',
                'Users may choose to contact support or prepare issue reports through their installed device email application. Information entered into a support email is shared only when the user explicitly reviews and sends that email. The application does not silently transmit support data or issue reports in the background.',
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    String content,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.goldBright,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.ivory,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}
