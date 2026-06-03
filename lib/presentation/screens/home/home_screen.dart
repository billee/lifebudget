import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'health_ring_widget.dart';
import 'jar_row_widget.dart';
import 'focus_card_widget.dart';
import 'home_header.dart';
import 'daily_allowance_card.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/expected_expenses_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expectedExpensesProvider);
    final allTxnsAsync = ref.watch(allTransactionsProvider);

    if (expensesAsync.isLoading || allTxnsAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (expensesAsync.hasError || allTxnsAsync.hasError) {
      return const Center(
        child: Text('Something went wrong. Please restart the app.',
            style: TextStyle(fontSize: 16)),
      );
    }

    final expectedExpenses = expensesAsync.value!;
    final transactions = allTxnsAsync.value!;

    double totalIncome = 0;
    double totalSpent = 0;
    final Map<String, double> jarSpent = {};

    for (final t in transactions) {
      if (t.type == 'income') {
        totalIncome += t.amount;
      } else {
        totalSpent += t.amount;
        final jar = t.jar.toLowerCase();
        jarSpent[jar] = (jarSpent[jar] ?? 0) + t.amount;
      }
    }

    double leftAmount = totalIncome - totalSpent;
    if (leftAmount < 0) leftAmount = 0;

    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    double totalAllocated = 0;
    for (final exp in expectedExpenses) {
      switch (exp.frequency) {
        case 'daily':
          totalAllocated += exp.amount * daysInMonth;
          break;
        case 'weekly':
          totalAllocated += exp.amount * (daysInMonth / 7);
          break;
        case 'monthly':
          totalAllocated += exp.amount;
          break;
      }
    }

    double freeMoney = totalIncome - totalAllocated;
    if (freeMoney < 0) freeMoney = 0;

    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final daysLeft = lastDayOfMonth.difference(now).inDays + 1;
    final double dailyAllowance =
        daysLeft > 0 ? freeMoney / daysLeft : freeMoney;

    // --- Status line for top header ---
    String statusLine;
    if (totalIncome == 0) {
      statusLine = "Let’s start by adding your income for the month.";
    } else if (freeMoney <= 0) {
      statusLine = "Every peso has a job — you’re on top of your plan.";
    } else if (freeMoney < totalIncome * 0.1) {
      statusLine = "A little tight — but still manageable.";
    } else {
      statusLine = "You’re on track this week.";
    }

    return Column(
      children: [
        HomeHeader(statusLine: statusLine),
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
                  jarSpent: jarSpent,
                  totalIncome: totalIncome,
                ),
                const SizedBox(height: 24),
                FocusCardWidget(
                  dailyAllowance: dailyAllowance,
                  daysLeft: daysLeft,
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
