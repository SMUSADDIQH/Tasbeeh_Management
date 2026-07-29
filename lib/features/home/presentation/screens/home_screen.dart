import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/section_title.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.pagePadding,
          child: Center(
            child: SectionTitle(
              title: '📿 Tasbeeh-Tracker',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
