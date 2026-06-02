import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'health_ring_widget.dart';
import 'jar_row_widget.dart';
import 'focus_card_widget.dart';
import 'home_header.dart';
import 'daily_allowance_card.dart';
import '../../providers/transaction_provider.dart'; // jarSummariesProvider
import '../../providers/expected_expenses_provider.dart'; // expectedExpensesProvider

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expectedExpensesProvider);
    final summariesAsync = ref.watch(jarSummariesProvider);

    if (expensesAsync.isLoading || summariesAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (expensesAsync.hasError || summariesAsync.hasError) {
      return const Center(
        child: Text('Something went wrong. Please restart the app.',
            style: TextStyle(fontSize: 16)),
      );
    }

    final expectedExpenses = expensesAsync.value!;
    final summaries = summariesAsync.value!;

    // Total income
    final totalIncome = summaries['__total_income__'] ?? 0.0;

    // Total spent
    double totalSpent = 0;
    for (final entry in summaries.entries) {
      if (entry.key == '__total_income__') continue;
      totalSpent += entry.value;
    }

    // Left to use (actual)
    double leftAmount = totalIncome - totalSpent;
    if (leftAmount < 0) leftAmount = 0;

    // Total allocated from expected expenses (convert to monthly equivalent)
    double totalAllocated = 0;
    for (final exp in expectedExpenses) {
      switch (exp.frequency) {
        case 'daily':
          totalAllocated += exp.amount * 30; // approximate
          break;
        case 'weekly':
          totalAllocated += exp.amount * 4.33;
          break;
        case 'monthly':
          totalAllocated += exp.amount;
          break;
      }
    }

    // Free money = income - planned
    double freeMoney = totalIncome - totalAllocated;
    if (freeMoney < 0) freeMoney = 0;

    // Daily allowance based on free money
    final now = DateTime.now();
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final daysLeft = lastDayOfMonth.difference(now).inDays + 1;
    final double dailyAllowance =
        daysLeft > 0 ? freeMoney / daysLeft : freeMoney;

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
                  totalBudget: totalIncome,
                ),
                const SizedBox(height: 16),
                DailyAllowanceCard(
                  dailyAllowance: dailyAllowance,
                  daysLeft: daysLeft,
                ),
                const SizedBox(height: 16),
                JarRowWidget(
                  expectedExpenses: expectedExpenses,
                  jarSpent: {}, // no spending linked yet
                  totalIncome: totalIncome,
                ),
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
