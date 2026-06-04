import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'jar_card_widget.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/expected_expense_model.dart';

class JarRowWidget extends StatelessWidget {
  final List<ExpectedExpense> expectedExpenses;
  final Map<String, double> jarSpent; // jar name → total spent this month
  final double totalIncome;
  final Map<String, double> dailyRates; // actual daily rates (for daily/weekly)
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
          final double plannedAmount = exp.amount; // as stored
          final double actualSpent = jarSpent[key] ?? 0.0;

          // Determine what amount to display
          double displayedAmount;
          double overBudgetRatio = 1.0;

          switch (exp.frequency) {
            case 'daily':
              // Show actual daily average if spent > 0, else planned daily
              displayedAmount = actualSpent > 0
                  ? (actualSpent /
                      (DateTime.now()
                              .difference(DateTime(
                                  DateTime.now().year, DateTime.now().month, 1))
                              .inDays +
                          1))
                  : plannedAmount;
              // Ratio: actual daily rate / planned daily
              final double actualDaily =
                  actualSpent > 0 ? displayedAmount : plannedAmount;
              overBudgetRatio =
                  plannedAmount > 0 ? actualDaily / plannedAmount : 1.0;
              break;

            case 'weekly':
              // Similar to daily but using weekly average – not used currently
              final weeksElapsed = ((DateTime.now()
                              .difference(DateTime(
                                  DateTime.now().year, DateTime.now().month, 1))
                              .inDays +
                          1) /
                      7)
                  .ceil();
              final double actualWeekly =
                  actualSpent > 0 ? actualSpent / weeksElapsed : 0;
              displayedAmount = actualSpent > 0 ? actualWeekly : plannedAmount;
              overBudgetRatio =
                  plannedAmount > 0 ? actualWeekly / plannedAmount : 1.0;
              break;

            case 'monthly':
              // Show total spent so far (or planned monthly if no spending)
              displayedAmount = actualSpent > 0 ? actualSpent : plannedAmount;
              // Ratio: spent / planned
              overBudgetRatio =
                  plannedAmount > 0 ? actualSpent / plannedAmount : 1.0;
              break;

            default:
              displayedAmount = plannedAmount;
          }

          return JarCardWidget(
            icon: _iconForFrequency(exp.frequency),
            name: exp.title,
            plannedAmount: exp.amount,
            frequency: exp.frequency,
            actualAmount: displayedAmount,
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
