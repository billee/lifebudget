import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/transaction_model.dart';
import '../../services/notification_service.dart';
import '../providers/bill_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/due_items_provider.dart';
import '../providers/expected_expenses_provider.dart';
import '../providers/transaction_provider.dart';

/// Shared bottom sheet for paying bills and due expected expenses.
class DueItemsSheet {
  DueItemsSheet._();

  static Future<void> show(BuildContext context, WidgetRef ref) async {
    final initialItems = await ref.read(dueItemsProvider.future);
    if (!context.mounted) return;

    if (initialItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No bills or expenses due right now.'),
          backgroundColor: AppColors.onTrack,
        ),
      );
      return;
    }

    final items = List<DueItem>.from(initialItems);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.3,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Pay Bills & Expenses',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${items.length} item${items.length == 1 ? '' : 's'} due',
                        style:
                            const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: items.isEmpty
                            ? const Center(
                                child: Text(
                                  'All cleared! No items due.',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                controller: scrollController,
                                itemCount: items.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(),
                                itemBuilder: (context, index) {
                                  final item = items[index];
                                  return DueItemTile(
                                    item: item,
                                    onMarkPaid: () async {
                                      await markAsPaid(context, ref, item);
                                      setState(() => items.removeAt(index));
                                      ref.invalidate(dueItemsProvider);
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  static Future<void> markAsPaid(
    BuildContext context,
    WidgetRef ref,
    DueItem item,
  ) async {
    try {
      if (item.type == DueItemType.bill) {
        final billRepo = ref.read(billRepositoryProvider);
        await billRepo.markAsPaid(item.id);
        await NotificationService.instance.cancelBillReminder(item.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${item.title} marked as paid'),
              backgroundColor: AppColors.onTrack,
            ),
          );
        }
      } else {
        final expenseRepo = ref.read(expectedExpenseRepositoryProvider);
        await expenseRepo.markAsPaid(item.id);

        final transactionRepo = ref.read(transactionRepositoryProvider);
        final transaction = TransactionModel(
          type: 'expense',
          jar: item.title,
          amount: item.amount,
          date: DateTime.now(),
          note: 'Paid: ${item.title}',
        );
        await transactionRepo.insertTransaction(transaction);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${item.title} expense paid and recorded'),
              backgroundColor: AppColors.onTrack,
            ),
          );
        }
      }
      ref.invalidate(allTransactionsProvider);
      ref.invalidate(expectedExpensesProvider);
      ref.invalidate(budgetStateProvider);
      ref.invalidate(dueItemsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error marking as paid: $e'),
            backgroundColor: AppColors.critical,
          ),
        );
      }
    }
  }
}

class DueItemTile extends StatelessWidget {
  final DueItem item;
  final VoidCallback onMarkPaid;

  const DueItemTile({
    super.key,
    required this.item,
    required this.onMarkPaid,
  });

  static String statusLabel(DueItem item) {
    final isOverdue = item.isOverdue;
    final daysUntil = item.dueDate.difference(DateTime.now()).inDays;
    if (isOverdue) return 'Overdue';
    if (daysUntil == 0) return 'Due today';
    if (daysUntil == 1) return 'Due tomorrow';
    return 'Due in $daysUntil days';
  }

  static Color statusColor(DueItem item) {
    final isOverdue = item.isOverdue;
    final daysUntil = item.dueDate.difference(DateTime.now()).inDays;
    if (isOverdue) return AppColors.critical;
    if (daysUntil == 0) return AppColors.warning;
    if (daysUntil == 1) return AppColors.primary;
    return AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final status = statusLabel(item);
    final statusColor = DueItemTile.statusColor(item);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        item.type == DueItemType.bill ? Icons.receipt : Icons.category,
        color: item.isOverdue ? AppColors.critical : AppColors.primary,
      ),
      title: Text(item.title),
      subtitle: Text(
        '₱${item.amount.toStringAsFixed(0)} • $status',
        style: TextStyle(color: statusColor),
      ),
      trailing: ElevatedButton(
        onPressed: onMarkPaid,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.onTrack,
          foregroundColor: Colors.white,
        ),
        child: const Text('Pay'),
      ),
    );
  }
}
