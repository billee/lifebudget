import 'dart:math';
import 'package:flutter/material.dart';

class HoneycombBackground extends StatelessWidget {
  final Color? color;
  final double opacity;
  final double hexRadius;

  const HoneycombBackground({
    super.key,
    this.color,
    this.opacity = 0.06,
    this.hexRadius = 3.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _HoneycombPainter(
        color: color ?? Theme.of(context).colorScheme.onSurface,
        opacity: opacity,
        hexRadius: hexRadius,
      ),
      size: Size.infinite,
    );
  }
}

class _HoneycombPainter extends CustomPainter {
  final Color color;
  final double opacity;
  final double hexRadius;

  _HoneycombPainter({
    required this.color,
    required this.opacity,
    required this.hexRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Width of a single hexagon from left to right (corner to corner horizontally)
    final double hexWidth = hexRadius * 2;
    // Vertical distance between rows (center to center)
    final double rowHeight = hexRadius * sqrt(3);

    // We need to cover the entire area, including partial hexagons at edges
    final int cols = (size.width / (hexWidth * 0.75)).ceil() + 2;
    final int rows = (size.height / rowHeight).ceil() + 2;

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        // Offset for odd rows (staggering)
        final double xOff =
            (col * hexWidth * 0.75) + (row % 2 == 0 ? 0 : hexWidth * 0.375);
        final double yOff = row * rowHeight;

        // Calculate the six corners of the hexagon
        final path = Path();
        for (int i = 0; i < 6; i++) {
          final double angle = pi / 3 * i - pi / 6; // start at top point
          final double x = xOff + hexRadius * cos(angle);
          final double y = yOff + hexRadius * sin(angle);
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        path.close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
