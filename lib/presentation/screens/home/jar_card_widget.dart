import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/emotional_tone_helper.dart';

class JarCardWidget extends StatelessWidget {
  final String emoji;
  final String name;
  final double remaining;
  final double total;
  final Color color;

  const JarCardWidget({
    super.key,
    required this.emoji,
    required this.name,
    required this.remaining,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final double usedPercent = (total - remaining) / total;
    final String status = getJarStatusLabel(usedPercent);
    return GestureDetector(
      onTap: () {}, // tap to open jar detail (future)
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$emoji $name',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Text(
              '₱${remaining.toInt()}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: usedPercent,
                minHeight: 6,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              status,
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
