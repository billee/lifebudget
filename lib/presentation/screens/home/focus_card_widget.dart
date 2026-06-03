import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class FocusCardWidget extends StatelessWidget {
  final double dailyAllowance;
  final int daysLeft;
  const FocusCardWidget({
    super.key,
    required this.dailyAllowance,
    required this.daysLeft,
  });

  @override
  Widget build(BuildContext context) {
    String message;
    IconData icon;

    if (dailyAllowance <= 0) {
      icon = Icons.lightbulb_outline;
      message = "Your planned expenses are using all your income right now. "
          "That’s okay — it just means every peso has a job. "
          "If you feel squeezed, try adjusting one of your envelopes.";
    } else if (dailyAllowance < 100) {
      icon = Icons.tips_and_updates;
      message =
          "You have ₱${dailyAllowance.toInt()} left per day — a little room to breathe. "
          "Small amounts add up!";
    } else {
      icon = Icons.emoji_events;
      message = "You’re doing great! With ₱${dailyAllowance.toInt()} a day, "
          "you’ve got space to save or treat yourself.";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 28, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Got it'),
            ),
          ),
        ],
      ),
    );
  }
}
