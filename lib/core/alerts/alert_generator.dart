import 'package:flutter/material.dart';
import 'alert_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/goal_model.dart';
import '../../data/models/slip_up_model.dart';

/// Generates budget alerts from current data.
class AlertGenerator {
  /// Generate all alerts from the provided data.
  static List<BudgetAlert> generate({
    required List<TransactionModel> transactions,
    required Map<String, double> jarSpent,
    required Map<String, double> allocations,
    required double totalIncome,
    required List<Goal> goals,
    required List<SlipUp> slipUps,
    required int daysSinceLastLog,
  }) {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysElapsed = now.difference(firstDay).inDays + 1;

    // Filter to current month transactions
    final currentMonthTxns =
        transactions.where((t) => !t.date.isBefore(firstDay)).toList();

    final alerts = <BudgetAlert>[];

    // ── 1. Spending pace warning ──
    if (totalIncome > 0 && daysElapsed > 0) {
      final totalExpenses = currentMonthTxns
          .where((t) => t.type == 'expense' || t.type == 'savings')
          .fold<double>(0, (sum, t) => sum + t.amount);
      final dailyRate = totalExpenses / daysElapsed;
      final projected = dailyRate * daysInMonth;

      if (projected > totalIncome) {
        alerts.add(BudgetAlert(
          title: 'Overspending Alert',
          message:
              'At your current pace, you\'ll spend \$${projected.toStringAsFixed(0)} this month — that\'s \$${(projected - totalIncome).toStringAsFixed(0)} over your \$${totalIncome.toStringAsFixed(0)} income.',
          icon: Icons.trending_up,
          type: AlertType.warning,
          timestamp: now,
        ));
      }
    }

    // ── 2. Jar budget warnings (jar spent > 80% of allocation) ──
    if (totalIncome > 0) {
      for (final entry in jarSpent.entries) {
        final jar = entry.key;
        final spent = entry.value;
        final pctAlloc = allocations[jar] ?? 0;
        if (pctAlloc <= 0) continue;

        final budget = totalIncome * (pctAlloc / 100);
        if (budget <= 0) continue;

        final pctUsed = (spent / budget) * 100;

        if (pctUsed >= 100) {
          alerts.add(BudgetAlert(
            title: '${_capitalize(jar)} budget exceeded',
            message:
                'You\'ve spent \$${spent.toStringAsFixed(0)} out of \$${budget.toStringAsFixed(0)} allocated to ${jar}.',
            icon: Icons.warning_amber_rounded,
            type: AlertType.warning,
            timestamp: now,
          ));
        } else if (pctUsed >= 80) {
          alerts.add(BudgetAlert(
            title: '${_capitalize(jar)} budget running low',
            message:
                'You\'ve used ${pctUsed.toStringAsFixed(0)}% of your ${jar} budget (\$${spent.toStringAsFixed(0)} / \$${budget.toStringAsFixed(0)}).',
            icon: Icons.info_outline,
            type: AlertType.info,
            timestamp: now,
          ));
        }
      }
    }

    // ── 3. Goal milestones (50%, 80%, 100%) ──
    for (final goal in goals) {
      if (goal.targetAmount <= 0) continue;
      final pct = (goal.currentAmount / goal.targetAmount) * 100;

      if (goal.isCompleted || pct >= 100) {
        alerts.add(BudgetAlert(
          title: 'Goal complete! 🎉',
          message:
              '${goal.emoji} "${goal.title}" is fully funded at \$${goal.targetAmount.toStringAsFixed(0)}!',
          icon: Icons.celebration,
          type: AlertType.achievement,
          timestamp: now,
        ));
      } else if (pct >= 80) {
        alerts.add(BudgetAlert(
          title: 'Almost there!',
          message:
              '${goal.emoji} "${goal.title}" is ${pct.toStringAsFixed(0)}% funded. Just \$${(goal.targetAmount - goal.currentAmount).toStringAsFixed(0)} to go!',
          icon: Icons.flag_rounded,
          type: AlertType.achievement,
          timestamp: now,
        ));
      }
    }

    // ── 4. No expenses logged recently ──
    if (daysSinceLastLog >= 3) {
      alerts.add(BudgetAlert(
        title: 'No expenses logged',
        message:
            'You haven\'t logged any expenses in $daysSinceLastLog days. Everything okay? Keeping track builds awareness.',
        icon: Icons.edit_note_rounded,
        type: AlertType.info,
        timestamp: now,
      ));
    }

    // ── 5. Streak: days within budget ──
    if (totalIncome > 0 && daysElapsed >= 3) {
      final dailyBudget = totalIncome / daysInMonth;
      // Count consecutive days within daily budget (from today backwards)
      int streak = 0;
      final spendingByDay = <String, double>{};
      for (final t in currentMonthTxns) {
        if (t.type == 'expense') {
          final key = '${t.date.year}-${t.date.month}-${t.date.day}';
          spendingByDay[key] = (spendingByDay[key] ?? 0) + t.amount;
        }
      }
      for (int d = 0; d < daysElapsed; d++) {
        final date = DateTime(now.year, now.month, now.day - d);
        final key = '${date.year}-${date.month}-${date.day}';
        final daySpent = spendingByDay[key] ?? 0;
        if (daySpent > 0 && daySpent <= dailyBudget) {
          streak++;
        } else if (daySpent == 0 && d > 0) {
          // No spending on a past day — might be fine, continue streak
          streak++;
        } else {
          break;
        }
      }

      if (streak >= 7) {
        alerts.add(BudgetAlert(
          title: '$streak-day streak! 🔥',
          message:
              'You\'ve stayed within budget for $streak days straight. Keep it up!',
          icon: Icons.local_fire_department,
          type: AlertType.achievement,
          timestamp: now,
        ));
      } else if (streak >= 3) {
        alerts.add(BudgetAlert(
          title: '$streak-day streak',
          message: 'Nice! $streak days within budget. Can you make it a week?',
          icon: Icons.whatshot,
          type: AlertType.achievement,
          timestamp: now,
        ));
      }
    }

    // ── 6. Slip-up follow-up ──
    if (slipUps.isNotEmpty) {
      final lastSlipUp = slipUps.first;
      final daysSince = now.difference(lastSlipUp.date).inDays;
      if (daysSince == 1) {
        alerts.add(BudgetAlert(
          title: 'How\'s today going?',
          message:
              'You logged a slip-up yesterday. Today\'s a fresh start — small wins count!',
          icon: Icons.favorite,
          type: AlertType.info,
          timestamp: now,
        ));
      }
    }

    // ── 7. Low daily allowance ──
    if (totalIncome > 0 && daysElapsed > 0) {
      final totalMonthlyExpenses = currentMonthTxns
          .where((t) => t.type == 'expense' || t.type == 'savings')
          .fold<double>(0, (sum, t) => sum + t.amount);
      final remaining = totalIncome - totalMonthlyExpenses;
      final daysLeft = daysInMonth - daysElapsed + 1;
      if (daysLeft > 0) {
        final dailyAllowance = remaining / daysLeft;
        if (dailyAllowance < 10 && dailyAllowance >= 0) {
          alerts.add(BudgetAlert(
            title: 'Tight budget ahead',
            message:
                'Your daily allowance is only \$${dailyAllowance.toStringAsFixed(2)} for the rest of the month. Plan carefully!',
            icon: Icons.attach_money,
            type: AlertType.warning,
            timestamp: now,
          ));
        }
      }
    }

    // Sort: warnings first, then info, then achievements
    alerts.sort((a, b) => _priority(a.type) - _priority(b.type));
    return alerts;
  }

  static int _priority(AlertType t) {
    switch (t) {
      case AlertType.warning:
        return 0;
      case AlertType.info:
        return 1;
      case AlertType.achievement:
        return 2;
    }
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
