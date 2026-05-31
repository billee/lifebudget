import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../../../core/constants/app_colors.dart';

class HealthRingWidget extends StatelessWidget {
  const HealthRingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock: 4200 left of 18000 => ~23.3% used, 76.7% left? Our ring shows "left to use".
    const double leftAmount = 4200;
    const double totalBudget = 18000;
    final double percentLeft = leftAmount /
        totalBudget; // 0.233 -> that's low? Wait, design says ring fills as money is used.
    // Actually design: ring fills with color as money is used. So percentageUsed = 1 - percentLeft.
    // Ring should show "left to use" amount inside. The ring fill = percentageUsed.
    final double usedPercent = 1 - percentLeft; // 0.767
    // Color from green -> amber -> soft red based on usage
    Color ringColor;
    if (usedPercent <= 0.7) {
      ringColor = AppColors.onTrack;
    } else if (usedPercent <= 0.9) {
      ringColor = AppColors.warning;
    } else {
      ringColor = AppColors.critical;
    }

    return Center(
      child: CircularPercentIndicator(
        radius: 100,
        lineWidth: 14,
        percent: usedPercent,
        progressColor: ringColor,
        backgroundColor: AppColors.ringBackground,
        circularStrokeCap: CircularStrokeCap.round,
        center: Column(
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
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              'of your ₱${totalBudget.toInt()}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
