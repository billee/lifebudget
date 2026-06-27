import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/bill_model.dart';
import '../../data/models/expected_expense_model.dart';
import '../../data/repositories/bill_repository.dart';
import '../../data/repositories/expected_expense_repository.dart';
import 'bill_provider.dart';
import 'expected_expenses_provider.dart';

enum DueItemType { bill, expense }

class DueItem {
  final int id;
  final String title;
  final double amount;
  final DateTime dueDate;
  final DueItemType type;
  final bool isOverdue;

  DueItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.dueDate,
    required this.type,
    this.isOverdue = false,
  });
}

final dueItemsProvider = FutureProvider<List<DueItem>>((ref) async {
  // Correct way: use .future on the provider reference
  final bills = await ref.watch(allBillsProvider.future);
  final expenses = await ref.watch(expectedExpensesProvider.future);

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  List<DueItem> items = [];

  for (final bill in bills) {
    if (!bill.isPaid) {
      items.add(DueItem(
        id: bill.id!,
        title: bill.title,
        amount: bill.amount,
        dueDate: bill.dueDate,
        type: DueItemType.bill,
        isOverdue: bill.isOverdue(),
      ));
    }
  }

  for (final expense in expenses) {
    if (expense.dueDate != null) {
      final dueDate = expense.dueDate!;
      items.add(DueItem(
        id: expense.id!,
        title: expense.title,
        amount: expense.amount,
        dueDate: dueDate,
        type: DueItemType.expense,
        isOverdue: dueDate.isBefore(today),
      ));
    }
  }

  items.sort((a, b) => a.dueDate.compareTo(b.dueDate));
  return items;
});

final urgentDueItemsCountProvider = FutureProvider<int>((ref) async {
  final items = await ref.watch(dueItemsProvider.future);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return items
      .where(
          (item) => item.dueDate.isBefore(today.add(const Duration(days: 1))))
      .length;
});
