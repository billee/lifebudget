import 'package:flutter_riverpod/flutter_riverpod.dart';

class BudgetState {
  final double totalBudget;
  final String month; // e.g., '2026-05'
  const BudgetState({required this.totalBudget, required this.month});

  BudgetState copyWith({double? totalBudget, String? month}) {
    return BudgetState(
      totalBudget: totalBudget ?? this.totalBudget,
      month: month ?? this.month,
    );
  }
}

final budgetProvider = StateProvider<BudgetState>((ref) {
  // default initial budget
  return BudgetState(totalBudget: 18000, month: '2026-05');
});
