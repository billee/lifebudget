import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'health_ring_widget.dart';
import 'jar_row_widget.dart';
import 'focus_card_widget.dart';
import 'home_header.dart';
import 'daily_allowance_card.dart';
import 'goals_preview.dart';
import 'insights_card_widget.dart';
import 'celebration_overlay.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/expected_expenses_provider.dart';
import '../../providers/slip_up_provider.dart';
import '../../providers/milestone_provider.dart';
import '../../providers/goal_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/emotional_messages.dart';
import '../../../core/utils/number_formatter.dart';
import '../slip_up/slip_up_screen.dart';
import '../what_if/what_if_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expectedExpensesProvider);
    final allTxnsAsync = ref.watch(allTransactionsProvider);
    final daysSinceSlipUpAsync = ref.watch(daysSinceLastSlipUpProvider);
    final milestoneAsync = ref.watch(newMilestoneProvider);
    final goalsAsync = ref.watch(goalsProvider);

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
    final daysSinceSlipUp = daysSinceSlipUpAsync.valueOrNull;
    final milestone = milestoneAsync.valueOrNull;

    // ---- Totals (income, actual spending) ----
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
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final firstDay = DateTime(now.year, now.month, 1);
    final daysElapsed = now.difference(firstDay).inDays + 1;

    // ---- Planned monthly allocations (from fixed expected expenses) ----
    double plannedMonthlyTotal = 0;
    for (final exp in expectedExpenses) {
      switch (exp.frequency) {
        case 'daily':
          plannedMonthlyTotal += exp.amount * daysInMonth;
          break;
        case 'weekly':
          plannedMonthlyTotal += exp.amount * (daysInMonth / 7);
          break;
        case 'monthly':
          plannedMonthlyTotal += exp.amount;
          break;
      }
    }

    // Free money after planned allocations
    double freeMoney = totalIncome - plannedMonthlyTotal;
    if (freeMoney < 0) freeMoney = 0;

    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final daysLeft = lastDayOfMonth.difference(now).inDays + 1;
    final double dailyAllowance =
        (freeMoney <= 0 || daysLeft <= 0) ? 0.0 : freeMoney / daysLeft;

    // ---- Overspent analysis (for daily/weekly only) ----
    String? mostOverspentCategory;
    double maxOverRatio = 1.0;
    for (final exp in expectedExpenses) {
      if (exp.frequency == 'monthly') continue; // skip fixed expenses
      final key = exp.title.toLowerCase();
      final plannedDaily = (exp.frequency == 'daily')
          ? exp.amount
          : exp.amount / 7; // weekly → daily rate
      final actualSpent = jarSpent[key] ?? 0;
      final actualDaily = actualSpent / daysElapsed;
      if (plannedDaily > 0) {
        final ratio = actualDaily / plannedDaily;
        if (ratio > maxOverRatio) {
          maxOverRatio = ratio;
          mostOverspentCategory = exp.title;
        }
      }
    }
    final bool isOverBudget = maxOverRatio > 1.0;

    // ---- Nearest goal nudge ----
    String? nearestGoalMessage;
    final goals = goalsAsync.valueOrNull ?? [];
    if (goals.isNotEmpty) {
      final incomplete = goals.where((g) => !g.isCompleted).toList();
      if (incomplete.isNotEmpty) {
        incomplete.sort((a, b) {
          final remainingA = a.targetAmount - a.currentAmount;
          final remainingB = b.targetAmount - b.currentAmount;
          return remainingA.compareTo(remainingB);
        });
        final closest = incomplete.first;
        final remaining = closest.targetAmount - closest.currentAmount;
        if (remaining <= 500) {
          nearestGoalMessage =
              "You're ${formatAmount(remaining)} away from “${closest.title}”. "
              "You're almost there!";
        }
      }
    }

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
                  ),
                  const SizedBox(height: 24),
                  const GoalsPreview(),
                  if (goals.any((g) => !g.isCompleted))
                    const SizedBox(height: 24),
                  // ---- Insights ----
                  const InsightsCardWidget(),
                  const SizedBox(height: 24),
                  // ---- Milestone or Focus Card ----
                  if (milestone != null)
                    CelebrationOverlay(
                      milestone: milestone,
                      onDismiss: () async {
                        final prefs = await SharedPreferences.getInstance();
                        final shown =
                            prefs.getStringList('shown_milestones') ?? [];
                        shown.add(milestone.id);
                        await prefs.setStringList('shown_milestones', shown);
                        ref.invalidate(newMilestoneProvider);
                        ref.invalidate(shownMilestonesProvider);
                      },
                    )
                  else ...[
                    FocusCardWidget(
                      dailyAllowance: dailyAllowance,
                      daysLeft: daysLeft,
                      daysSinceLastSlipUp: daysSinceSlipUp,
                      overrideMessage: focusOverrideMessage,
                      nearestGoalMessage: nearestGoalMessage,
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
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const WhatIfScreen()),
                          );
                        },
                        child: const Text(
                          "What if I saved a little?",
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
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
