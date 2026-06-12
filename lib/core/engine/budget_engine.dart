import 'dart:convert';
import 'package:equatable/equatable.dart';

/// Represents a single income transaction (actual or expected).
class IncomeEntry {
  final double amount;
  final DateTime date;
  final String? description;

  IncomeEntry({required this.amount, required this.date, this.description});

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'date': date.toIso8601String().substring(0, 10),
        'description': description,
      };
}

/// Represents a planned expense category.
class ExpenseCategory {
  final String name;
  final double amount; // per frequency
  final String frequency; // 'daily', 'weekly', 'monthly'
  final String? description;

  ExpenseCategory({
    required this.name,
    required this.amount,
    required this.frequency,
    this.description,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'amount': amount,
        'frequency': frequency,
        'description': description,
      };
}

/// Represents a real expense transaction.
class ExpenseTransaction {
  final String category; // must match an ExpenseCategory name
  final double amount;
  final DateTime date;
  final String? note;

  ExpenseTransaction({
    required this.category,
    required this.amount,
    required this.date,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'category': category,
        'amount': amount,
        'date': date.toIso8601String().substring(0, 10),
        'note': note,
      };
}

/// The complete output of the budget engine.
class BudgetState extends Equatable {
  final List<IncomeEntry> expectedIncomes;
  final List<IncomeEntry> actualIncomes;
  final List<ExpenseCategory> expectedExpenses;
  final List<ExpenseTransaction> actualExpenses;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime today;
  final int daysInPeriod;
  final int daysElapsed; // days from startDate to today (inclusive)
  final int daysLeft;
  final double totalExpectedIncome;
  final double totalActualIncome;
  final Map<String, double> plannedTotalPerCategory;
  final double totalPlannedExpenses;
  final Map<String, double> plannedUpToTodayPerCategory;
  final double totalPlannedUpToToday;
  final Map<String, double> plannedRemainingPerCategory;
  final double totalPlannedRemaining;
  final double originalDailyAllowance;
  final double totalSafelySpendBudget;
  final double safelySpendSpent;
  final double remainingSafelySpend;
  final double currentDailyAllowance;
  final Map<String, double> actualSpentPerCategory;
  final Map<String, double>
      remainingPerCategory; // total planned - actual spent

  const BudgetState({
    required this.expectedIncomes,
    required this.actualIncomes,
    required this.expectedExpenses,
    required this.actualExpenses,
    required this.startDate,
    required this.endDate,
    required this.today,
    required this.daysInPeriod,
    required this.daysElapsed,
    required this.daysLeft,
    required this.totalExpectedIncome,
    required this.totalActualIncome,
    required this.plannedTotalPerCategory,
    required this.totalPlannedExpenses,
    required this.plannedUpToTodayPerCategory,
    required this.totalPlannedUpToToday,
    required this.plannedRemainingPerCategory,
    required this.totalPlannedRemaining,
    required this.originalDailyAllowance,
    required this.totalSafelySpendBudget,
    required this.safelySpendSpent,
    required this.remainingSafelySpend,
    required this.currentDailyAllowance,
    required this.actualSpentPerCategory,
    required this.remainingPerCategory,
  });

  @override
  List<Object?> get props => [
        expectedIncomes,
        actualIncomes,
        expectedExpenses,
        actualExpenses,
        startDate,
        endDate,
        today,
        daysInPeriod,
        daysElapsed,
        daysLeft,
        totalExpectedIncome,
        totalActualIncome,
        plannedTotalPerCategory,
        totalPlannedExpenses,
        plannedUpToTodayPerCategory,
        totalPlannedUpToToday,
        plannedRemainingPerCategory,
        totalPlannedRemaining,
        originalDailyAllowance,
        totalSafelySpendBudget,
        safelySpendSpent,
        remainingSafelySpend,
        currentDailyAllowance,
        actualSpentPerCategory,
        remainingPerCategory,
      ];

