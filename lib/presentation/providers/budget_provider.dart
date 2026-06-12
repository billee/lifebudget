import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/expected_expense_model.dart';
import '../../core/engine/budget_engine.dart';
import 'transaction_provider.dart';
import 'expected_expenses_provider.dart';

final budgetStateProvider = FutureProvider<BudgetState>((ref) async {
  final transactions = await ref.watch(allTransactionsProvider.future);
  final expectedExpenses = await ref.watch(expectedExpensesProvider.future);

  // Convert income transactions
  final actualIncomes = transactions
      .where((t) => t.type == 'income')
      .map((t) => IncomeEntry(amount: t.amount, date: t.date))
      .toList();

  // Expected incomes – can be extended later
  final expectedIncomes = <IncomeEntry>[];

  // Convert expected expenses (normalize names to lowercase for matching)
  final expectedExpensesList = expectedExpenses
      .where((e) =>
          e.title.toLowerCase() != 'safely spend') // exclude safely spend
      .map((e) => ExpenseCategory(
            name: e.title.toLowerCase(),
            amount: e.amount,
            frequency: e.frequency,
          ))
      .toList();

  // Convert actual expenses (normalize category names)
  final actualExpensesList = transactions
      .where((t) => t.type == 'expense' || t.type == 'savings')
      .map((t) => ExpenseTransaction(
            category: t.jar.toLowerCase(),
            amount: t.amount,
            date: t.date,
            note: t.note,
          ))
      .toList();

  final now = DateTime.now();
  final endOfMonth = DateTime(now.year, now.month + 1, 0);

  return BudgetEngine.compute(
    actualIncomes: actualIncomes,
    expectedIncomes: expectedIncomes,
    expectedExpenses: expectedExpensesList,
    actualExpenses: actualExpensesList,
    endDate: endOfMonth,
    today: now,
  );
});
