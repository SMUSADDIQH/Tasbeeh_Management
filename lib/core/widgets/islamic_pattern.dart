import 'package:flutter/material.dart';

class IslamicPattern extends StatelessWidget {
  const IslamicPattern({super.key, this.opacity = 0.13});
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(
        painter: _PatternPainter(
          Theme.of(context).colorScheme.secondary.withValues(alpha: opacity),
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  const _PatternPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    const step = 44.0;
    for (var y = -step; y < size.height + step; y += step) {
      for (var x = -step; x < size.width + step; x += step) {
        final center = Offset(x, y);
        final path = Path();
        for (var i = 0; i < 8; i++) {
          final angle = i * 3.141592653589793 / 4;
          final point = center + Offset.fromDirection(angle, 15);
          i == 0
              ? path.moveTo(point.dx, point.dy)
              : path.lineTo(point.dx, point.dy);
        }
        path.close();
        canvas.drawPath(path, paint);
        canvas.drawRect(
          Rect.fromCenter(center: center, width: 21, height: 21),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PatternPainter oldDelegate) =>
      oldDelegate.color != color;
}
