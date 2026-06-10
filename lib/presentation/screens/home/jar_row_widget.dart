import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../data/models/expected_expense_model.dart';

class JarRowWidget extends StatelessWidget {
  final List<ExpectedExpense> expectedExpenses;
  final Map<String, double> jarSpent;
  final int trackingDaysElapsed;
  final Map<String, DateTime> jarEarliestDate;

  const JarRowWidget({
    super.key,
    required this.expectedExpenses,
    required this.jarSpent,
    required this.trackingDaysElapsed,
    required this.jarEarliestDate,
  });

  @override
  Widget build(BuildContext context) {
    if (expectedExpenses.isEmpty) {
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
        ...expectedExpenses.map((exp) => _buildEnvelope(exp)),
      ],
    );
  }

  Widget _buildEnvelope(ExpectedExpense expense) {
    final title = expense.title;
    final titleLower = title.toLowerCase();
    final spent = jarSpent[titleLower] ?? 0.0;
    final isMonthly = expense.frequency == 'monthly';

    if (isMonthly) {
      final remaining = expense.amount - spent;
      final isOverBudget = remaining < 0;
      final statusColor = isOverBudget ? AppColors.critical : AppColors.onTrack;
      final statusText = isOverBudget ? 'Over budget' : 'On track';

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Budget: ${formatAmount(expense.amount)}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                Text(
                  'Remaining: ${formatAmount(remaining > 0 ? remaining : 0)}',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        remaining > 0 ? AppColors.onTrack : AppColors.critical,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
    } else {
      // daily or weekly – show per‑day averages
      final plannedPerDay = _calculatePlannedPerDay(expense);
      final earliestDate = jarEarliestDate[titleLower];
      final daysSinceStart = earliestDate != null
          ? DateTime.now().difference(earliestDate).inDays + 1
          : trackingDaysElapsed;
      final actualPerDay = daysSinceStart > 0 ? spent / daysSinceStart : 0.0;

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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
