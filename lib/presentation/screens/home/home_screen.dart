import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'health_ring_widget.dart';
import 'jar_row_widget.dart';
import 'focus_card_widget.dart';
import 'home_header.dart';
import 'daily_allowance_card.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/budget_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budget = ref.watch(budgetProvider);
    final jarSummariesAsync = ref.watch(jarSummariesProvider);

    final totalBudget = budget.totalBudget;
    double totalSpent = 0;
    final Map<String, double> jarSpent = {};

    jarSummariesAsync.whenData((summaries) {
      for (final entry in summaries.entries) {
        if (entry.key == '__total_income__') continue;
        jarSpent[entry.key] = entry.value;
        totalSpent += entry.value;
      }
    });

    double leftAmount = totalBudget - totalSpent;
    if (leftAmount < 0) leftAmount = 0;

    // Days left in the current month (including today)
    final now = DateTime.now();
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final daysLeft = lastDayOfMonth.difference(now).inDays + 1; // today counts

    final double dailyAllowance =
        daysLeft > 0 ? leftAmount / daysLeft : leftAmount;

    return Column(
      children: [
        const HomeHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HealthRingWidget(
                  leftAmount: leftAmount,
                  totalBudget: totalBudget,
                ),
                const SizedBox(height: 16),
                DailyAllowanceCard(
                  dailyAllowance: dailyAllowance,
                  daysLeft: daysLeft,
                ),
                const SizedBox(height: 16),
                JarRowWidget(jarSpent: jarSpent),
                const SizedBox(height: 24),
                const FocusCardWidget(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
