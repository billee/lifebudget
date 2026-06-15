import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/expected_expense_model.dart';
import '../../core/engine/budget_engine.dart';
import 'transaction_provider.dart';
import 'expected_expenses_provider.dart';
import '../../services/month_transition_service.dart';

final budgetStateProvider = FutureProvider<BudgetState>((ref) async {
  final transactions = await ref.watch(allTransactionsProvider.future);
  final expectedExpenses = await ref.watch(expectedExpensesProvider.future);

  // DEBUG: Use override date if set (for testing month transitions)
  final now = MonthTransitionService.debugOverrideDate ?? DateTime.now();
  final endOfMonth = DateTime(now.year, now.month + 1, 0);
  final startOfMonth = DateTime(now.year, now.month, 1);

  // For debug mode, we want to use the simulated month's data
  // In production, filter by year AND month
  // In debug mode, we need to handle the case where real data is in a different year
  final isDebugMode = MonthTransitionService.debugOverrideDate != null;

  // Filter transactions by current month using full date comparison
  // This ensures consistency whether in debug mode or production
  final currentMonthTransactions = transactions.where((t) {
    final date = t.date;
    // Match by year AND month for consistency
    return date.year == now.year && date.month == now.month;
  }).toList();

  debugPrint('[BudgetProvider] Now: $now, isDebugMode: $isDebugMode');
  debugPrint(
      '[BudgetProvider] Total transactions: ${transactions.length}, Filtered: ${currentMonthTransactions.length}');
  debugPrint(
      '[BudgetProvider] Current month transactions: ${currentMonthTransactions.map((t) => '${t.type}:${t.amount}:${t.date}').join(', ')}');

  // Convert income transactions (only current month)
  final actualIncomes = currentMonthTransactions
      .where((t) => t.type == 'income')
      .map((t) => IncomeEntry(amount: t.amount, date: t.date))
      .toList();

  // Expected incomes – can be extended later
  final expectedIncomes = <IncomeEntry>[];

  // Convert expected expenses for current month only (normalize names to lowercase for matching)
  // Use full date format consistently (YYYY-MM)
  final currentMonthStr = '${now.year}-${now.month.toString().padLeft(2, '0')}';

  // Calculate actual spent per category first (needed for monthly expense adjustment)
  final actualSpentPerCat = <String, double>{};
  for (final t in currentMonthTransactions) {
    if (t.type == 'expense' || t.type == 'savings') {
      final cat = t.jar.toLowerCase();
      actualSpentPerCat[cat] = (actualSpentPerCat[cat] ?? 0) + t.amount;
    }
  }

  final expectedExpensesList = expectedExpenses
      .where((e) =>
          e.title.toLowerCase() != 'safely spend' && // exclude safely spend
          e.month == currentMonthStr) // match current month only
      .map((e) {
    final name = e.title.toLowerCase();
    final freq = e.frequency;
    var amount = e.amount;

    // For monthly expenses: adjust for amount already spent
    // If fully paid, remaining is 0. If partially paid, use remaining amount.
    if (freq == 'monthly') {
      final spent = actualSpentPerCat[name] ?? 0;
      amount = (amount - spent).clamp(0.0, double.infinity);
    }

    return ExpenseCategory(
      name: name,
      amount: amount,
      frequency: freq,
    );
  }).toList();

  // Convert actual expenses (only current month, normalize category names)
  final actualExpensesList = currentMonthTransactions
      .where((t) => t.type == 'expense' || t.type == 'savings')
      .map((t) => ExpenseTransaction(
            category: t.jar.toLowerCase(),
            amount: t.amount,
            date: t.date,
            note: t.note,
          ))
      .toList();

  final budgetState = BudgetEngine.compute(
    actualIncomes: actualIncomes,
    expectedIncomes: expectedIncomes,
    expectedExpenses: expectedExpensesList,
    actualExpenses: actualExpensesList,
    endDate: endOfMonth,
    today: now,
  );

  // Sync Safely Spend to database (idempotent, delta-based)
  final safelySpendAmount = budgetState.totalSafelySpendBudget;
  debugPrint('[BudgetProvider] Safely Spend amount: $safelySpendAmount');

  if (safelySpendAmount > 0) {
    final monthStr = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    debugPrint('[BudgetProvider] Syncing Safely Spend for month: $monthStr');
    final repo = ref.read(expectedExpenseRepositoryProvider);

    // Check if update is needed (delta > 1 to avoid redundant writes)
    final existingSafelySpend = expectedExpenses
        .where((e) =>
            e.title.toLowerCase() == 'safely spend' && e.month == monthStr)
        .firstOrNull;

    debugPrint(
        '[BudgetProvider] Existing Safely Spend: ${existingSafelySpend?.amount ?? "null"}');

    if (existingSafelySpend == null ||
        (existingSafelySpend.amount - safelySpendAmount).abs() > 1.0) {
      debugPrint(
          '[BudgetProvider] Writing Safely Spend to database: $safelySpendAmount');
      await repo.upsertSafelySpend(safelySpendAmount, monthStr);
      debugPrint('[BudgetProvider] Safely Spend written successfully');
      // Don't invalidate here - it causes infinite loop
      // The UI will refresh naturally when needed
    } else {
      debugPrint('[BudgetProvider] Safely Spend unchanged (delta <= 1.0)');
    }
  } else {
    debugPrint('[BudgetProvider] Safely Spend is 0 or negative, skipping sync');
  }

  return budgetState;
});
