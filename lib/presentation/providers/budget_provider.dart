import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/budget_repository.dart';
import '../../data/models/budget_plan_model.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository();
});

final budgetProvider = FutureProvider<BudgetPlan>((ref) async {
  final repo = ref.watch(budgetRepositoryProvider);
  final month = _currentMonth(); // e.g., '2026-06'
  return await repo.getOrCreateBudget(month);
});

String _currentMonth() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}';
}
