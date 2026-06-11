import 'dart:io';
import 'budget_engine.dart';

void main() {
  print(
      '=== BUDGET ENGINE – DETAILED CALCULATIONS (Dynamic Daily Allowance) ===\n');

  // ---------- INPUT DATA ----------
  final actualIncomes = [
    IncomeEntry(
        amount: 2000, date: DateTime(2026, 6, 10), description: 'Salary'),
    IncomeEntry(
        amount: 500, date: DateTime(2026, 6, 15), description: 'Freelance'),
  ];

  final expectedIncomes = [
    IncomeEntry(
        amount: 2000, date: DateTime(2026, 6, 30), description: 'Future Bonus'),
  ];

  final expectedExpenses = [
    ExpenseCategory(name: 'Rent', amount: 600, frequency: 'monthly'),
    ExpenseCategory(name: 'Food', amount: 30, frequency: 'daily'),
    ExpenseCategory(name: 'Transport', amount: 15, frequency: 'daily'),
    ExpenseCategory(name: 'Insurance', amount: 200, frequency: 'monthly'),
    ExpenseCategory(name: 'Savings', amount: 200, frequency: 'monthly'),
  ];

  // Real transactions: Food expense on 12th, Safely Spend expense of 50 on 20th
  final actualExpenses = <ExpenseTransaction>[
    ExpenseTransaction(
        category: 'Food',
        amount: 30,
        date: DateTime(2026, 6, 12),
        note: 'Groceries'),
    ExpenseTransaction(
        category: 'Safely Spend',
        amount: 50,
        date: DateTime(2026, 6, 20),
        note: 'Takeout'),
  ];

  final endDate = DateTime(2026, 6, 30);
  final today = DateTime(2026, 6, 21); // simulate "today" after the withdrawal

  final state = BudgetEngine.compute(
    actualIncomes: actualIncomes,
    expectedIncomes: expectedIncomes,
    expectedExpenses: expectedExpenses,
    actualExpenses: actualExpenses,
    endDate: endDate,
    today: today,
  );

  // ---------- DETAILED OUTPUT ----------
  print('1. PERIOD & DAYS');
  print('   First actual income: ${state.startDate.toIso8601String()}');
  print('   End of period: ${state.endDate.toIso8601String()}');
  print('   Total days in period: ${state.daysInPeriod}');
  print('   Today (simulated): ${state.today.toIso8601String()}');
  print('   Days left in period: ${state.daysLeftInPeriod}\n');

  print('2. INCOME SUMMARY');
  print('   Actual incomes:');
  for (final inc in state.actualIncomes) {
    print('     - ${inc.amount} on ${inc.date.toIso8601String()}');
  }
  print('   Total actual income: ${state.totalActualIncome}');
  print('   Expected incomes (up to end date):');
  for (final inc in state.expectedIncomes) {
    print('     - ${inc.amount} on ${inc.date.toIso8601String()}');
  }
  print('   Total expected income: ${state.totalExpectedIncome}');
  print('   Effective income: ${state.totalActualIncome}\n');

  print('3. PLANNED EXPENSES (total for the period)');
  double sumPlanned = 0;
  for (final exp in state.expectedExpenses) {
    double total = state.plannedTotalPerCategory[exp.name]!;
    sumPlanned += total;
    String detail;
    switch (exp.frequency) {
      case 'daily':
        detail = '${exp.amount} × ${state.daysInPeriod} days';
        break;
      case 'weekly':
        detail = '(${exp.amount} / 7) × ${state.daysInPeriod} days';
        break;
      case 'monthly':
        detail = 'full monthly amount (no prorating)';
        break;
      default:
        detail = '';
    }
    print('   ${exp.name} (${exp.frequency}): $total   ($detail)');
  }
  print('   Total planned expenses: $sumPlanned\n');

  print('4. DAILY ALLOWANCE (Original & Current)');
  print(
      '   Original daily allowance = (Effective income - Total planned) / Days');
  print(
      '   = (${state.totalActualIncome} - $sumPlanned) / ${state.daysInPeriod}');
  print('   = ${state.totalActualIncome - sumPlanned} / ${state.daysInPeriod}');
  print('   = ${state.originalDailyAllowance.toStringAsFixed(2)} per day');
  print('   Total safely spend budget = Original daily allowance × Days');
  print(
      '   = ${state.originalDailyAllowance.toStringAsFixed(2)} × ${state.daysInPeriod}');
  print('   = ${state.totalSafelySpendBudget.toStringAsFixed(2)}\n');

  print('5. ACTUAL SPENDING');
  print('   Regular expenses:');
  for (final entry in state.actualSpentPerCategory.entries) {
    print('     ${entry.key}: ${entry.value}');
  }
  print('   Safely spend spent: ${state.safelySpendSpent}');
  double totalSpent =
      state.actualSpentPerCategory.values.fold(0.0, (a, b) => a + b) +
          state.safelySpendSpent;
  print('   Total actual spending: $totalSpent\n');

  print('6. REMAINING SAFELY SPEND & CURRENT DAILY ALLOWANCE');
  print('   Remaining safely spend = Total budget - Spent');
  print(
      '   = ${state.totalSafelySpendBudget.toStringAsFixed(2)} - ${state.safelySpendSpent}');
  print('   = ${state.remainingSafelySpend.toStringAsFixed(2)}');
  print('   Current daily allowance = Remaining safely spend / Days left');
  print(
      '   = ${state.remainingSafelySpend.toStringAsFixed(2)} / ${state.daysLeftInPeriod}');
  print(
      '   = ${state.currentDailyAllowance.toStringAsFixed(2)} per day (from now until ${state.endDate.toIso8601String()})\n');

  print('7. REMAINING PER CATEGORY');
  for (final entry in state.remainingPerCategory.entries) {
    final planned = state.plannedTotalPerCategory[entry.key]!;
    print(
        '   ${entry.key}: remaining ${entry.value.toStringAsFixed(2)} (planned $planned, spent ${state.actualSpentPerCategory[entry.key] ?? 0})');
  }

  print('\n8. FINAL STATE');
  print(
      '   Original daily allowance (planning): ${state.originalDailyAllowance.toStringAsFixed(2)}');
  print(
      '   Current daily allowance (realistic): ${state.currentDailyAllowance.toStringAsFixed(2)}');
  print(
      '   Safely spend left: ${state.remainingSafelySpend.toStringAsFixed(2)}');
  print('\n=== END ===');
}
