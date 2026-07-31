import 'dart:math' as math;
import 'package:flutter/material.dart';

class IslamicPattern extends StatelessWidget {
  const IslamicPattern({
    super.key,
    this.opacity = 0.13,
  });

  final double opacity;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: IslamicStarPattern(
        backgroundColor: Colors.transparent,
        lineColor: Theme.of(context).colorScheme.secondary.withValues(alpha: opacity),
        lineWidth: 1.5,
        tileSize: 84,
      ),
    );
  }
}

class IslamicStarPattern extends StatelessWidget {
  const IslamicStarPattern({
    super.key,
    this.backgroundColor = const Color(0xFF0C4D3C),
    this.lineColor = const Color(0xFFF5E9D1),
    this.lineWidth = 2.0,
    this.tileSize = 84,
  });

  final Color backgroundColor;
  final Color lineColor;
  final double lineWidth;
  final double tileSize;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: IslamicStarPatternPainter(
        backgroundColor: backgroundColor,
        lineColor: lineColor,
        lineWidth: lineWidth,
        tileSize: tileSize,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class IslamicStarPatternPainter extends CustomPainter {
  const IslamicStarPatternPainter({
    required this.backgroundColor,
    required this.lineColor,
    required this.lineWidth,
    required this.tileSize,
  });

  final Color backgroundColor;
  final Color lineColor;
  final double lineWidth;
  final double tileSize;

  @override
  void paint(Canvas canvas, Size size) {
    if (backgroundColor != Colors.transparent) {
      final backgroundPaint = Paint()
        ..color = backgroundColor
        ..style = PaintingStyle.fill;

      canvas.drawRect(Offset.zero & size, backgroundPaint);
    }

    final patternPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = lineWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final pi = math.pi;
    final rStarOuter = tileSize * 0.28;
    final rStarInner = rStarOuter * 0.50;
    final rPetalOuter = tileSize * 0.44;
    final rOuterHex = tileSize * 0.52;

    for (
      double y = -tileSize;
      y <= size.height + tileSize;
      y += tileSize * 0.866
    ) {
      final rowIndex = (y / (tileSize * 0.866)).round();
      final xOffset = (rowIndex % 2 != 0) ? tileSize * 0.5 : 0.0;

      for (
        double x = -tileSize + xOffset;
        x <= size.width + tileSize;
        x += tileSize
      ) {
        final center = Offset(x, y);

        // 1. Central 12-Pointed Star Rosette
        final starPath = Path();
        for (int i = 0; i < 12; i++) {
          final a1 = i * pi / 6;
          final a2 = a1 + pi / 12;
          final p1 = center + Offset(math.cos(a1) * rStarOuter, math.sin(a1) * rStarOuter);
          final p2 = center + Offset(math.cos(a2) * rStarInner, math.sin(a2) * rStarInner);
          i == 0 ? starPath.moveTo(p1.dx, p1.dy) : starPath.lineTo(p1.dx, p1.dy);
          starPath.lineTo(p2.dx, p2.dy);
        }
        starPath.close();
        canvas.drawPath(starPath, patternPaint);

        // 2. 12 Petals / Kites extending from the 12-star points to outer ring
        for (int i = 0; i < 12; i++) {
          final a = i * pi / 6;
          final aPrev = a - pi / 12;
          final aNext = a + pi / 12;

          final pTip = center + Offset(math.cos(a) * rStarOuter, math.sin(a) * rStarOuter);
          final pPetal = center + Offset(math.cos(a) * rPetalOuter, math.sin(a) * rPetalOuter);
          final pValleyL = center + Offset(math.cos(aPrev) * rStarInner, math.sin(aPrev) * rStarInner);
          final pValleyR = center + Offset(math.cos(aNext) * rStarInner, math.sin(aNext) * rStarInner);

          final kitePath = Path()
            ..moveTo(pTip.dx, pTip.dy)
            ..lineTo(pValleyR.dx, pValleyR.dy)
            ..lineTo(pPetal.dx, pPetal.dy)
            ..lineTo(pValleyL.dx, pValleyL.dy)
            ..close();

          canvas.drawPath(kitePath, patternPaint);
        }

        // 3. Interlocking Hexagon Boundary Mesh
        final hexPath = Path();
        for (int i = 0; i < 6; i++) {
          final a = i * pi / 3 + pi / 6;
          final pt = center + Offset(math.cos(a) * rOuterHex, math.sin(a) * rOuterHex);
          i == 0 ? hexPath.moveTo(pt.dx, pt.dy) : hexPath.lineTo(pt.dx, pt.dy);
        }
        hexPath.close();
        canvas.drawPath(hexPath, patternPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant IslamicStarPatternPainter oldDelegate) {
    return oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.lineWidth != lineWidth ||
        oldDelegate.tileSize != tileSize;
  }
}
