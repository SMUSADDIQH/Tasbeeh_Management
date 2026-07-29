import 'package:flutter/material.dart';

import '../../app/theme/app_spacing.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    required this.title,
    this.subtitle,
    this.action,
    this.textAlign = TextAlign.start,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? action;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: textAlign == TextAlign.center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          textAlign: textAlign,
          style: theme.textTheme.headlineMedium,
        ),
        if (subtitle case final subtitle?) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            textAlign: textAlign,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );

    if (action == null) {
      return content;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: content),
        const SizedBox(width: AppSpacing.md),
        action!,
      ],
    );
  }
}
