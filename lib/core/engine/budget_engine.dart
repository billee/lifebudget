import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

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
  final DateTime? dueDate;

  ExpenseCategory({
    required this.name,
    required this.amount,
    required this.frequency,
    this.description,
    this.dueDate,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'amount': amount,
        'frequency': frequency,
        'description': description,
        'dueDate': dueDate?.toIso8601String().substring(0, 10),
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
  final Map<String, int> daysLeftPerCategory; // per-category days remaining
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
    required this.daysLeftPerCategory,
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
        daysLeftPerCategory,
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
      'daysLeftPerCategory': daysLeftPerCategory,
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
    DateTime? startDate,
    DateTime? endDate,
    DateTime? today,
  }) {
    final now = endDate ?? DateTime.now();
    final currentDate = today ?? DateTime.now();

    // Use provided startDate, or calculate from earliest income, or use first of month
    final periodStart = startDate ??
        (actualIncomes.isNotEmpty
            ? actualIncomes
                .map((e) => e.date)
                .reduce((a, b) => a.isBefore(b) ? a : b)
            : DateTime(currentDate.year, currentDate.month, 1));

    final daysInPeriod = now.difference(periodStart).inDays + 1;
    final daysElapsed =
        (currentDate.difference(periodStart).inDays + 1).clamp(0, daysInPeriod);

    // Normalize dates to midnight for accurate day calculation
    final currentDateMidnight =
        DateTime(currentDate.year, currentDate.month, currentDate.day);
    final endDateMidnight = DateTime(now.year, now.month, now.day);
    final daysLeftBase =
        (endDateMidnight.difference(currentDateMidnight).inDays + 1)
            .clamp(0, daysInPeriod);

    debugPrint(
        '[BudgetEngine] now (endDate): $now, currentDate (today): $currentDate');
    debugPrint(
        '[BudgetEngine] daysInPeriod: $daysInPeriod, daysElapsed: $daysElapsed, daysLeftBase: $daysLeftBase');

    // Check today's date range
    final todayStart =
        DateTime(currentDate.year, currentDate.month, currentDate.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    // Calculate daysLeft per daily expense category
    final daysLeftPerCategory = <String, int>{};
    for (final exp in expectedExpenses.where((e) => e.frequency == 'daily')) {
      final category = exp.name.toLowerCase();
      final hasSpendingToday = actualExpenses.any((t) {
        final isThisCategory = t.category.toLowerCase() == category;
        final isToday = t.date.isAfter(
                todayStart.subtract(const Duration(milliseconds: 1))) &&
            t.date.isBefore(todayEnd);
        return isThisCategory && isToday;
      });
      daysLeftPerCategory[category] = hasSpendingToday
          ? (daysLeftBase - 1).clamp(0, daysInPeriod)
          : daysLeftBase;
      debugPrint(
          '[BudgetEngine] Category: $category, hasSpendingToday: $hasSpendingToday, daysLeft: ${daysLeftPerCategory[category]}');
    }

    // For backward compatibility, use the first daily category's daysLeft or base
    final daysLeft = daysLeftPerCategory.values.isNotEmpty
        ? daysLeftPerCategory.values.first
        : daysLeftBase;
    debugPrint(
        '[BudgetEngine] daysLeftBase: $daysLeftBase, global daysLeft: $daysLeft');

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
      double upToToday;
      double remaining;

      switch (exp.frequency) {
        case 'daily':
          // Daily: total for period, spent for elapsed days, remaining for future days
          final categoryDaysLeft =
              daysLeftPerCategory[exp.name.toLowerCase()] ?? daysLeftBase;
          total = exp.amount * daysInPeriod;
          upToToday = exp.amount * daysElapsed;
          remaining = exp.amount * categoryDaysLeft;
          break;
        case 'monthly':
          // Monthly: full amount, none spent yet, full amount still needed
          total = exp.amount;
          upToToday = 0;
          remaining = exp.amount;
          break;
        default:
          throw Exception('Unknown frequency: ${exp.frequency}');
      }

      plannedTotal[exp.name] = total;
      plannedUpToToday[exp.name] = upToToday;
      plannedRemaining[exp.name] = remaining;

      totalPlanned += total;
      totalUpToToday += upToToday;
      totalRemaining += remaining;
    }

    // Calculate actual spending first
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

    // Calculate total actual spending (all categories including safely spend)
    final totalActualSpent =
        actualSpent.values.fold(0.0, (a, b) => a + b) + safelySpendSpent;

    // Money actually remaining = income - what's already spent
    final actualMoneyRemaining = effectiveIncome - totalActualSpent;

    // Free money = money remaining - future planned expenses only
    // This gives the discretionary money available for remaining days
    final freeMoney = actualMoneyRemaining - totalRemaining;

    // Current daily allowance = free money / days left
    final currentDailyAllowance = daysLeft > 0 ? freeMoney / daysLeft : 0.0;

    // Total Safely Spend budget = free money available for remaining days
    final totalSafelySpendBudget = freeMoney;

    // Remaining Safely Spend = free money (since we're calculating from actual remaining)
    final remainingSafelySpend = freeMoney;

    // Original daily allowance (for reference - based on full period planning)
    final originalDailyAllowance = daysInPeriod > 0
        ? (effectiveIncome - totalPlanned) / daysInPeriod
        : 0.0;

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
      startDate: periodStart,
      endDate: now,
      today: currentDate,
      daysInPeriod: daysInPeriod,
      daysElapsed: daysElapsed,
      daysLeft: daysLeft,
      daysLeftPerCategory: daysLeftPerCategory,
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
