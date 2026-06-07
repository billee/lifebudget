import 'dart:math';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'jar_card_widget.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/expected_expense_model.dart';

class JarRowWidget extends StatelessWidget {
  final List<ExpectedExpense> expectedExpenses;
  final Map<String, double> jarSpent;
  final double totalIncome;
  final int trackingDaysElapsed;
  final double dailyAllowance;
  final Map<String, DateTime> jarEarliestDate;
  final Set<String> goalTitles;

  const JarRowWidget({
    super.key,
    required this.expectedExpenses,
    required this.jarSpent,
    required this.totalIncome,
    required this.trackingDaysElapsed,
    required this.dailyAllowance,
    this.jarEarliestDate = const {},
    this.goalTitles = const {},
  });

  @override
  Widget build(BuildContext context) {
    final sorted = List<ExpectedExpense>.from(expectedExpenses)
      ..sort((a, b) => b.amount.compareTo(a.amount));

    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: sorted.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final exp = sorted[index];
          final key = exp.title.toLowerCase();
          final double plannedAmount = exp.amount;
          final double actualSpent = jarSpent[key] ?? 0.0;

          double overBudgetRatio = 1.0;
          double? actualAverage;
          String? monthlyStatus;

          // Use jar-specific days elapsed for daily average
          final jarFirstDate = jarEarliestDate[key];
          final today = DateTime.now();
          final todayMidnight = DateTime(today.year, today.month, today.day);
          final jarDaysElapsed = jarFirstDate != null
              ? max(
                  1,
                  todayMidnight
                          .difference(DateTime(jarFirstDate.year,
                              jarFirstDate.month, jarFirstDate.day))
                          .inDays +
                      1)
              : trackingDaysElapsed;

          switch (exp.frequency) {
            case 'daily':
              actualAverage =
                  jarDaysElapsed > 0 ? actualSpent / jarDaysElapsed : null;
              overBudgetRatio = (plannedAmount > 0 && actualAverage != null)
                  ? actualAverage / plannedAmount
                  : 1.0;
              break;
            case 'weekly':
              final weeksElapsed = (trackingDaysElapsed / 7).ceil();
              actualAverage =
                  weeksElapsed > 0 ? actualSpent / weeksElapsed : null;
              overBudgetRatio = (plannedAmount > 0 && actualAverage != null)
                  ? actualAverage / plannedAmount
                  : 1.0;
              break;
            case 'monthly':
              actualAverage = null;
              overBudgetRatio =
                  plannedAmount > 0 ? actualSpent / plannedAmount : 1.0;
              // Determine monthly status
              if (actualSpent >= plannedAmount && plannedAmount > 0) {
                monthlyStatus = 'Paid';
              } else if (dailyAllowance > 0) {
                monthlyStatus = 'On track';
              } else {
                monthlyStatus = 'Unsure';
              }
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
              actualAverage: actualAverage,
              monthlyStatus: monthlyStatus,
              isGoal: goalTitles.contains(key),
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
