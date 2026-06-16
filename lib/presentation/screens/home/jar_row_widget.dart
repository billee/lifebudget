import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../core/engine/budget_engine.dart';

class JarRowWidget extends StatelessWidget {
  final List<ExpenseCategory> expectedExpenses;
  final Map<String, double> jarSpent;
  final Map<String, double> plannedTotalPerCategory;
  final int daysLeft;
  final int daysInPeriod;

  const JarRowWidget({
    super.key,
    required this.expectedExpenses,
    required this.jarSpent,
    this.plannedTotalPerCategory = const {},
    this.daysLeft = 0,
    this.daysInPeriod = 30,
  });

  @override
  Widget build(BuildContext context) {
    if (expectedExpenses.isEmpty) return const SizedBox.shrink();

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

  Widget _buildEnvelope(ExpenseCategory exp) {
    final spent = jarSpent[exp.name] ?? 0.0;
    final isDaily = exp.frequency == 'daily';
    final isMonthly = exp.frequency == 'monthly';

    // For daily, use the monthly total from plannedTotalPerCategory
    final monthlyBudget = plannedTotalPerCategory[exp.name] ?? exp.amount;
    final remaining = monthlyBudget - spent;

    // For monthly: check if fully paid (remaining budget is 0)
    final isMonthlyPaid = isMonthly && exp.amount <= 0;
    final isOverBudget = !isMonthlyPaid && remaining < 0;
    final statusColor = isMonthlyPaid
        ? AppColors.onTrack
        : (isOverBudget ? AppColors.critical : AppColors.onTrack);
    final statusText =
        isMonthlyPaid ? 'Paid' : (isOverBudget ? 'Over budget' : 'On track');

    // Build budget label based on frequency (include total)
    String budgetLabel;
    if (isDaily) {
      budgetLabel =
          '${formatAmount(exp.amount)}/day × $daysLeft days = ${formatAmount(exp.amount * daysLeft)}';
    } else if (isMonthly) {
      if (isMonthlyPaid) {
        budgetLabel = 'Paid in full';
      } else {
        budgetLabel = spent > 0
            ? '${formatAmount(monthlyBudget)} (${formatAmount(exp.amount)} left)'
            : formatAmount(monthlyBudget);
      }
    } else {
      budgetLabel = formatAmount(exp.amount);
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
                  exp.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                formatAmount(spent),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Budget label and status on same row
          Row(
            children: [
              Expanded(
                child: Text(
                  budgetLabel,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
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
}
