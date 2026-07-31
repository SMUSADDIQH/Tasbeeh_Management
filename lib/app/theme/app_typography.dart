import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract final class AppTypography {
  static TextStyle arabicGreeting({Color? color, double fontSize = 38}) =>
      GoogleFonts.amiri(
        fontSize: fontSize,
        height: 1.35,
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.goldBright,
        shadows: [
          Shadow(
            color: AppColors.goldGlow.withValues(alpha: 0.65),
            blurRadius: 16,
            offset: const Offset(0, 2),
          ),
          Shadow(
            color: AppColors.emerald950.withValues(alpha: 0.9),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      );

  static TextStyle arabicScript({Color? color, double fontSize = 20, FontWeight fontWeight = FontWeight.w600}) =>
      GoogleFonts.amiri(
        fontSize: fontSize,
        height: 1.4,
        fontWeight: fontWeight,
        color: color,
      );

  static TextStyle headerTitle({Color? color, double fontSize = 24}) =>
      GoogleFonts.cinzel(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 0.5,
      );

  static TextTheme textTheme(Color textColor) {
    final body = GoogleFonts.plusJakartaSansTextTheme();
    return body.copyWith(
      displayLarge: GoogleFonts.cinzel(
        fontSize: 57,
        height: 1.05,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      displayMedium: GoogleFonts.cinzel(
        fontSize: 45,
        height: 1.08,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      displaySmall: GoogleFonts.cinzel(
        fontSize: 36,
        height: 1.12,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      headlineLarge: GoogleFonts.cinzel(
        fontSize: 34,
        height: 1.1,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      headlineMedium: GoogleFonts.cinzel(
        fontSize: 31,
        height: 1.12,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      headlineSmall: GoogleFonts.cinzel(
        fontSize: 27,
        height: 1.15,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 22,
        height: 1.2,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        height: 1.45,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleSmall: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        height: 1.4,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        height: 1.5,
        color: textColor,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        height: 1.45,
        color: textColor,
      ),
      bodySmall: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        height: 1.4,
        color: textColor,
      ),
      labelLarge: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        height: 1.4,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      labelMedium: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        height: 1.35,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      labelSmall: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        height: 1.35,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    );
  }
}
