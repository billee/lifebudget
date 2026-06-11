import 'dart:convert';
import 'budget_engine.dart';

void main() {
  print('=== BUDGET ENGINE – COMPLETE DETAILED CALCULATIONS + JSON ===\n');

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

  final actualExpenses = [
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
  final today = DateTime(2026, 6, 21);

  final state = BudgetEngine.compute(
    actualIncomes: actualIncomes,
    expectedIncomes: expectedIncomes,
    expectedExpenses: expectedExpenses,
    actualExpenses: actualExpenses,
    endDate: endDate,
    today: today,
  );

  String fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ---------- 1. PERIOD ----------
  print('1. PERIOD & DAYS');
  print('   Start date (earliest actual income): ${fmtDate(state.startDate)}');
  print('   End date: ${fmtDate(state.endDate)}');
  print('   Today: ${fmtDate(state.today)}');
  print('   Days in period = (end - start + 1) = ${state.daysInPeriod}');
  print('   Days elapsed = (today - start + 1) = ${state.daysElapsed}');
  print('   Days left = (end - today + 1) = ${state.daysLeft}\n');

  // ---------- 2. INCOME ----------
  print('2. INCOME');
  print('   Actual incomes:');
  double actualSum = 0;
  for (var inc in actualIncomes) {
    actualSum += inc.amount;
    print('     ${inc.amount} on ${fmtDate(inc.date)}');
  }
  print('   Total actual income = $actualSum');
  print('   Expected incomes (up to end):');
  double expectedSum = 0;
  for (var inc in expectedIncomes) {
    expectedSum += inc.amount;
    print('     ${inc.amount} on ${fmtDate(inc.date)}');
  }
  print('   Total expected income = $expectedSum');
  print('   Effective income = actual income (since >0) = $actualSum\n');

  // ---------- 3. TOTAL PLANNED (FULL PERIOD) ----------
  print('3. PLANNED EXPENSES – TOTAL FOR PERIOD');
  double totalPlanned = 0;
  for (var exp in expectedExpenses) {
    double total = state.plannedTotalPerCategory[exp.name]!;
    totalPlanned += total;
    print(
        '   ${exp.name} (${exp.frequency}): $total = ${exp.amount} × ${state.daysInPeriod} days (${exp.frequency == 'monthly' ? 'full monthly' : ''})');
  }
  print('   Total planned expenses = $totalPlanned\n');

  // ---------- 4. PLANNED UP TO TODAY (PRORATED) ----------
  print('4. PLANNED EXPENSES – UP TO TODAY (prorated)');
  double totalUpToToday = 0;
  for (var exp in expectedExpenses) {
    double upToToday = state.plannedUpToTodayPerCategory[exp.name]!;
    totalUpToToday += upToToday;
    print(
        '   ${exp.name}: $upToToday = ${exp.amount} × ${state.daysElapsed} days (${exp.frequency == 'monthly' ? 'full monthly' : ''})');
  }
  print('   Total planned up to today = $totalUpToToday\n');

  // ---------- 5. PLANNED REMAINING (AFTER TODAY) – from engine ----------
  print('5. PLANNED EXPENSES – REMAINING (after today)');
  double totalRemaining = 0;
  for (var exp in expectedExpenses) {
    double remaining = state.plannedRemainingPerCategory[exp.name]!;
    totalRemaining += remaining;
    double total = state.plannedTotalPerCategory[exp.name]!;
    double upToToday = state.plannedUpToTodayPerCategory[exp.name]!;
    print(
        '   ${exp.name}: remaining $remaining = $total (total) - $upToToday (up to today)');
  }
  print('   Total planned remaining = $totalRemaining\n');

  // ---------- 6. DAILY ALLOWANCE & SAFELY SPEND BUDGET ----------
  print('6. DAILY ALLOWANCE (ORIGINAL)');
  double dailyAllowance = state.originalDailyAllowance;
  print('   = ($actualSum - $totalPlanned) / ${state.daysInPeriod}');
  print(
      '   = ${actualSum - totalPlanned} / ${state.daysInPeriod} = ${dailyAllowance.toStringAsFixed(2)} per day');
  double safelySpendBudget = state.totalSafelySpendBudget;
  print(
      '   Total safely spend budget = $dailyAllowance × ${state.daysInPeriod} = ${safelySpendBudget.toStringAsFixed(2)}\n');

  // ---------- 7. ACTUAL SPENDING ----------
  print('7. ACTUAL SPENDING (so far)');
  for (var entry in state.actualSpentPerCategory.entries) {
    print('   ${entry.key}: ${entry.value}');
  }
  print('   Safely spend spent: ${state.safelySpendSpent}\n');

  // ---------- 8. COMPARISON: PLANNED UP TO TODAY VS ACTUAL ----------
  print('8. COMPARISON: PLANNED UP TO TODAY VS ACTUAL');
  for (var exp in expectedExpenses) {
    double plannedUp = state.plannedUpToTodayPerCategory[exp.name]!;
    double actual = state.actualSpentPerCategory[exp.name] ?? 0.0;
    double diff = actual - plannedUp;
    print(
        '   ${exp.name}: planned $plannedUp, actual $actual → ${diff >= 0 ? 'over' : 'under'} by ${diff.abs().toStringAsFixed(2)}');
  }
  print(
      '   Safely spend: budget ${state.totalSafelySpendBudget.toStringAsFixed(2)}, spent ${state.safelySpendSpent} → remaining ${state.remainingSafelySpend.toStringAsFixed(2)}\n');

  // ---------- 9. CURRENT DAILY ALLOWANCE (REALISTIC) ----------
  print('9. CURRENT DAILY ALLOWANCE (REALISTIC)');
  double remainingSafely = state.remainingSafelySpend;
  double currentDaily = state.currentDailyAllowance;
  print(
      '   Remaining safely spend = ${state.totalSafelySpendBudget.toStringAsFixed(2)} - ${state.safelySpendSpent} = ${remainingSafely.toStringAsFixed(2)}');
  print('   Days left = ${state.daysLeft}');
  print(
      '   Current daily allowance = $remainingSafely / ${state.daysLeft} = ${currentDaily.toStringAsFixed(2)} per day\n');

  // ---------- 10. REMAINING PER CATEGORY (FULL PERIOD) – from engine ----------
  print('10. REMAINING PER CATEGORY (full period planned - actual)');
  for (var exp in expectedExpenses) {
    double remaining = state.remainingPerCategory[exp.name]!;
    double total = state.plannedTotalPerCategory[exp.name]!;
    double actual = state.actualSpentPerCategory[exp.name] ?? 0.0;
    print('   ${exp.name}: $total - $actual = ${remaining.toStringAsFixed(2)}');
  }

  // ---------- 11. JSON OUTPUT ----------
  print('\n=== JSON OUTPUT ===');
  final json = state.toJson();
  const encoder = JsonEncoder.withIndent('  ');
  print(encoder.convert(json));
}
