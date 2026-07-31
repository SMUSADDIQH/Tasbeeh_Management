import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';

class AppSegmentedTab<T> {
  const AppSegmentedTab({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

class AppSegmentedControl<T> extends StatelessWidget {
  const AppSegmentedControl({
    required this.tabs,
    required this.selected,
    required this.onChanged,
    super.key,
    this.isDarkBackground = false,
  });

  final List<AppSegmentedTab<T>> tabs;
  final T selected;
  final ValueChanged<T> onChanged;
  final bool isDarkBackground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDarkBackground
            ? AppColors.emerald850
            : AppColors.emerald900.withValues(alpha: 0.08),
        borderRadius: AppRadius.pillBorder,
        border: Border.all(
          color: isDarkBackground
              ? AppColors.premiumGold.withValues(alpha: 0.3)
              : AppColors.goldMuted.withValues(alpha: 0.4),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabCount = tabs.length;
          final tabWidth = (constraints.maxWidth - 8) / tabCount;
          // If individual tab width would be below 72px, wrap in SingleChildScrollView
          final useScroll = tabWidth < 72;

          if (useScroll) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final tab in tabs)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: _buildItem(
                        context,
                        tab,
                        isSelected: tab.value == selected,
                        isFlexible: false,
                      ),
                    ),
                ],
              ),
            );
          }

          return Row(
            children: [
              for (final tab in tabs)
                Expanded(
                  child: _buildItem(
                    context,
                    tab,
                    isSelected: tab.value == selected,
                    isFlexible: true,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildItem(
    BuildContext context,
    AppSegmentedTab<T> tab, {
    required bool isSelected,
    required bool isFlexible,
  }) {
    final activeBg = isDarkBackground
        ? AppColors.premiumGold
        : AppColors.emerald900;
    final activeFg = isDarkBackground ? AppColors.emerald950 : AppColors.ivory;
    final inactiveFg = isDarkBackground
        ? AppColors.softGold
        : AppColors.darkEmerald;

    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? activeBg : Colors.transparent,
        borderRadius: AppRadius.pillBorder,
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color:
                      (isDarkBackground
                              ? AppColors.premiumGold
                              : AppColors.emerald900)
                          .withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (tab.icon != null) ...[
            Icon(tab.icon, size: 15, color: isSelected ? activeFg : inactiveFg),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Text(
                tab.label,
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  color: isSelected ? activeFg : inactiveFg,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return InkWell(
      onTap: () => onChanged(tab.value),
      borderRadius: AppRadius.pillBorder,
      child: child,
    );
  }
}
