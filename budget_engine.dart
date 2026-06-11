import 'package:equatable/equatable.dart';

class IncomeEntry {
  final double amount;
  final DateTime date;
  final String? description;
  IncomeEntry({required this.amount, required this.date, this.description});
}

class ExpenseCategory {
  final String name;
  final double amount;
  final String frequency; // 'daily', 'weekly', 'monthly'
  final String? description;
  ExpenseCategory(
      {required this.name,
      required this.amount,
      required this.frequency,
      this.description});
}

class ExpenseTransaction {
  final String category;
  final double amount;
  final DateTime date;
  final String? note;
  ExpenseTransaction(
      {required this.category,
      required this.amount,
      required this.date,
      this.note});
}

class BudgetState extends Equatable {
  final List<IncomeEntry> expectedIncomes;
  final List<IncomeEntry> actualIncomes;
  final List<ExpenseCategory> expectedExpenses;
  final List<ExpenseTransaction> actualExpenses;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime today; // current date for remaining days calculation
  final int daysInPeriod;
  final int daysLeftInPeriod;
  final double totalExpectedIncome;
  final double totalActualIncome;
  final Map<String, double> plannedTotalPerCategory;
  final double totalPlannedExpenses;
  final double originalDailyAllowance; // planned rate for whole period
  final double totalSafelySpendBudget;
  final double safelySpendSpent;
  final double remainingSafelySpend;
  final double currentDailyAllowance; // remaining budget / days left
  final Map<String, double> actualSpentPerCategory;
  final Map<String, double> remainingPerCategory;

  const BudgetState({
    required this.expectedIncomes,
    required this.actualIncomes,
    required this.expectedExpenses,
    required this.actualExpenses,
    required this.startDate,
    required this.endDate,
    required this.today,
    required this.daysInPeriod,
    required this.daysLeftInPeriod,
    required this.totalExpectedIncome,
    required this.totalActualIncome,
    required this.plannedTotalPerCategory,
    required this.totalPlannedExpenses,
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
        daysLeftInPeriod,
        totalExpectedIncome,
        totalActualIncome,
        plannedTotalPerCategory,
        totalPlannedExpenses,
        originalDailyAllowance,
        totalSafelySpendBudget,
        safelySpendSpent,
        remainingSafelySpend,
        currentDailyAllowance,
        actualSpentPerCategory,
        remainingPerCategory,
      ];
}

class BudgetEngine {
  static BudgetState compute({
    required List<IncomeEntry> actualIncomes,
    required List<IncomeEntry> expectedIncomes,
    required List<ExpenseCategory> expectedExpenses,
    List<ExpenseTransaction> actualExpenses = const [],
    DateTime? endDate,
    DateTime? today, // pass current date; defaults to now
  }) {
    final now = endDate ?? DateTime.now();
    final currentDate = today ?? DateTime.now();

    // Start date is earliest actual income, or today if none
    final startDate = actualIncomes.isNotEmpty
        ? actualIncomes
            .map((e) => e.date)
            .reduce((a, b) => a.isBefore(b) ? a : b)
        : currentDate;
    final daysInPeriod = now.difference(startDate).inDays + 1;
    final daysLeftInPeriod =
        (now.difference(currentDate).inDays + 1).clamp(0, daysInPeriod);

    double totalActualIncome = 0;
    for (final inc in actualIncomes) {
      if (inc.date.isBefore(now) || inc.date.isAtSameMomentAs(now))
        totalActualIncome += inc.amount;
    }

    double totalExpectedIncome = 0;
    for (final inc in expectedIncomes) {
      if (inc.date.isBefore(now) || inc.date.isAtSameMomentAs(now))
        totalExpectedIncome += inc.amount;
    }

    final effectiveIncome =
        totalActualIncome > 0 ? totalActualIncome : totalExpectedIncome;

    // Planned expenses (excluding Safely Spend)
    final plannedTotal = <String, double>{};
    double totalPlanned = 0;
    for (final exp in expectedExpenses) {
      double categoryTotal;
      switch (exp.frequency) {
        case 'daily':
          categoryTotal = exp.amount * daysInPeriod;
          break;
        case 'weekly':
          categoryTotal = (exp.amount / 7) * daysInPeriod;
          break;
        case 'monthly':
          categoryTotal = exp.amount;
          break;
        default:
          throw Exception('Unknown frequency: ${exp.frequency}');
      }
      plannedTotal[exp.name] = categoryTotal;
      totalPlanned += categoryTotal;
    }

    final originalDailyAllowance =
        (effectiveIncome - totalPlanned) / daysInPeriod;
    final totalSafelySpendBudget = originalDailyAllowance * daysInPeriod;

    // Aggregate actual expenses, separating Safely Spend
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
        daysLeftInPeriod > 0 ? remainingSafelySpend / daysLeftInPeriod : 0.0;

    // Remaining per planned category
    final remaining = <String, double>{};
    for (final exp in expectedExpenses) {
      final spent = actualSpent[exp.name] ?? 0.0;
      remaining[exp.name] = plannedTotal[exp.name]! - spent;
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
      daysLeftInPeriod: daysLeftInPeriod,
      totalExpectedIncome: totalExpectedIncome,
      totalActualIncome: totalActualIncome,
      plannedTotalPerCategory: plannedTotal,
      totalPlannedExpenses: totalPlanned,
      originalDailyAllowance: originalDailyAllowance,
      totalSafelySpendBudget: totalSafelySpendBudget,
      safelySpendSpent: safelySpendSpent,
      remainingSafelySpend: remainingSafelySpend,
      currentDailyAllowance: currentDailyAllowance,
      actualSpentPerCategory: actualSpent,
      remainingPerCategory: remaining,
    );
  }
}
