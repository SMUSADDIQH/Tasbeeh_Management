import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';

class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

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
          'Terms of Use',
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
                'Terms of Use',
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
                '1. Acceptance of Terms',
                'By installing or using this application, you agree to be bound by these Terms of Use. If you do not agree to these terms, please do not use the application.',
              ),
              _buildSection(
                context,
                '2. Purpose of the Application',
                'The application is intended to help users organize personal Zikr goals, track counts, manage sessions, and maintain spiritual reflection records.',
              ),
              _buildSection(
                context,
                '3. Personal and Non-Commercial Use',
                'The application is provided for your personal, non-commercial use in accordance with applicable laws.',
              ),
              _buildSection(
                context,
                '4. User-Entered Content',
                'You are solely responsible for all content, Zikr names, Arabic text, targets, session counts, custom labels, and notes that you enter into the application.',
              ),
              _buildSection(
                context,
                '5. Device Storage and Data Loss',
                'Application data is stored primarily on your local device. Data may be lost due to uninstalling the app, clearing app storage, operating system actions, hardware failure, or lack of external backups.',
              ),
              _buildSection(
                context,
                '6. Translation Limitations',
                'Automatic Arabic translation features may produce incomplete or inaccurate results. Users are responsible for reviewing translated text before saving.',
              ),
              _buildSection(
                context,
                '7. Count and Progress Accuracy',
                'Users are responsible for verifying their Zikr counts, Live Zikr targets, manual session entries, and completed progress records.',
              ),
              _buildSection(
                context,
                '8. No Religious Advice',
                'The application is a productivity and tracking tool. It does not provide official religious rulings, fatwas, or qualified religious guidance.',
              ),
              _buildSection(
                context,
                '9. No Medical, Legal, or Financial Advice',
                'The application does not provide medical, psychological, legal, or financial advice.',
              ),
              _buildSection(
                context,
                '10. Intellectual Property',
                'The application\'s original branding, design, user interface, and code belong to the developer. No ownership is claimed over traditional religious texts or prayers.',
              ),
              _buildSection(
                context,
                '11. Prohibited Misuse',
                'You agree not to misuse the application, attempt unauthorized access, reverse engineer where prohibited by law, or interfere with application functionality.',
              ),
              _buildSection(
                context,
                '12. Disclaimer of Warranties',
                'The application is provided on an "as is" and "as available" basis without warranties of any kind, express or implied.',
              ),
              _buildSection(
                context,
                '13. Limitation of Liability',
                'To the maximum extent permitted by law, the developer shall not be liable for any indirect, incidental, or consequential damages arising from app use or data loss.',
              ),
              _buildSection(
                context,
                '14. Changes to Terms',
                'The developer reserves the right to modify these Terms of Use at any time. Continued use of the application constitutes acceptance of updated terms.',
              ),
              _buildSection(
                context,
                '15. Developer Contact',
                'Developer: $developerName\nApp Version: $displayedVersion',
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
