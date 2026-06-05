import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/number_formatter.dart';

class JarCardWidget extends StatelessWidget {
  final IconData icon;
  final String name;
  final double plannedAmount;
  final String frequency;
  final Color color;
  final double overBudgetRatio;
  final double? actualAverage; // NEW: average actual spend per period

  const JarCardWidget({
    super.key,
    required this.icon,
    required this.name,
    required this.plannedAmount,
    required this.frequency,
    required this.color,
    this.overBudgetRatio = 1.0,
    this.actualAverage,
  });

  @override
  Widget build(BuildContext context) {
    final frequencyLabel = frequency[0].toUpperCase() + frequency.substring(1);

    String statusLabel;
    Color statusColor;
    if (overBudgetRatio > 1.5) {
      statusLabel = 'A lot over';
      statusColor = AppColors.critical;
    } else if (overBudgetRatio > 1.0) {
      statusLabel = 'A bit over';
      statusColor = AppColors.warning;
    } else if (overBudgetRatio > 0.9) {
      statusLabel = 'On track';
      statusColor = AppColors.onTrack;
    } else {
      statusLabel = 'Under';
      statusColor = AppColors.onTrack;
    }

    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Planned amount
            Text(
              formatAmount(plannedAmount),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
            ),
            // Actual average (if spending exists)
            if (actualAverage != null) ...[
              const SizedBox(height: 2),
              Text(
                'Avg: ${formatAmount(actualAverage!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                frequencyLabel,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              statusLabel,
              style: TextStyle(
                fontSize: 11,
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
