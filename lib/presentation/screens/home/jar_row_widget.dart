import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../core/engine/budget_engine.dart';

class JarRowWidget extends StatelessWidget {
  final List<ExpenseCategory> expectedExpenses;
  final Map<String, double> jarSpent;
  final Map<String, double> plannedTotalPerCategory;

  const JarRowWidget({
    super.key,
    required this.expectedExpenses,
    required this.jarSpent,
    this.plannedTotalPerCategory = const {},
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
    final isWeekly = exp.frequency == 'weekly';

    // For daily/weekly, use the monthly total from plannedTotalPerCategory
    final monthlyBudget = plannedTotalPerCategory[exp.name] ?? exp.amount;
    final remaining = monthlyBudget - spent;
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isDaily || isWeekly
                    ? 'Budget: ${formatAmount(monthlyBudget)} (${formatAmount(exp.amount)}/${exp.frequency})'
                    : 'Budget: ${formatAmount(exp.amount)}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              Text(
                'Remaining: ${formatAmount(remaining > 0 ? remaining : 0)}',
                style: TextStyle(
                  fontSize: 12,
                  color: remaining > 0 ? AppColors.onTrack : AppColors.critical,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
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
    );
  }
}
