import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'health_ring_widget.dart';
import 'jar_row_widget.dart';
import 'focus_card_widget.dart';
import 'home_header.dart';
import 'daily_allowance_card.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/expected_expenses_provider.dart';
import '../../providers/slip_up_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/number_formatter.dart';
import '../slip_up/slip_up_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expectedExpensesProvider);
    final allTxnsAsync = ref.watch(allTransactionsProvider);
    final daysSinceSlipUpAsync = ref.watch(daysSinceLastSlipUpProvider);
    final daysSinceSlipUp = daysSinceSlipUpAsync.valueOrNull;

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

    // Current month info
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysElapsed = now.difference(firstDay).inDays + 1; // today counts

    // --- Build a daily rate for each expected expense ---
    // If actual spending exists, use its daily average; else use the planned rate.
    final Map<String, double> dailyRates = {};
    for (final exp in expectedExpenses) {
      final key = exp.title.toLowerCase();
      final spent = jarSpent[key] ?? 0.0;
      double dailyRate;
      if (spent > 0) {
        // actual average per day
        dailyRate = spent / daysElapsed;
      } else {
        // planned rate based on frequency
        switch (exp.frequency) {
          case 'daily':
            dailyRate = exp.amount;
            break;
          case 'weekly':
            dailyRate = exp.amount / 7;
            break;
          case 'monthly':
            dailyRate = exp.amount / daysInMonth;
            break;
          default:
            dailyRate = exp.amount / daysInMonth;
        }
      }
      dailyRates[key] = dailyRate;
    }

    // Total allocated (monthly equivalent) = sum of dailyRates × daysInMonth
    double totalAllocated = 0;
    for (final rate in dailyRates.values) {
      totalAllocated += rate * daysInMonth;
    }

    double freeMoney = totalIncome - totalAllocated;
    if (freeMoney < 0) freeMoney = 0;

    // Days left in month
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final daysLeft = lastDayOfMonth.difference(now).inDays + 1;
    final double dailyAllowance =
        (freeMoney <= 0 || daysLeft <= 0) ? 0.0 : freeMoney / daysLeft;

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

    // --- Debug (remove later) ---
    print('=== HomeScreen Debug ===');
    print('totalIncome: $totalIncome');
    print('totalSpent: $totalSpent');
    print('leftAmount (ring): $leftAmount');
    print('dailyRates: $dailyRates');
    print('totalAllocated: $totalAllocated');
    print('freeMoney: $freeMoney');
    print('daysLeft: $daysLeft');
    print('dailyAllowance: $dailyAllowance');

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
                  daysSinceLastSlipUp: daysSinceSlipUp,
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SlipUpScreen()),
                      );
                    },
                    child: const Text(
                      "Had a rough day? It's okay.",
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 14),
                    ),
                  ),
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
