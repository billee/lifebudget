import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/emotional_tone_helper.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data
    const percentageUsed = 0.6; // 60% used
    final statusLine = getStatusLine(percentageUsed);

    return Row(
      children: [
        // Avatar
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.primary,
          child: const Text(
            'M',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 12),
        // Greeting + status
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good morning, Maria',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                statusLine,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        // Notification bell
        IconButton(
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: AppColors.textSecondary,
          ),
          onPressed: () {},
        ),
      ],
    );
  }
}
