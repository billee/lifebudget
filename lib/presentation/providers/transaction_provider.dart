import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/transaction_repository.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});

// Provider that fetches all transactions (you can add filters later)
final transactionsProvider =
    FutureProvider<List<TransactionModel>>((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  // For now we don't need all transactions in one place; we'll use jar-specific provider
  // This can be used for a global transaction history screen later
  return [];
});

// Provider for jar summaries (real-time)
final jarSummariesProvider = FutureProvider<Map<String, double>>((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  return await repo.getJarSummaries();
});

final allTransactionsProvider =
    FutureProvider<List<TransactionModel>>((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  return await repo.getAllTransactions();
});

final freshStartProvider = FutureProvider.autoDispose<void>((ref) async {
  // This provider will be used to trigger the action and then invalidate others
});
