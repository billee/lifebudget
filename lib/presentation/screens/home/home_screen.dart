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
import '../../../core/utils/emotional_messages.dart';
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

    // ---- Totals ----
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

    // ---- Time helpers ----
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysElapsed = now.difference(firstDay).inDays + 1; // today counts

    // ---- Planned daily rates ----
    final Map<String, double> plannedDailyRates = {};
    for (final exp in expectedExpenses) {
      final key = exp.title.toLowerCase();
      switch (exp.frequency) {
        case 'daily':
          plannedDailyRates[key] = exp.amount;
          break;
        case 'weekly':
          plannedDailyRates[key] = exp.amount / 7;
          break;
        case 'monthly':
          plannedDailyRates[key] = exp.amount / daysInMonth;
          break;
      }
    }

    // ---- Actual daily rates (from spending) ----
    final Map<String, double> actualDailyRates = {};
    for (final entry in jarSpent.entries) {
      actualDailyRates[entry.key] = entry.value / daysElapsed;
    }
    // For categories with no spending, use planned rate
    for (final exp in expectedExpenses) {
      final key = exp.title.toLowerCase();
      if (!actualDailyRates.containsKey(key)) {
        actualDailyRates[key] = plannedDailyRates[key] ?? 0;
      }
    }

    // ---- Monthly allocations based on actual daily rates ----
    double totalAllocated = 0;
    for (final rate in actualDailyRates.values) {
      totalAllocated += rate * daysInMonth;
    }

    double freeMoney = totalIncome - totalAllocated;
    if (freeMoney < 0) freeMoney = 0;

    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final daysLeft = lastDayOfMonth.difference(now).inDays + 1;
    final double dailyAllowance =
        (freeMoney <= 0 || daysLeft <= 0) ? 0.0 : freeMoney / daysLeft;

    // ---- Find most overspent category ----
    String? mostOverspentCategory;
    double maxOverRatio = 1.0;
    for (final exp in expectedExpenses) {
      final key = exp.title.toLowerCase();
      final planned = plannedDailyRates[key] ?? 0;
      final actual = actualDailyRates[key] ?? 0;
      if (planned > 0) {
        final ratio = actual / planned;
        if (ratio > maxOverRatio) {
          maxOverRatio = ratio;
          mostOverspentCategory = exp.title;
        }
      }
    }
    final bool isOverBudget = maxOverRatio > 1.0;

    // ---- Emotional messages ----
    String statusLine;
    String? focusOverrideMessage;

    if (totalIncome == 0) {
      statusLine = getRandomMessage('no_income');
      focusOverrideMessage = null;
    } else if (isOverBudget && mostOverspentCategory != null) {
      statusLine =
          getRandomMessage('overspent', category: mostOverspentCategory);
      focusOverrideMessage =
          getRandomMessage('overspent', category: mostOverspentCategory);
    } else if (freeMoney <= 0) {
      statusLine = getRandomMessage('tight');
      focusOverrideMessage = null;
    } else {
      statusLine = getRandomMessage('on_track');
      focusOverrideMessage = null;
    }

    // ---- UI ----
    return Column(
      children: [
        HomeHeader(statusLine: statusLine),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              // Invalidate a provider to rebuild and get a new random message
              ref.invalidate(allTransactionsProvider);
            },
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
                    dailyRates: actualDailyRates,
                    plannedRates: plannedDailyRates,
                  ),
                  const SizedBox(height: 24),
                  FocusCardWidget(
                    dailyAllowance: dailyAllowance,
                    daysLeft: daysLeft,
                    daysSinceLastSlipUp: daysSinceSlipUp,
                    overrideMessage: focusOverrideMessage,
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const SlipUpScreen()),
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
        ),
      ],
    );
  }
}
