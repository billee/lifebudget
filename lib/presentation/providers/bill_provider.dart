import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/bill_model.dart';
import '../../data/repositories/bill_repository.dart';

final billRepositoryProvider = Provider<BillRepository>((ref) {
  return BillRepository();
});

// Provider for all bills
final allBillsProvider = FutureProvider<List<BillModel>>((ref) async {
  final repo = ref.watch(billRepositoryProvider);
  return await repo.getAllBills();
});

// Provider for unpaid bills
final unpaidBillsProvider = FutureProvider<List<BillModel>>((ref) async {
  final repo = ref.watch(billRepositoryProvider);
  return await repo.getUnpaidBills();
});

// Provider for bills due soon (within 7 days)
final billsDueSoonProvider = FutureProvider<List<BillModel>>((ref) async {
  final repo = ref.watch(billRepositoryProvider);
  return await repo.getBillsDueWithinDays(7);
});

// Provider for overdue bills
final overdueBillsProvider = FutureProvider<List<BillModel>>((ref) async {
  final repo = ref.watch(billRepositoryProvider);
  return await repo.getOverdueBills();
});
