import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'health_ring_widget.dart';
import 'jar_row_widget.dart';
import 'focus_card_widget.dart';
import 'home_header.dart';
import 'daily_allowance_card.dart';
import '../../providers/transaction_provider.dart'; // jarSummariesProvider
import '../../providers/budget_provider.dart'; // jarAllocationsProvider

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allocationsAsync = ref.watch(jarAllocationsProvider);
    final summariesAsync = ref.watch(jarSummariesProvider);

    // Show loading until both are ready
    if (allocationsAsync.isLoading || summariesAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Handle errors gracefully
    if (allocationsAsync.hasError || summariesAsync.hasError) {
      return const Center(
        child: Text('Something went wrong. Please restart the app.',
            style: TextStyle(fontSize: 16)),
      );
    }

    final allocations = allocationsAsync.value!;
    final summaries = summariesAsync.value!;

    // Total income for the month (from summaries)
    final totalIncome = summaries['__total_income__'] ?? 0.0;

    // Total spent (sum of all expenses)
    double totalSpent = 0;
    final Map<String, double> jarSpent = {};
    for (final entry in summaries.entries) {
      if (entry.key == '__total_income__') continue;
      jarSpent[entry.key] = entry.value;
      totalSpent += entry.value;
    }

    // Left to use = income - spent
    double leftAmount = totalIncome - totalSpent;
    if (leftAmount < 0) leftAmount = 0;

    // Daily allowance calculation
    final now = DateTime.now();
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final daysLeft = lastDayOfMonth.difference(now).inDays + 1;
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
                  totalBudget:
                      totalIncome, // now the ring says "of your income"
                ),
                const SizedBox(height: 16),
                DailyAllowanceCard(
                  dailyAllowance: dailyAllowance,
                  daysLeft: daysLeft,
                ),
                const SizedBox(height: 16),
                JarRowWidget(
                  allocations: allocations,
                  jarSpent: jarSpent,
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
