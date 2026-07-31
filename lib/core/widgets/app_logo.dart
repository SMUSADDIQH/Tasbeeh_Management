import 'package:flutter/material.dart';

class IslamicAppLogo extends StatelessWidget {
  const IslamicAppLogo({
    super.key,
    this.size = 72.0,
    this.borderRadius = 18.0,
    this.showBorder = true,
  });

  final double size;
  final double borderRadius;
  final bool showBorder;

  static const Color colorBackground = Color(0xFF003B2F);
  static const Color colorDarkEmerald = Color(0xFF00281F);
  static const Color colorGold = Color(0xFFE4B54C);
  static const Color colorSoftGold = Color(0xFFF2D07A);
  static const Color colorBorderGold = Color(0xFFD6A53C);

  static const String assetPath = 'assets/branding/tasbeeh_premium_icon.png';

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius.clamp(0.0, size / 2).toDouble();

    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(effectiveRadius),
          boxShadow: [
            BoxShadow(
              color: colorBorderGold.withValues(alpha: 0.25),
              blurRadius: size * 0.18,
              spreadRadius: size * 0.01,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: size * 0.16,
              offset: Offset(0, size * 0.06),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(effectiveRadius),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colorDarkEmerald,
              borderRadius: BorderRadius.circular(effectiveRadius),
              border: showBorder
                  ? Border.all(color: colorBorderGold, width: size * 0.015)
                  : null,
            ),
            child: Image.asset(
              assetPath,
              width: size,
              height: size,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
              gaplessPlayback: true,
              errorBuilder: (context, error, stackTrace) {
                return ColoredBox(
                  color: colorDarkEmerald,
                  child: Center(
                    child: Icon(
                      Icons.nights_stay_rounded,
                      size: size * 0.52,
                      color: colorGold,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
