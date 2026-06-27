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

  final now = MonthTransitionService.debugOverrideDate ?? DateTime.now();
  final endOfMonth = DateTime(now.year, now.month + 1, 0);
  final startOfMonth = DateTime(now.year, now.month, 1);

  final isDebugMode = MonthTransitionService.debugOverrideDate != null;

  final currentMonthTransactions = transactions.where((t) {
    final date = t.date;
    return date.year == now.year && date.month == now.month;
  }).toList();

  debugPrint('[BudgetProvider] Now: $now, isDebugMode: $isDebugMode');
  debugPrint(
      '[BudgetProvider] Total transactions: ${transactions.length}, Filtered: ${currentMonthTransactions.length}');
  debugPrint(
      '[BudgetProvider] Current month transactions: ${currentMonthTransactions.map((t) => '${t.type}:${t.amount}:${t.date}').join(', ')}');

  final actualIncomes = currentMonthTransactions
      .where((t) => t.type == 'income')
      .map((t) => IncomeEntry(amount: t.amount, date: t.date))
      .toList();

  final expectedIncomes = <IncomeEntry>[];

  final currentMonthStr = '${now.year}-${now.month.toString().padLeft(2, '0')}';

  final actualSpentPerCat = <String, double>{};
  for (final t in currentMonthTransactions) {
    if (t.type == 'expense' || t.type == 'savings') {
      final cat = t.jar.toLowerCase();
      actualSpentPerCat[cat] = (actualSpentPerCat[cat] ?? 0) + t.amount;
    }
  }

  final expectedExpensesList = expectedExpenses
      .where((e) =>
          e.title.toLowerCase() != 'safely spend' && e.month == currentMonthStr)
      .map((e) {
    final name = e.title.toLowerCase();
    final freq = e.frequency;
    var amount = e.amount;

    if (freq == 'monthly') {
      final spent = actualSpentPerCat[name] ?? 0;
      amount = (amount - spent).clamp(0.0, double.infinity);
    }

    return ExpenseCategory(
      name: name,
      amount: amount,
      frequency: freq,
      dueDate: e.dueDate, // <--- NEW: pass dueDate
    );
  }).toList();

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
    startDate: startOfMonth,
    endDate: endOfMonth,
    today: now,
  );

  final safelySpendAmount = budgetState.totalSafelySpendBudget;
  debugPrint('[BudgetProvider] Safely Spend amount: $safelySpendAmount');

  if (safelySpendAmount > 0) {
    final monthStr = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    debugPrint('[BudgetProvider] Syncing Safely Spend for month: $monthStr');
    final repo = ref.read(expectedExpenseRepositoryProvider);

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
    } else {
      debugPrint('[BudgetProvider] Safely Spend unchanged (delta <= 1.0)');
    }
  } else {
    debugPrint('[BudgetProvider] Safely Spend is 0 or negative, skipping sync');
  }

  return budgetState;
});
