import 'dart:io';
import 'budget_engine.dart';

void main() {
  print('=== BUDGET ENGINE – DETAILED CALCULATIONS (Full Report) ===\n');

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
  final today = DateTime(2026, 6, 21); // simulate "today" after withdrawal

  // ---------- COMPUTE ----------
  final state = BudgetEngine.compute(
    actualIncomes: actualIncomes,
    expectedIncomes: expectedIncomes,
    expectedExpenses: expectedExpenses,
    actualExpenses: actualExpenses,
    endDate: endDate,
    today: today,
  );

  // Helper to format date without time
  String fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ---------- DETAILED OUTPUT ----------
  print('1. PERIOD & DATES');
  print('   Start date (earliest actual income): ${fmtDate(state.startDate)}');
  print('   End of period: ${fmtDate(state.endDate)}');
  print('   Today (simulated): ${fmtDate(state.today)}');
  print(
      '   Days in period: ${state.daysInPeriod} (from ${fmtDate(state.startDate)} to ${fmtDate(state.endDate)})');
  print('   Days elapsed (start → today): ${state.daysElapsed}');
  print('   Days left (after today): ${state.daysLeft}\n');

  print('2. INCOME DETAILS');
  print('   Actual incomes:');
  for (final inc in state.actualIncomes) {
    print(
        '     - ${inc.amount} on ${fmtDate(inc.date)} (${inc.description ?? 'income'})');
  }
  print('   Total actual income = ${state.totalActualIncome}');
  print('   Expected incomes (up to end date):');
  for (final inc in state.expectedIncomes) {
    print(
        '     - ${inc.amount} on ${fmtDate(inc.date)} (${inc.description ?? 'income'})');
  }
  print('   Total expected income = ${state.totalExpectedIncome}');
  print(
      '   Effective income (actual used because >0) = ${state.totalActualIncome}\n');

  print('3. PLANNED EXPENSES – TOTAL FOR THE PERIOD');
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
  print('   Total planned expenses (full period) = $sumPlanned\n');

  print('4. PLANNED EXPENSES – UP TO TODAY (prorated)');
  double sumUpToToday = 0;
  for (final exp in state.expectedExpenses) {
    double upToToday = state.plannedUpToTodayPerCategory[exp.name]!;
    sumUpToToday += upToToday;
    String detail;
    switch (exp.frequency) {
      case 'daily':
        detail = '${exp.amount} × ${state.daysElapsed} days';
        break;
      case 'weekly':
        detail = '(${exp.amount} / 7) × ${state.daysElapsed} days';
        break;
      case 'monthly':
        detail = 'full monthly amount (assumed due)';
        break;
      default:
        detail = '';
    }
    print('   ${exp.name}: $upToToday   ($detail)');
  }
  print('   Total planned up to today = $sumUpToToday\n');

  print('5. PLANNED EXPENSES – REMAINING (after today)');
  double sumRemaining = 0;
  for (final exp in state.expectedExpenses) {
    double remaining = state.plannedRemainingPerCategory[exp.name]!;
    sumRemaining += remaining;
    print('   ${exp.name}: $remaining');
  }
  print('   Total planned remaining = $sumRemaining\n');

  print('6. DAILY ALLOWANCE & SAFELY SPEND BUDGET (PLANNING)');
  print(
      '   Original daily allowance = (Effective income - Total planned) / Days');
  print(
      '   = (${state.totalActualIncome} - $sumPlanned) / ${state.daysInPeriod}');
  print('   = ${state.totalActualIncome - sumPlanned} / ${state.daysInPeriod}');
  print('   = ${state.originalDailyAllowance.toStringAsFixed(2)} per day');
  print(
      '   Total safely spend budget (original) = Original daily allowance × Days');
  print(
      '   = ${state.originalDailyAllowance.toStringAsFixed(2)} × ${state.daysInPeriod}');
  print('   = ${state.totalSafelySpendBudget.toStringAsFixed(2)}\n');

  print('7. ACTUAL SPENDING (SO FAR)');
  print('   Regular expenses:');
  for (final entry in state.actualSpentPerCategory.entries) {
    print('     ${entry.key}: ${entry.value}');
  }
  print('   Safely spend spent: ${state.safelySpendSpent}');
  double totalSpent =
      state.actualSpentPerCategory.values.fold(0.0, (a, b) => a + b) +
          state.safelySpendSpent;
  print('   Total actual spending: $totalSpent\n');

  print('8. COMPARISON: PLANNED UP TO TODAY VS ACTUAL');
  for (final exp in state.expectedExpenses) {
    final planned = state.plannedUpToTodayPerCategory[exp.name]!;
    final actual = state.actualSpentPerCategory[exp.name] ?? 0.0;
    final diff = actual - planned;
    print(
        '   ${exp.name}: planned $planned, actual $actual → ${diff >= 0 ? 'over' : 'under'} by ${diff.abs().toStringAsFixed(2)}');
  }
  print(
      '   Safely spend: budget for period ${state.totalSafelySpendBudget.toStringAsFixed(2)}, spent ${state.safelySpendSpent} → remaining ${state.remainingSafelySpend.toStringAsFixed(2)}\n');

  print('9. CURRENT DAILY ALLOWANCE (REALISTIC)');
  print(
      '   Remaining safely spend = ${state.remainingSafelySpend.toStringAsFixed(2)}');
  print('   Days left = ${state.daysLeft}');
  print('   Current daily allowance = Remaining / Days left');
  print(
      '   = ${state.remainingSafelySpend.toStringAsFixed(2)} / ${state.daysLeft}');
  print(
      '   = ${state.currentDailyAllowance.toStringAsFixed(2)} per day (from ${fmtDate(state.today)} to ${fmtDate(state.endDate)})\n');

  print('10. REMAINING PER CATEGORY (FULL PERIOD PLANNED - ACTUAL)');
  for (final entry in state.remainingPerCategory.entries) {
    print('   ${entry.key}: ${entry.value.toStringAsFixed(2)}');
  }

  print('\n=== END OF DETAILED REPORT ===');
}
