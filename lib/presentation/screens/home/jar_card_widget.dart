import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class JarCardWidget extends StatelessWidget {
  final IconData icon;
  final String name;
  final double plannedAmount;
  final String frequency; // 'daily', 'weekly', 'monthly'
  final double? actualAmount; // null if no actual spending yet
  final Color color;

  const JarCardWidget({
    super.key,
    required this.icon,
    required this.name,
    required this.plannedAmount,
    required this.frequency,
    this.actualAmount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final displayedAmount = actualAmount ?? plannedAmount;
    final statusText = actualAmount != null ? 'Actual' : 'Planned';
    final statusColor =
        actualAmount != null ? AppColors.primary : AppColors.textSecondary;

    final frequencyLabel = frequency[0].toUpperCase() + frequency.substring(1);

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
            Text(
              '₱${displayedAmount.toStringAsFixed(0)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
            ),
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
            const Spacer(),
            Text(
              statusText,
              style: TextStyle(
                fontSize: 11,
                color: statusColor,
                fontWeight:
                    actualAmount != null ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
