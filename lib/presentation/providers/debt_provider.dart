import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/debt_model.dart';
import '../../data/repositories/debt_repository.dart';

final debtRepositoryProvider = Provider<DebtRepository>((ref) {
  return DebtRepository();
});

// Provider for all debts
final allDebtsProvider = FutureProvider<List<DebtModel>>((ref) async {
  final repo = ref.watch(debtRepositoryProvider);
  return await repo.getAllDebts();
});

// Provider for active debts (not paid off)
final activeDebtsProvider = FutureProvider<List<DebtModel>>((ref) async {
  final repo = ref.watch(debtRepositoryProvider);
  return await repo.getActiveDebts();
});

// Provider for total debt balance
final totalDebtBalanceProvider = FutureProvider<double>((ref) async {
  final repo = ref.watch(debtRepositoryProvider);
  return await repo.getTotalDebtBalance();
});

// Provider for debts due soon (within 7 days)
final debtsDueSoonProvider = FutureProvider<List<DebtModel>>((ref) async {
  final repo = ref.watch(debtRepositoryProvider);
  return await repo.getDebtsDueWithinDays(7);
});

// Provider for overdue debts
final overdueDebtsProvider = FutureProvider<List<DebtModel>>((ref) async {
  final repo = ref.watch(debtRepositoryProvider);
  return await repo.getOverdueDebts();
});