  Map<String, dynamic> toJson() {
    return {
      'expectedIncomes': expectedIncomes.map((e) => e.toJson()).toList(),
      'actualIncomes': actualIncomes.map((e) => e.toJson()).toList(),
      'expectedExpenses': expectedExpenses.map((e) => e.toJson()).toList(),
      'actualExpenses': actualExpenses.map((e) => e.toJson()).toList(),
      'startDate': startDate.toIso8601String().substring(0, 10),
      'endDate': endDate.toIso8601String().substring(0, 10),
      'today': today.toIso8601String().substring(0, 10),
      'daysInPeriod': daysInPeriod,
      'daysElapsed': daysElapsed,
      'daysLeft': daysLeft,
      'totalExpectedIncome': totalExpectedIncome,
      'totalActualIncome': totalActualIncome,
      'plannedTotalPerCategory': plannedTotalPerCategory,
      'totalPlannedExpenses': totalPlannedExpenses,
      'plannedUpToTodayPerCategory': plannedUpToTodayPerCategory,
      'totalPlannedUpToToday': totalPlannedUpToToday,
      'plannedRemainingPerCategory': plannedRemainingPerCategory,
      'totalPlannedRemaining': totalPlannedRemaining,
      'originalDailyAllowance': originalDailyAllowance,
      'totalSafelySpendBudget': totalSafelySpendBudget,
      'safelySpendSpent': safelySpendSpent,
      'remainingSafelySpend': remainingSafelySpend,
      'currentDailyAllowance': currentDailyAllowance,
      'actualSpentPerCategory': actualSpentPerCategory,
      'remainingPerCategory': remainingPerCategory,
    };
  }
}

/// Core engine that computes all budget metrics from input data.
class BudgetEngine {
  static BudgetState compute({
    required List<IncomeEntry> actualIncomes,
    required List<IncomeEntry> expectedIncomes,
    required List<ExpenseCategory> expectedExpenses,
    List<ExpenseTransaction> actualExpenses = const [],
    DateTime? endDate,
    DateTime? today,
  }) {
    final now = endDate ?? DateTime.now();
    final currentDate = today ?? DateTime.now();

    final startDate = actualIncomes.isNotEmpty
        ? actualIncomes
            .map((e) => e.date)
            .reduce((a, b) => a.isBefore(b) ? a : b)
        : currentDate;

    final daysInPeriod = now.difference(startDate).inDays + 1;
    final daysElapsed =
        (currentDate.difference(startDate).inDays + 1).clamp(0, daysInPeriod);
    final daysLeft =
        (now.difference(currentDate).inDays + 1).clamp(0, daysInPeriod);

    double totalActualIncome = 0;
    for (final inc in actualIncomes) {
      if (inc.date.isBefore(now) || inc.date.isAtSameMomentAs(now)) {
        totalActualIncome += inc.amount;
      }
    }

    double totalExpectedIncome = 0;
    for (final inc in expectedIncomes) {
      if (inc.date.isBefore(now) || inc.date.isAtSameMomentAs(now)) {
        totalExpectedIncome += inc.amount;
      }
    }

    final effectiveIncome =
        totalActualIncome > 0 ? totalActualIncome : totalExpectedIncome;

    final plannedTotal = <String, double>{};
    final plannedUpToToday = <String, double>{};
    final plannedRemaining = <String, double>{};
    double totalPlanned = 0;
    double totalUpToToday = 0;
    double totalRemaining = 0;

    for (final exp in expectedExpenses) {
      double total;
      switch (exp.frequency) {
        case 'daily':
          total = exp.amount * daysInPeriod;
          break;
        case 'weekly':
          total = (exp.amount / 7) * daysInPeriod;
          break;
        case 'monthly':
          total = exp.amount;
          break;
        default:
          throw Exception('Unknown frequency: ${exp.frequency}');
      }
      plannedTotal[exp.name] = total;

      double upToToday;
      switch (exp.frequency) {
        case 'daily':
          upToToday = exp.amount * daysElapsed;
          break;
        case 'weekly':
          upToToday = (exp.amount / 7) * daysElapsed;
          break;
        case 'monthly':
          upToToday = exp.amount;
          break;
        default:
          upToToday = 0;
      }
      plannedUpToToday[exp.name] = upToToday;

      final remaining = total - upToToday;
      plannedRemaining[exp.name] = remaining;

      totalPlanned += total;
      totalUpToToday += upToToday;
      totalRemaining += remaining;
    }

    final originalDailyAllowance =
        (effectiveIncome - totalPlanned) / daysInPeriod;
    final totalSafelySpendBudget = originalDailyAllowance * daysInPeriod;

    final actualSpent = <String, double>{};
    double safelySpendSpent = 0;
    for (final trans in actualExpenses) {
      if (trans.category.toLowerCase() == 'safely spend') {
        safelySpendSpent += trans.amount;
      } else {
        actualSpent[trans.category] =
            (actualSpent[trans.category] ?? 0) + trans.amount;
      }
    }

    final remainingSafelySpend = totalSafelySpendBudget - safelySpendSpent;
    final currentDailyAllowance =
        daysLeft > 0 ? remainingSafelySpend / daysLeft : 0.0;

    final remainingPerCat = <String, double>{};
    for (final exp in expectedExpenses) {
      final spent = actualSpent[exp.name] ?? 0.0;
      remainingPerCat[exp.name] = plannedTotal[exp.name]! - spent;
    }

    return BudgetState(
      expectedIncomes: expectedIncomes,
      actualIncomes: actualIncomes,
      expectedExpenses: expectedExpenses,
      actualExpenses: actualExpenses,
      startDate: startDate,
      endDate: now,
      today: currentDate,
      daysInPeriod: daysInPeriod,
      daysElapsed: daysElapsed,
      daysLeft: daysLeft,
      totalExpectedIncome: totalExpectedIncome,
      totalActualIncome: totalActualIncome,
      plannedTotalPerCategory: plannedTotal,
      totalPlannedExpenses: totalPlanned,
      plannedUpToTodayPerCategory: plannedUpToToday,
      totalPlannedUpToToday: totalUpToToday,
      plannedRemainingPerCategory: plannedRemaining,
      totalPlannedRemaining: totalRemaining,
      originalDailyAllowance: originalDailyAllowance,
      totalSafelySpendBudget: totalSafelySpendBudget,
      safelySpendSpent: safelySpendSpent,
      remainingSafelySpend: remainingSafelySpend,
      currentDailyAllowance: currentDailyAllowance,
      actualSpentPerCategory: actualSpent,
      remainingPerCategory: remainingPerCat,
    );
  }
}
