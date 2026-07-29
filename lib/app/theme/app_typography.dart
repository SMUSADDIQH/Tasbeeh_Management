import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTypography {
  static TextTheme textTheme(Color textColor) {
    return GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.inter(
        fontSize: 57,
        height: 1.12,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 45,
        height: 1.16,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: 36,
        height: 1.22,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      headlineLarge: GoogleFonts.inter(
        fontSize: 32,
        height: 1.25,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 30,
        height: 1.27,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 24,
        height: 1.33,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 22,
        height: 1.27,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        height: 1.43,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        height: 1.43,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        height: 1.33,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        height: 1.43,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        height: 1.33,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        height: 1.45,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    );
  }
}
