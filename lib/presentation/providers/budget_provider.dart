import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/budget_repository.dart';
import '../../data/models/budget_plan_model.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository();
});

final jarAllocationsProvider = FutureProvider<List<JarAllocation>>((ref) async {
  final repo = ref.watch(budgetRepositoryProvider);
  final month = _currentMonth();
  return await repo.getJarAllocations(month);
});

String _currentMonth() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}';
}
