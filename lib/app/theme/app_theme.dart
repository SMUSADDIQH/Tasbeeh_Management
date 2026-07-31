import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => _theme(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.background,
    surface: AppColors.surface,
  );

  static ThemeData get dark => _theme(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.backgroundDark,
    surface: AppColors.surfaceDark,
  );

  static ThemeData _theme({
    required Brightness brightness,
    required Color scaffoldBackgroundColor,
    required Color surface,
  }) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.gold,
      onPrimary: AppColors.emerald950,
      primaryContainer: AppColors.gold.withValues(alpha: 0.16),
      onPrimaryContainer: AppColors.goldBright,
      secondary: AppColors.goldBright,
      onSecondary: AppColors.emerald950,
      secondaryContainer: AppColors.emerald800,
      onSecondaryContainer: AppColors.ivory,
      error: AppColors.error,
      onError: Colors.white,
      surface: surface,
      onSurface: AppColors.ivory,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.goldMuted,
      outlineVariant: AppColors.goldMuted.withValues(alpha: 0.42),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: AppColors.ivory,
      onInverseSurface: AppColors.emerald950,
      inversePrimary: AppColors.emerald700,
      surfaceTint: Colors.transparent,
    );
    final textTheme = AppTypography.textTheme(AppColors.ivory);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBackgroundColor,
        foregroundColor: AppColors.goldBright,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: AppColors.goldBright,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side: BorderSide(
            color: AppColors.goldMuted.withValues(alpha: 0.5),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.emerald950,
          minimumSize: const Size(48, 48),
          padding: AppSpacing.buttonPadding,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
          textStyle: textTheme.labelLarge?.copyWith(
            color: AppColors.emerald950,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.goldBright),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.goldBright,
          minimumSize: const Size(48, 48),
          padding: AppSpacing.buttonPadding,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
          side: const BorderSide(color: AppColors.goldMuted),
          textStyle: textTheme.labelLarge,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.goldMuted.withValues(alpha: 0.35),
        space: AppSpacing.md,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.emerald850,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.sage),
        border: const OutlineInputBorder(borderRadius: AppRadius.input),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(
            color: AppColors.goldMuted.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(color: AppColors.gold, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.emerald900,
        indicatorColor: AppColors.gold.withValues(alpha: 0.18),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? AppColors.goldBright
              : AppColors.sage,
        )),
        labelTextStyle: WidgetStateProperty.resolveWith((states) =>
            textTheme.labelSmall?.copyWith(
              color: states.contains(WidgetState.selected)
                  ? AppColors.goldBright
                  : AppColors.textSecondary,
            )),
        height: 72,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.emerald900,
        indicatorColor: AppColors.gold.withValues(alpha: 0.18),
        selectedIconTheme: const IconThemeData(color: AppColors.goldBright),
        unselectedIconTheme: const IconThemeData(color: AppColors.sage),
        selectedLabelTextStyle: const TextStyle(color: AppColors.goldBright),
        unselectedLabelTextStyle: const TextStyle(color: AppColors.textSecondary),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.emerald850,
        textStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side: BorderSide(color: AppColors.goldMuted.withValues(alpha: .5)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.emerald900,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: AppColors.goldBright),
        contentTextStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side: BorderSide(color: AppColors.goldMuted.withValues(alpha: .5)),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.emerald900,
        modalBackgroundColor: AppColors.emerald900,
        showDragHandle: true,
        dragHandleColor: AppColors.goldMuted,
      ),
      visualDensity: VisualDensity.standard,
    );
  }
}
