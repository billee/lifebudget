import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../../core/constants/app_colors.dart';

class HealthRingWidget extends StatelessWidget {
  final double leftAmount;
  final double totalBudget;
  const HealthRingWidget(
      {super.key, required this.leftAmount, required this.totalBudget});

  @override
  Widget build(BuildContext context) {
    // Mock data – will be replaced with real provider later
    const double leftAmount = 4200;
    const double totalBudget = 18000;
    final double percentLeft = leftAmount / totalBudget; // 0.233…
    final double usedPercent = 1 - percentLeft; // ring fills as money is used

    // Colour changes from green → amber → soft red depending on usage
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
              style:
                  const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
