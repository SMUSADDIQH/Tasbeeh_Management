import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import 'islamic_pattern.dart';

/// Renders a mosque silhouette with domes and minarets
class MosqueSilhouetteWidget extends StatelessWidget {
  const MosqueSilhouetteWidget({
    super.key,
    this.color = AppColors.gold,
    this.opacity = 0.18,
    this.height = 90,
  });

  final Color color;
  final double opacity;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: MosqueDomePainter(
            color: color.withValues(alpha: opacity),
          ),
        ),
      ),
    );
  }
}

class MosqueDomePainter extends CustomPainter {
  MosqueDomePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final w = size.width;
    final h = size.height;

    // Draw minaret left
    path.moveTo(w * 0.1, h);
    path.lineTo(w * 0.1, h * 0.25);
    path.lineTo(w * 0.08, h * 0.25);
    path.lineTo(w * 0.11, h * 0.05); // Spire top
    path.lineTo(w * 0.14, h * 0.25);
    path.lineTo(w * 0.12, h * 0.25);
    path.lineTo(w * 0.12, h);

    // Minaret right
    path.moveTo(w * 0.88, h);
    path.lineTo(w * 0.88, h * 0.25);
    path.lineTo(w * 0.86, h * 0.25);
    path.lineTo(w * 0.89, h * 0.05); // Spire top
    path.lineTo(w * 0.92, h * 0.25);
    path.lineTo(w * 0.9, h * 0.25);
    path.lineTo(w * 0.9, h);

    // Main Central Dome
    path.moveTo(w * 0.35, h);
    path.lineTo(w * 0.35, h * 0.45);
    // Onion dome curve left to top center
    path.cubicTo(
      w * 0.32, h * 0.3,
      w * 0.42, h * 0.1,
      w * 0.5, h * 0.02,
    );
    // Onion dome curve right to bottom
    path.cubicTo(
      w * 0.58, h * 0.1,
      w * 0.68, h * 0.3,
      w * 0.65, h * 0.45,
    );
    path.lineTo(w * 0.65, h);

    // Side Dome Left
    path.moveTo(w * 0.2, h);
    path.lineTo(w * 0.2, h * 0.6);
    path.cubicTo(
      w * 0.18, h * 0.5,
      w * 0.24, h * 0.35,
      w * 0.28, h * 0.3,
    );
    path.cubicTo(
      w * 0.32, h * 0.35,
      w * 0.38, h * 0.5,
      w * 0.36, h * 0.6,
    );
    path.lineTo(w * 0.36, h);

    // Side Dome Right
    path.moveTo(w * 0.64, h);
    path.lineTo(w * 0.64, h * 0.6);
    path.cubicTo(
      w * 0.62, h * 0.5,
      w * 0.68, h * 0.35,
      w * 0.72, h * 0.3,
    );
    path.cubicTo(
      w * 0.76, h * 0.35,
      w * 0.82, h * 0.5,
      w * 0.8, h * 0.6,
    );
    path.lineTo(w * 0.8, h);

    canvas.drawPath(path, paint);

    // Draw crescent on main dome tip
    final crescentPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final crescentCenter = Offset(w * 0.5, h * 0.01);
    canvas.drawCircle(crescentCenter, 3.5, crescentPaint);
  }

  @override
  bool shouldRepaint(covariant MosqueDomePainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Illuminated Ramadan Lantern (Fanous) custom painter
class RamadanLanternWidget extends StatelessWidget {
  const RamadanLanternWidget({
    super.key,
    this.size = 50,
    this.color = AppColors.goldBright,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size * 1.5,
        child: CustomPaint(
          painter: RamadanLanternPainter(color: color),
        ),
      ),
    );
  }
}

