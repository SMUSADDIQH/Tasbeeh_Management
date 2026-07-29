import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/section_title.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/progress_card.dart';
import '../widgets/stats_grid.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.pagePadding,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const DashboardHeader(
                        greeting: 'Assalamu Alaikum',
                        subtitle: 'May every remembrance bring you peace.',
                      )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: -0.08, end: 0),
                  const SizedBox(height: AppSpacing.xl),
                  const SectionTitle(
                    title: 'Your Dhikr',
                    subtitle: 'Stay present. Keep your heart connected.',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      const progressCard = ProgressCard(
                        tasbeehName: 'SubhanAllah',
                        currentCount: 68,
                        target: 100,
                        lastUpdated: 'today at 9:42 AM',
                      );
                      const statsGrid = StatsGrid(
                        todayCount: 68,
                        lifetimeCount: 12486,
                      );

                      if (constraints.maxWidth < 760) {
                        return const Column(
                          children: [
                            progressCard,
                            SizedBox(height: AppSpacing.md),
                            statsGrid,
                          ],
                        );
                      }

                      return const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 5, child: progressCard),
                          SizedBox(width: AppSpacing.lg),
                          Expanded(flex: 4, child: statsGrid),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
