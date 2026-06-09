import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'transaction_provider.dart';
import 'expected_expenses_provider.dart';
import '../../../core/utils/number_formatter.dart'; // optional, for formatting

final safelySpendRemainingProvider = FutureProvider<double>((ref) async {
  final transactions = await ref.watch(allTransactionsProvider.future);
  final expectedExpenses = await ref.watch(expectedExpensesProvider.future);

  final now = DateTime.now();
  final currentMonth = DateTime(now.year, now.month, 1);

  double totalIncome = 0;
  double safelySpendSpent = 0;
  double deductionSpent = 0;

  for (final t in transactions) {
    if (t.date.isBefore(currentMonth)) continue;
    if (t.type == 'income') {
      totalIncome += t.amount;
    } else {
      final jarLower = t.jar.toLowerCase();
      if (jarLower == 'safely spend') {
        safelySpendSpent += t.amount;
      } else if (jarLower.endsWith('_deduction')) {
        deductionSpent += t.amount;
      }
    }
  }

  final effectiveIncome = totalIncome - safelySpendSpent - deductionSpent;

  final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
  double plannedMonthlyTotal = 0;
  for (final exp in expectedExpenses) {
    if (exp.title.toLowerCase() == 'safely spend') continue;
    switch (exp.frequency) {
      case 'daily':
        plannedMonthlyTotal += exp.amount * daysInMonth;
        break;
      case 'weekly':
        plannedMonthlyTotal += exp.amount * (daysInMonth / 7);
        break;
      case 'monthly':
        plannedMonthlyTotal += exp.amount;
        break;
    }
  }

  double freeMoney = effectiveIncome - plannedMonthlyTotal;
  if (freeMoney < 0) freeMoney = 0;
  return freeMoney;
});
