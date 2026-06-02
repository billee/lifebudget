import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class HealthRingWidget extends StatelessWidget {
  final double leftAmount;
  final double totalBudget;

  const HealthRingWidget({
    super.key,
    required this.leftAmount,
    required this.totalBudget,
  });

  @override
  Widget build(BuildContext context) {
    final double usedPercent =
        totalBudget > 0 ? 1 - (leftAmount / totalBudget) : 0.0;

    Color ringColor;
    if (usedPercent <= 0.7) {
      ringColor = AppColors.onTrack;
    } else if (usedPercent <= 0.9) {
      ringColor = AppColors.warning;
    } else {
      ringColor = AppColors.critical;
    }

    return Center(
      child: SizedBox(
        width: 200,
        height: 200,
        child: CustomPaint(
          painter: _RingPainter(
            percent: usedPercent.clamp(0.0, 1.0),
            progressColor: ringColor,
            backgroundColor: AppColors.ringBackground,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '₱${leftAmount.toInt()}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Text(
                  'left to use',
                  style:
                      TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  'of your ₱${totalBudget.toInt()}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double percent;
  final Color progressColor;
  final Color backgroundColor;

  _RingPainter({
    required this.percent,
    required this.progressColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 14;
    const strokeWidth = 14.0;

    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * percent,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      percent != oldDelegate.percent ||
      progressColor != oldDelegate.progressColor;
}
