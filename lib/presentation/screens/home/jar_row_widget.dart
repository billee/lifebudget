import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'jar_card_widget.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/expected_expense_model.dart';

class JarRowWidget extends StatelessWidget {
  final List<ExpectedExpense> expectedExpenses;
  final Map<String, double> jarSpent;
  final double totalIncome;
  final Map<String, double> dailyRates; // actual daily rates (or null)
  final Map<String, double> plannedRates; // planned daily rates

  const JarRowWidget({
    super.key,
    required this.expectedExpenses,
    required this.jarSpent,
    required this.totalIncome,
    required this.dailyRates,
    required this.plannedRates,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = List<ExpectedExpense>.from(expectedExpenses)
      ..sort((a, b) => b.amount.compareTo(a.amount));

    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: sorted.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final exp = sorted[index];
          final key = exp.title.toLowerCase();
          final actualDaily = dailyRates[key] ?? 0;
          final plannedDaily = plannedRates[key] ?? 0;
          final overBudgetRatio =
              plannedDaily > 0 ? actualDaily / plannedDaily : 1.0;

          return JarCardWidget(
            icon: _iconForFrequency(exp.frequency),
            name: exp.title,
            plannedAmount: exp.amount,
            frequency: exp.frequency,
            actualAmount: actualDaily > 0 ? actualDaily : null,
            color: _colorForTitle(exp.title),
            overBudgetRatio: overBudgetRatio,
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
