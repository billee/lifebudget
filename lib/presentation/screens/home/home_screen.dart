import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'health_ring_widget.dart';
import 'jar_row_widget.dart';
import 'focus_card_widget.dart';
import 'home_header.dart';
import 'daily_allowance_card.dart';
import 'goals_preview.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/expected_expenses_provider.dart';
import '../../../data/models/expected_expense_model.dart';
import '../../providers/slip_up_provider.dart';
import '../../providers/milestone_provider.dart';
import '../../providers/goal_provider.dart';
import '../../providers/settings_provider.dart';
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

    // ---- Survival Mode ----
    final settings = ref.watch(reminderSettingsProvider);
    final survivalMode = settings.survivalMode;

    // ---- Totals ----
    final now = DateTime.now();
    double totalIncome = 0;
    double totalExpenses = 0; // all expenses (incl. safely spend & deductions)
    double safelySpendSpent = 0;
    double deductionSpent = 0;
    final Map<String, double> jarSpent = {};
    final Map<String, DateTime> jarEarliestDate = {};
    DateTime? earliestDate;
    final currentMonth = DateTime(now.year, now.month, 1);

    for (final t in transactions) {
      if (t.date.isBefore(currentMonth)) continue;

      if (t.type == 'income') {
        totalIncome += t.amount;
      } else {
        totalExpenses += t.amount; // sum everything spent
        final jarLower = t.jar.toLowerCase();
        if (jarLower == 'safely spend') {
          safelySpendSpent += t.amount;
        } else if (jarLower.endsWith('_deduction')) {
          deductionSpent += t.amount;
        } else {
          var jar = jarLower;
          if (jar.startsWith('goal_')) jar = jar.substring(5);
          jarSpent[jar] = (jarSpent[jar] ?? 0) + t.amount;
          if (!jarEarliestDate.containsKey(jar) ||
              t.date.isBefore(jarEarliestDate[jar]!)) {
            jarEarliestDate[jar] = t.date;
          }
        }
      }
      if (earliestDate == null || t.date.isBefore(earliestDate)) {
        earliestDate = t.date;
      }
    }

    // Effective income for daily allowance calculation (unchanged)
    final effectiveIncome = totalIncome - safelySpendSpent - deductionSpent;
    // Remaining amount shown in ring = total income minus all expenses
    double leftAmount = totalIncome - totalExpenses;
    if (leftAmount < 0) leftAmount = 0;

    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    // Tracking days
    final DateTime trackingStartDate = earliestDate ?? now;
    final int trackingDaysElapsed =
        max(1, now.difference(trackingStartDate).inDays + 1);

    // ---- Planned allocations (monthly) ----
    // Filter out 'Safely Spend' from calculations (it's a derived value)
    final realExpenses = expectedExpenses
        .where((e) => e.title.toLowerCase() != 'safely spend')
        .toList();

    final workingList = survivalMode
        ? realExpenses
            .where((e) => ['food', 'transport', 'rent', 'utilities']
                .contains(e.title.toLowerCase()))
            .where((e) => e.amount > 0)
            .toList()
        : realExpenses.where((e) => e.amount > 0).toList();

    double plannedMonthlyTotal = 0;
    for (final exp in realExpenses) {
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

    double freeMoney = effectiveIncome - plannedMonthlyTotal;
    if (freeMoney < 0) freeMoney = 0;

    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final daysLeft = lastDayOfMonth.difference(now).inDays + 1;
    final double dailyAllowance =
        (freeMoney <= 0 || daysLeft <= 0) ? 0.0 : freeMoney / daysLeft;

    // Safely Spend amount (displayed in its own section)
    final safelySpendAmount = dailyAllowance * daysLeft;
    final monthStr = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    if (safelySpendAmount > 0) {
      final existingSafelySpend = expectedExpenses
          .where((e) =>
              e.title.toLowerCase() == 'safely spend' && e.month == monthStr)
          .firstOrNull;

      if (existingSafelySpend == null ||
          (existingSafelySpend.amount - safelySpendAmount).abs() > 1.0) {
        Future.microtask(() async {
          final repo = ref.read(expectedExpenseRepositoryProvider);
          await repo.upsertSafelySpend(safelySpendAmount, monthStr);
          ref.invalidate(expectedExpensesProvider); // keep Profile page in sync
        });
      }
    }

    // ---- Overspent analysis (using tracking days) ----
    String? mostOverspentCategory;
    double maxOverRatio = 1.0;
    for (final exp in expectedExpenses) {
      if (exp.frequency == 'monthly') continue;
      final key = exp.title.toLowerCase();
      final plannedDaily =
          (exp.frequency == 'daily') ? exp.amount : exp.amount / 7;
      final actualSpent = jarSpent[key] ?? 0;
      final actualDaily =
          trackingDaysElapsed > 0 ? actualSpent / trackingDaysElapsed : 0;
      if (plannedDaily > 0) {
        final ratio = actualDaily / plannedDaily;
        if (ratio > maxOverRatio) {
          maxOverRatio = ratio;
          mostOverspentCategory = exp.title;
        }
      }
    }
    final bool isOverBudget = maxOverRatio > 1.0;

    // ---- Nearest goal nudge (only in normal mode) ----
    String? nearestGoalMessage;
    if (!survivalMode) {
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
        const HomeHeader(),
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
                    totalBudget: totalIncome, // now shows total monthly income
                  ),
                  const SizedBox(height: 16),
                  DailyAllowanceCard(
                    dailyAllowance: dailyAllowance,
                    daysLeft: daysLeft,
                  ),
                  const SizedBox(height: 16),
                  JarRowWidget(
                    expectedExpenses: workingList,
                    jarSpent: jarSpent,
                    totalIncome: effectiveIncome,
                    trackingDaysElapsed: trackingDaysElapsed,
                    dailyAllowance: dailyAllowance,
                    jarEarliestDate: jarEarliestDate,
                    goalTitles: goalsAsync.valueOrNull
                            ?.map((g) => g.title.toLowerCase())
                            .toSet() ??
                        {},
                  ),
                  if (!survivalMode) ...[
                    const SizedBox(height: 24),
                    const GoalsPreview(),
                    if (safelySpendAmount > 0) ...[
                      const SizedBox(height: 24),
                      _SafelySpendSection(
                        budget: safelySpendAmount,
                        spent: safelySpendSpent,
                        daysLeft: daysLeft,
                        dailyAllowance: dailyAllowance,
                      ),
                    ],
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

class _SafelySpendSection extends StatelessWidget {
  final double budget;
  final double spent;
  final int daysLeft;
  final double dailyAllowance;

  const _SafelySpendSection({
    required this.budget,
    required this.spent,
    required this.daysLeft,
    required this.dailyAllowance,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = budget - spent;
    final progress = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet,
                  size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Safely Spend',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${formatAmount(dailyAllowance)}/day',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 14,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    color: progress >= 0.9
                        ? AppColors.critical
                        : AppColors.primary,
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spent: ${formatAmount(spent)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                'Budget: ${formatAmount(budget)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Remaining: ${formatAmount(remaining > 0 ? remaining : 0)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: remaining > 0 ? AppColors.onTrack : AppColors.critical,
            ),
          ),
        ],
      ),
    );
  }
}
