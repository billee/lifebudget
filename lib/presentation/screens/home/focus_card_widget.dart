import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/number_formatter.dart';

class FocusCardWidget extends StatelessWidget {
  final double dailyAllowance;
  final int daysLeft;
  final int? daysSinceLastSlipUp;
  final String? overrideMessage;

  const FocusCardWidget({
    super.key,
    required this.dailyAllowance,
    required this.daysLeft,
    this.daysSinceLastSlipUp,
    this.overrideMessage,
  });

  @override
  Widget build(BuildContext context) {
    String message;
    IconData icon;

    if (overrideMessage != null) {
      message = overrideMessage!;
      icon = Icons.info_outline;
    } else {
      // Slip-up streak message
      if (daysSinceLastSlipUp == null) {
        icon = Icons.sunny;
        message =
            "You haven't had a rough day since you started. That's amazing!";
      } else if (daysSinceLastSlipUp == 0) {
        icon = Icons.heart_broken;
        message =
            "Yesterday was tough — but today is a new day. You're still here.";
      } else if (daysSinceLastSlipUp == 1) {
        icon = Icons.sentiment_satisfied;
        message =
            "It's been a day since your last slip-up. One step at a time.";
      } else {
        icon = Icons.emoji_events;
        message =
            "You've gone $daysSinceLastSlipUp days without a rough day. That's strength.";
      }

      // Append daily allowance info
      if (dailyAllowance <= 0) {
        message +=
            "\n\nYour planned expenses cover all your income — every peso has a job.";
      } else if (dailyAllowance < 100) {
        message +=
            "\n\nYou have ${formatAmount(dailyAllowance)} left per day. Small amounts add up.";
      } else {
        message +=
            "\n\nWith ${formatAmount(dailyAllowance)} a day, you've got breathing room.";
      }
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
