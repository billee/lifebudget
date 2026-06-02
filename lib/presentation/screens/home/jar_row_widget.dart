import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'jar_card_widget.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/expected_expense_model.dart';

class JarRowWidget extends StatelessWidget {
  final List<ExpectedExpense> expectedExpenses;
  final Map<String, double> jarSpent; // currently unused
  final double totalIncome; // currently unused

  const JarRowWidget({
    super.key,
    required this.expectedExpenses,
    required this.jarSpent,
    required this.totalIncome,
  });

  @override
  Widget build(BuildContext context) {
    // Sort expenses by amount (descending)
    final sorted = List<ExpectedExpense>.from(expectedExpenses)
      ..sort((a, b) => b.amount.compareTo(a.amount));

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: sorted.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final exp = sorted[index];
          // Allocated amount = the entered amount (could be daily/weekly/monthly)
          final allocated = exp.amount;
          // No spending yet
          final remaining = allocated;

          return JarCardWidget(
            icon: _iconForFrequency(exp.frequency),
            name: exp.title,
            remaining: remaining,
            total: allocated,
            color:
                AppColors.primary, // or a custom color per category if desired
          );
        },
      ),
    );
  }

  IconData _iconForFrequency(String frequency) {
    switch (frequency) {
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
}
