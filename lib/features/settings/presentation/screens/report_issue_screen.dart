import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  static const String supportEmail = 'support@riontix.com';
  static const String appVersion = 'v1.0.0';

  static const List<String> categories = [
    'App Functionality',
    'Live Zikr',
    'Manual Entry',
    'Translation',
    'History',
    'Settings',
    'Design or Display',
    'Data or Progress',
    'Other',
  ];

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  final _emailKey = GlobalKey();
  final _subjectKey = GlobalKey();
  final _descriptionKey = GlobalKey();

  final _emailFocusNode = FocusNode();
  final _subjectFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();

  late final TextEditingController _emailController;
  late final TextEditingController _subjectController;
  late final TextEditingController _descriptionController;

  String _selectedCategory = 'App Functionality';
  bool _isSubmitting = false;

  static final RegExp _emailRegex = RegExp(
    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
  );

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _subjectController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _subjectController.dispose();
    _descriptionController.dispose();
    _emailFocusNode.dispose();
    _subjectFocusNode.dispose();
    _descriptionFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Your email address is required.';
    }
    if (!_emailRegex.hasMatch(trimmed)) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  String? _validateSubject(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Issue subject is required.';
    }
    if (trimmed.length < 4 || trimmed.length > 120) {
      return 'Subject must be between 4 and 120 characters.';
    }
    return null;
  }

  String? _validateDescription(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Issue description is required.';
    }
    if (trimmed.length < 15) {
      return 'Please provide a description of at least 15 characters.';
    }
    if (trimmed.length > 3000) {
      return 'Description cannot exceed 3000 characters.';
    }
    return null;
  }

  void _scrollToKey(GlobalKey key, FocusNode node) {
    node.requestFocus();
    if (key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _prepareEmailReport() async {
    if (_isSubmitting) return;

    final emailError = _validateEmail(_emailController.text);
    if (emailError != null) {
      _formKey.currentState?.validate();
      _scrollToKey(_emailKey, _emailFocusNode);
      return;
    }

    final subjectError = _validateSubject(_subjectController.text);
    if (subjectError != null) {
      _formKey.currentState?.validate();
      _scrollToKey(_subjectKey, _subjectFocusNode);
      return;
    }

    final descError = _validateDescription(_descriptionController.text);
    if (descError != null) {
      _formKey.currentState?.validate();
      _scrollToKey(_descriptionKey, _descriptionFocusNode);
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);

    final email = _emailController.text.trim();
    final subject = _subjectController.text.trim();
    final description = _descriptionController.text.trim();
    final platformStr = defaultTargetPlatform == TargetPlatform.android
        ? 'Android'
        : defaultTargetPlatform == TargetPlatform.iOS
            ? 'iOS'
            : 'Desktop/Other';

    final bodyText = '''
Tasbeeh Management Issue Report

Reporter Email:
$email

Category:
$_selectedCategory

Subject:
$subject

Issue Description:
$description

App Version:
${ReportIssueScreen.appVersion}

Platform:
$platformStr''';

    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: ReportIssueScreen.supportEmail,
      queryParameters: {
        'subject': '[Tasbeeh Management Issue] $subject',
        'body': bodyText,
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

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (!launched) {
        _showNoEmailAppDialog();
      }
    }
  }

  void _showNoEmailAppDialog() {
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
                const ClipboardData(text: ReportIssueScreen.supportEmail),
              );
              Navigator.pop(dialogContext);
              if (mounted) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.emerald950,
      appBar: AppBar(
        backgroundColor: AppColors.emerald950,
        foregroundColor: AppColors.goldBright,
        iconTheme: const IconThemeData(color: AppColors.goldBright),
        title: const Text(
          'Report an Issue',
          style: TextStyle(
            color: AppColors.goldBright,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.disabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Report an Issue',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.goldBright,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Describe the problem and we’ll prepare an email for Riontix Support.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.softGold,
                      ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // 1. Reporter Email
                TextFormField(
                  key: _emailKey,
                  focusNode: _emailFocusNode,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  style: const TextStyle(color: AppColors.ivory),
                  decoration: const InputDecoration(
                    labelText: 'Your email address',
                    hintText: 'name@example.com',
                    labelStyle: TextStyle(color: AppColors.softGold),
                    hintStyle: TextStyle(color: AppColors.mutedGold),
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: AppColors.goldBright,
                    ),
                    errorStyle: TextStyle(color: AppColors.error),
                  ),
                  validator: _validateEmail,
                ),
                const SizedBox(height: AppSpacing.md),

                // 2. Issue Subject
                TextFormField(
                  key: _subjectKey,
                  focusNode: _subjectFocusNode,
                  controller: _subjectController,
                  maxLength: 120,
                  style: const TextStyle(color: AppColors.ivory),
                  decoration: const InputDecoration(
                    labelText: 'Issue subject',
                    hintText: 'Briefly describe the issue',
                    labelStyle: TextStyle(color: AppColors.softGold),
                    hintStyle: TextStyle(color: AppColors.mutedGold),
                    prefixIcon: Icon(
                      Icons.subject_outlined,
                      color: AppColors.goldBright,
                    ),
                    errorStyle: TextStyle(color: AppColors.error),
                  ),
                  validator: _validateSubject,
                ),
                const SizedBox(height: AppSpacing.sm),

                // 3. Category Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  dropdownColor: AppColors.emerald900,
                  style: const TextStyle(color: AppColors.ivory),
                  decoration: const InputDecoration(
                    labelText: 'Issue Category',
                    labelStyle: TextStyle(color: AppColors.softGold),
                    prefixIcon: Icon(
                      Icons.category_outlined,
                      color: AppColors.goldBright,
                    ),
                  ),
                  items: ReportIssueScreen.categories
                      .map(
                        (cat) => DropdownMenuItem<String>(
                          value: cat,
                          child: Text(
                            cat,
                            style: const TextStyle(color: AppColors.ivory),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedCategory = val);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // 4. Issue Description
                TextFormField(
                  key: _descriptionKey,
                  focusNode: _descriptionFocusNode,
                  controller: _descriptionController,
                  keyboardType: TextInputType.multiline,
                  minLines: 4,
                  maxLines: 8,
                  maxLength: 3000,
                  style: const TextStyle(color: AppColors.ivory),
                  decoration: const InputDecoration(
                    labelText: 'Explain the issue',
                    hintText:
                        'Tell us what happened, what you expected, and how to reproduce it.',
                    alignLabelWithHint: true,
                    labelStyle: TextStyle(color: AppColors.softGold),
                    hintStyle: TextStyle(color: AppColors.mutedGold),
                    prefixIcon: Icon(
                      Icons.description_outlined,
                      color: AppColors.goldBright,
                    ),
                    errorStyle: TextStyle(color: AppColors.error),
                  ),
                  validator: _validateDescription,
                ),
                const SizedBox(height: AppSpacing.lg),

                // 5. Submit Action Button
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.goldBright,
                    foregroundColor: AppColors.emerald950,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                  ),
                  onPressed: _isSubmitting ? null : _prepareEmailReport,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.emerald950,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                  label: const Text(
                    'Prepare Email Report',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
