import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/insights/insight_model.dart';
import '../../core/insights/rules_engine.dart';
import 'transaction_provider.dart';
import 'budget_provider.dart';
import 'expected_expenses_provider.dart';
import 'goal_provider.dart';
import 'slip_up_provider.dart';
import 'journal_provider.dart';

String _currentMonth() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}';
}

String _lastMonth() {
  final now = DateTime.now();
  final last = DateTime(now.year, now.month - 1, 1);
  return '${last.year}-${last.month.toString().padLeft(2, '0')}';
}

final insightsProvider = FutureProvider<List<Insight>>((ref) async {
  // Watch all data providers
  final transactions = await ref.watch(allTransactionsProvider.future);
  final allocations = await ref.watch(jarAllocationsProvider.future);
  final expectedExpenses = await ref.watch(expectedExpensesProvider.future);
  final goals = await ref.watch(goalsProvider.future);
  final journalEntries = await ref.watch(journalEntriesProvider.future);

  // Slip-ups for current month
  final slipUpRepo = ref.watch(slipUpRepositoryProvider);
  final slipUps = await slipUpRepo.getForMonth(_currentMonth());

  // Last month archived data (best-effort, empty if unavailable)
  Map<String, double> lastMonthJarSpent = {};
  try {
    final txRepo = ref.watch(transactionRepositoryProvider);
    lastMonthJarSpent = await txRepo.getArchivedJarSummaries(_lastMonth());
  } catch (_) {}

  // Build engine and generate
  final engine = RulesEngine(lastMonthJarSpent: lastMonthJarSpent);
  return engine.generate(
    transactions: transactions,
    allocations: allocations,
    expectedExpenses: expectedExpenses,
    goals: goals,
    slipUps: slipUps,
    journalEntries: journalEntries,
  );
});
