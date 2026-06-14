import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/expected_expense_repository.dart';
import '../../data/models/expected_expense_model.dart';
import '../../services/month_transition_service.dart';

final expectedExpenseRepositoryProvider =
    Provider<ExpectedExpenseRepository>((ref) {
  return ExpectedExpenseRepository();
});

final expectedExpensesProvider =
    FutureProvider<List<ExpectedExpense>>((ref) async {
  final repo = ref.watch(expectedExpenseRepositoryProvider);
  final month = _currentMonth();
  return await repo.getForMonth(month);
});

String _currentMonth() {
  // Use debug override date if set, otherwise use real current date
  final now = MonthTransitionService.debugOverrideDate ?? DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}';
}
