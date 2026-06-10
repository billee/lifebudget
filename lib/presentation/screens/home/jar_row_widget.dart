import 'dart:math';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'jar_card_widget.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../data/models/expected_expense_model.dart';
import '../../../data/models/goal_model.dart';

class JarRowWidget extends StatelessWidget {
  final List<ExpectedExpense>
      expectedExpenses; // kept for compatibility, not used
  final Map<String, double> jarSpent;
  final double totalIncome;
  final int trackingDaysElapsed;
  final double dailyAllowance;
  final Map<String, DateTime> jarEarliestDate;
  final Set<String> goalTitles;
  final List<Goal> goals;
  final Function(Goal) onAddMoneyToGoal; // still kept in signature but not used

  const JarRowWidget({
    super.key,
    required this.expectedExpenses,
    required this.jarSpent,
    required this.totalIncome,
    required this.trackingDaysElapsed,
    required this.dailyAllowance,
    required this.jarEarliestDate,
    required this.goalTitles,
    required this.goals,
    required this.onAddMoneyToGoal,
  });

  @override
  Widget build(BuildContext context) {
    if (goals.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your envelopes',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...goals.map((goal) => _buildGoalTile(goal)),
      ],
    );
  }

  Widget _buildGoalTile(Goal goal) {
    final progress = goal.progressPercent;
    final daysLeft = _getDaysLeftInMonth();
    final dailyRate = goal.targetAmount / daysLeft;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "Goal" label + emoji + title row (no + button)
          Row(
            children: [
              Text(
                'Goal',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Text(goal.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  goal.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: Colors.grey.shade300,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 8),
          // Saved / Budget row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Saved: ${formatAmount(goal.currentAmount)}',
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
              Text(
                'Budget: ${formatAmount(goal.targetAmount)}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Rate per day
          Text(
            'Rate: ${formatAmount(dailyRate)} / day',
            style:
                const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          if (goal.isCompleted)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.onTrack.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Completed! 🎉',
                style: TextStyle(fontSize: 11, color: AppColors.onTrack),
              ),
            ),
        ],
      ),
    );
  }

  int _getDaysLeftInMonth() {
    final now = DateTime.now();
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final daysLeft = lastDayOfMonth.difference(now).inDays + 1;
    return daysLeft > 0 ? daysLeft : 1;
  }
}