class RamadanLanternPainter extends CustomPainter {
  RamadanLanternPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Glowing Radial background behind lantern
    final glowPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(w * 0.5, h * 0.5),
        w * 0.7,
        [
          AppColors.goldGlow.withValues(alpha: 0.6),
          AppColors.goldBright.withValues(alpha: 0.2),
          AppColors.goldBright.withValues(alpha: 0.0),
        ],
        const [0.0, 0.5, 1.0],
      );
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.65, glowPaint);

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    // Hanging Chain
    canvas.drawLine(Offset(w * 0.5, 0), Offset(w * 0.5, h * 0.15), linePaint);
    canvas.drawCircle(Offset(w * 0.5, h * 0.15), 3, linePaint);

    // Cap Top
    final capPath = Path()
      ..moveTo(w * 0.35, h * 0.22)
      ..lineTo(w * 0.5, h * 0.17)
      ..lineTo(w * 0.65, h * 0.22)
      ..lineTo(w * 0.7, h * 0.3)
      ..lineTo(w * 0.3, h * 0.3)
      ..close();
    canvas.drawPath(capPath, fillPaint);
    canvas.drawPath(capPath, linePaint);

    // Glass Body
    final bodyPath = Path()
      ..moveTo(w * 0.3, h * 0.3)
      ..lineTo(w * 0.15, h * 0.55)
      ..lineTo(w * 0.32, h * 0.78)
      ..lineTo(w * 0.68, h * 0.78)
      ..lineTo(w * 0.85, h * 0.55)
      ..lineTo(w * 0.7, h * 0.3)
      ..close();
    canvas.drawPath(bodyPath, fillPaint);
    canvas.drawPath(bodyPath, linePaint);

    // Glass Segment Vertical Lines
    canvas.drawLine(Offset(w * 0.5, h * 0.3), Offset(w * 0.5, h * 0.78), linePaint);
    canvas.drawLine(Offset(w * 0.38, h * 0.3), Offset(w * 0.34, h * 0.78), linePaint);
    canvas.drawLine(Offset(w * 0.62, h * 0.3), Offset(w * 0.66, h * 0.78), linePaint);

    // Inner Flame
    final flamePaint = Paint()
      ..color = AppColors.goldGlow
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.5, h * 0.54), w * 0.12, flamePaint);

    // Base Stand
    final basePath = Path()
      ..moveTo(w * 0.32, h * 0.78)
      ..lineTo(w * 0.25, h * 0.9)
      ..lineTo(w * 0.75, h * 0.9)
      ..lineTo(w * 0.68, h * 0.78)
      ..close();
    canvas.drawPath(basePath, fillPaint);
    canvas.drawPath(basePath, linePaint);

    // Bottom Ring
    canvas.drawCircle(Offset(w * 0.5, h * 0.94), 2.5, linePaint);
  }

  @override
  bool shouldRepaint(covariant RamadanLanternPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Top Metallic Gold Arch Frame Banner (ZIKR MANAGEMENT APP - Premium. Spiritual. Purposeful.)
class TopArchHeaderBanner extends StatelessWidget {
  const TopArchHeaderBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF021B14),
              Color(0xFF042E25),
              Color(0xFF021B14),
            ],
          ),
          border: Border(
            bottom: BorderSide(
              color: AppColors.goldMuted.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 1,
                  width: 36,
                  color: AppColors.goldMuted.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.star_rate_rounded, size: 12, color: AppColors.goldBright),
                const SizedBox(width: 6),
                Text(
                  'ZIKR MANAGEMENT APP',
                  style: TextStyle(
                    fontFamily: 'Cinzel',
                    fontSize: 12,
                    letterSpacing: 2.2,
                    fontWeight: FontWeight.w700,
                    color: AppColors.goldBright,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.star_rate_rounded, size: 12, color: AppColors.goldBright),
                const SizedBox(width: 8),
                Container(
                  height: 1,
                  width: 36,
                  color: AppColors.goldMuted.withValues(alpha: 0.6),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Premium. Spiritual. Purposeful.',
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                letterSpacing: 0.8,
                color: AppColors.gold.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GreetingHeaderBackgroundWidget extends StatelessWidget {
  const GreetingHeaderBackgroundWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox.expand(
        child: CustomPaint(
          painter: GreetingHeaderBackgroundPainter(),
        ),
      ),
    );
  }
}

class GreetingHeaderBackgroundPainter extends CustomPainter {
  GreetingHeaderBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Deep Emerald Base & Gold Halo Shader
    final bgPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(w * 0.3, h * 0.35),
        w * 0.8,
        [
          const Color(0xFF0C4D3C),
          const Color(0xFF03261D),
          const Color(0xFF01140E),
        ],
        const [0.0, 0.55, 1.0],
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // 2. Render Iconic 12-Fold Alhambra Star Rosette Advertised Pattern
    final patternPainter = IslamicStarPatternPainter(
      backgroundColor: Colors.transparent,
      lineColor: AppColors.goldBright.withValues(alpha: 0.12),
      lineWidth: 1.5,
      tileSize: 84,
    );
    patternPainter.paint(canvas, size);

    // 3. Soft Golden Radial Glow behind Calligraphy
    final glowPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(w * 0.28, h * 0.32),
        w * 0.45,
        [
          AppColors.goldGlow.withValues(alpha: 0.3),
          AppColors.goldBright.withValues(alpha: 0.08),
          AppColors.goldBright.withValues(alpha: 0.0),
        ],
        const [0.0, 0.5, 1.0],
      );
    canvas.drawCircle(Offset(w * 0.28, h * 0.32), w * 0.45, glowPaint);
  }

  @override
  bool shouldRepaint(covariant GreetingHeaderBackgroundPainter oldDelegate) => false;
}

