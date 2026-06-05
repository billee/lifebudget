import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'jar_card_widget.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/expected_expense_model.dart';

class JarRowWidget extends StatelessWidget {
  final List<ExpectedExpense> expectedExpenses;
  final Map<String, double> jarSpent; // jar name → total spent this month
  final double totalIncome;

  const JarRowWidget({
    super.key,
    required this.expectedExpenses,
    required this.jarSpent,
    required this.totalIncome,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = List<ExpectedExpense>.from(expectedExpenses)
      ..sort((a, b) => b.amount.compareTo(a.amount));

    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final daysElapsed = now.difference(firstDay).inDays + 1;

    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: sorted.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final exp = sorted[index];
          final key = exp.title.toLowerCase();
          final double plannedAmount = exp.amount; // stored amount (per period)
          final double actualSpent = jarSpent[key] ?? 0.0;

          // Determine over/under ratio based on frequency
          double overBudgetRatio = 1.0;
          switch (exp.frequency) {
            case 'daily':
              final plannedDaily = plannedAmount;
              final actualDaily = actualSpent / daysElapsed;
              overBudgetRatio =
                  plannedDaily > 0 ? actualDaily / plannedDaily : 1.0;
              break;
            case 'weekly':
              final weeksElapsed = (daysElapsed / 7).ceil();
              final plannedWeekly = plannedAmount;
              final actualWeekly =
                  weeksElapsed > 0 ? actualSpent / weeksElapsed : 0;
              overBudgetRatio =
                  plannedWeekly > 0 ? actualWeekly / plannedWeekly : 1.0;
              break;
            case 'monthly':
              // Compare total spent so far to planned monthly amount
              overBudgetRatio =
                  plannedAmount > 0 ? actualSpent / plannedAmount : 1.0;
              break;
          }

          return SizedBox(
            height: 150,
            child: JarCardWidget(
              icon: _iconForFrequency(exp.frequency),
              name: exp.title,
              plannedAmount: exp.amount,
              frequency: exp.frequency,
              color: _colorForTitle(exp.title),
              overBudgetRatio: overBudgetRatio,
            ),
          );
        },
      ),
    );
  }

  IconData _iconForFrequency(String freq) {
    switch (freq) {
      case 'daily':
        return FontAwesomeIcons.calendarDay;
      case 'weekly':
        return FontAwesomeIcons.calendarWeek;
      case 'monthly':
        return FontAwesomeIcons.calendarAlt;
      default:
        return FontAwesomeIcons.calendar;
    }
  }

  Color _colorForTitle(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('rent')) return AppColors.rent;
    if (lower.contains('food') || lower.contains('grocer'))
      return AppColors.food;
    if (lower.contains('transport') || lower.contains('commute'))
      return AppColors.transport;
    if (lower.contains('health') || lower.contains('medical'))
      return AppColors.health;
    if (lower.contains('fun') || lower.contains('entertain'))
      return AppColors.fun;
    if (lower.contains('saving') || lower.contains('invest'))
      return AppColors.primary;
    return AppColors.primary;
  }
}
