import 'dart:math';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'jar_card_widget.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../data/models/expected_expense_model.dart';
import '../../../data/models/goal_model.dart';

class JarRowWidget extends StatelessWidget {
  final List<ExpectedExpense> expectedExpenses;
  final Map<String, double> jarSpent;
  final double totalIncome;
  final int trackingDaysElapsed;
  final double dailyAllowance;
  final Map<String, DateTime> jarEarliestDate;
  final Set<String> goalTitles;
  final List<Goal> goals;
  final Function(Goal) onAddMoneyToGoal;

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your envelopes',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...expectedExpenses.map((exp) => _buildJarTile(exp)).toList(),
        if (goals.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Savings Goals',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          ...goals.map((goal) => _buildGoalTile(goal)).toList(),
        ],
      ],
    );
  }

  Widget _buildJarTile(ExpectedExpense expense) {
    final title = expense.title;
    final titleLower = title.toLowerCase();
    final spent = jarSpent[titleLower] ?? 0.0;
    final plannedPerDay = _calculatePlannedPerDay(expense);
    final earliestDate = jarEarliestDate[titleLower];
    final daysSinceStart = earliestDate != null
        ? DateTime.now().difference(earliestDate).inDays + 1
        : trackingDaysElapsed;
    final actualPerDay = daysSinceStart > 0 ? spent / daysSinceStart : 0.0;

    // Determine status color
    Color statusColor;
    String statusText;
    if (plannedPerDay == 0) {
      statusColor = AppColors.textSecondary;
      statusText = 'No budget';
    } else if (actualPerDay <= plannedPerDay) {
      statusColor = AppColors.onTrack;
      statusText = 'On track';
    } else {
      statusColor = AppColors.critical;
      statusText = 'Over budget';
    }

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
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '₱${spent.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${formatAmount(actualPerDay)}/day avg',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 12),
              Text(
                'Budget: ${formatAmount(plannedPerDay)}/day',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(fontSize: 11, color: statusColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalTile(Goal goal) {
    final progress = goal.progressPercent;
    final remaining = goal.targetAmount - goal.currentAmount;

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
          Row(
            children: [
              Text(goal.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  goal.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 20, color: AppColors.primary),
                onPressed: () => onAddMoneyToGoal(goal),
                tooltip: 'Add money',
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.grey[300],
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${formatAmount(goal.currentAmount)} / ${formatAmount(goal.targetAmount)}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              if (remaining > 0)
                Text(
                  '${formatAmount(remaining)} left',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
            ],
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

  double _calculatePlannedPerDay(ExpectedExpense expense) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    double monthlyAmount = 0;
    switch (expense.frequency) {
      case 'daily':
        monthlyAmount = expense.amount * daysInMonth;
        break;
      case 'weekly':
        monthlyAmount = expense.amount * (daysInMonth / 7);
        break;
      case 'monthly':
        monthlyAmount = expense.amount;
        break;
    }
    return monthlyAmount / daysInMonth;
  }
}
