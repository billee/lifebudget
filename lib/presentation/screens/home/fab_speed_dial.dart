import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../screens/transactions/log_expense_screen.dart';
import '../../screens/transactions/log_income_screen.dart';
import '../../screens/transactions/transfer_dialog.dart';
import '../../providers/budget_provider.dart';
import '../../providers/due_items_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/bill_provider.dart';
import '../../providers/expected_expenses_provider.dart';
import '../../../data/models/transaction_model.dart';
import '../../../services/notification_service.dart';

class FabSpeedDial extends ConsumerStatefulWidget {
  final bool isOnLeftSide;
  final ValueChanged<bool>? onExpandedChanged;

  const FabSpeedDial({
    super.key,
    this.isOnLeftSide = false,
    this.onExpandedChanged,
  });

  @override
  ConsumerState<FabSpeedDial> createState() => FabSpeedDialState();
}

class FabSpeedDialState extends ConsumerState<FabSpeedDial>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _controller;
  late Animation<double> _rotate;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _rotate = Tween<double>(
      begin: 0,
      end: 0.125,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      _expanded ? _controller.forward() : _controller.reverse();
      widget.onExpandedChanged?.call(_expanded);
    });
  }

  void collapse() {
    if (_expanded) {
      setState(() {
        _expanded = false;
        _controller.reverse();
        widget.onExpandedChanged?.call(false);
      });
    }
  }

  // ============================================================
  // Due Items Dialog – uses StatefulBuilder for instant updates
  // ============================================================
  Future<void> _showDueItemsDialog(BuildContext context) async {
    // Fetch initial items
    final initialItems = await ref.read(dueItemsProvider.future);
    if (initialItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No bills or expenses due right now.'),
          backgroundColor: AppColors.onTrack,
        ),
      );
      return;
    }

    // Local mutable list
    List<DueItem> items = List.from(initialItems);

    showModalBottomSheet(
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
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${items.length} item${items.length > 1 ? 's' : ''} due',
                        style: const TextStyle(color: AppColors.textSecondary),
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
                                separatorBuilder: (_, __) => const Divider(),
                                itemBuilder: (context, index) {
                                  final item = items[index];
                                  return _DueItemTile(
                                    item: item,
                                    onMarkPaid: () async {
                                      // Mark as paid in database
                                      await _markAsPaid(context, ref, item);
                                      // Remove from local list and update UI
                                      setState(() {
                                        items.removeAt(index);
                                      });
                                      // Invalidate providers to sync background data
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

  Future<void> _markAsPaid(
      BuildContext context, WidgetRef ref, DueItem item) async {
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
      // Invalidate all relevant providers to keep the rest of the app in sync
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

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final alignment =
        widget.isOnLeftSide ? CrossAxisAlignment.start : CrossAxisAlignment.end;
    final dueCountAsync = ref.watch(urgentDueItemsCountProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignment,
      children: [
        if (_expanded) ...[
          _MiniFAB(
            icon: Icons.edit_note_rounded,
            label: 'Log expense',
            onTap: () {
              _toggle();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LogExpenseScreen()),
              );
            },
          ),
          const SizedBox(height: 6),
          _MiniFAB(
            icon: Icons.add_rounded,
            label: 'Add income',
            onTap: () {
              _toggle();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LogIncomeScreen()),
              );
            },
          ),
          const SizedBox(height: 6),
          _MiniFAB(
            icon: Icons.swap_horiz_rounded,
            label: 'Transfer',
            onTap: () {
              _toggle();
              final budgetAsync = ref.read(budgetStateProvider);
              final categories = budgetAsync.when(
                data: (budget) =>
                    budget.expectedExpenses.map((e) => e.name).toList(),
                loading: () => <String>[],
                error: (_, __) => <String>[],
              );
              if (categories.isNotEmpty) {
                showDialog(
                  context: context,
                  builder: (ctx) => TransferDialog(categories: categories),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('No categories available for transfer')),
                );
              }
            },
          ),
          const SizedBox(height: 6),
          dueCountAsync.when(
            loading: () => _MiniFAB(
              icon: Icons.receipt_long_rounded,
              label: 'Pay Bill',
              onTap: () {},
            ),
            error: (_, __) => _MiniFAB(
              icon: Icons.receipt_long_rounded,
              label: 'Pay Bill',
              onTap: () {},
            ),
            data: (count) {
              return Badge(
                label: Text('$count'),
                isLabelVisible: count > 0,
                child: _MiniFAB(
                  icon: Icons.receipt_long_rounded,
                  label: 'Pay Bill',
                  onTap: () {
                    _toggle();
                    _showDueItemsDialog(context);
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 10),
        ],
        GestureDetector(
          onTap: _toggle,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => Transform.rotate(
              angle: _rotate.value * 2 * 3.141592,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  _expanded ? Icons.close : Icons.add,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// Due Item Tile (unchanged)
// ============================================================
class _DueItemTile extends StatelessWidget {
  final DueItem item;
  final VoidCallback onMarkPaid;

  const _DueItemTile({required this.item, required this.onMarkPaid});

  @override
  Widget build(BuildContext context) {
    final isOverdue = item.isOverdue;
    final daysUntil = item.dueDate.difference(DateTime.now()).inDays;
    String status;
    Color statusColor;
    if (isOverdue) {
      status = 'Overdue';
      statusColor = AppColors.critical;
    } else if (daysUntil == 0) {
      status = 'Due today';
      statusColor = AppColors.warning;
    } else if (daysUntil == 1) {
      status = 'Due tomorrow';
      statusColor = AppColors.primary;
    } else {
      status = 'Due in $daysUntil days';
      statusColor = AppColors.textSecondary;
    }

    return ListTile(
      leading: Icon(
        item.type == DueItemType.bill ? Icons.receipt : Icons.category,
        color: isOverdue ? AppColors.critical : AppColors.primary,
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

// ============================================================
// Mini FAB (unchanged)
// ============================================================
class _MiniFAB extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MiniFAB(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(width: 8),
            Icon(icon, size: 16, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
