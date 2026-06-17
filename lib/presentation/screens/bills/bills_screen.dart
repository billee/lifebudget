import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/bill_model.dart';
import '../../../services/notification_service.dart';
import '../../providers/bill_provider.dart';
import '../../widgets/common/lifebudget_scaffold.dart';
import '../../widgets/common/app_menu_button.dart';

class BillsScreen extends ConsumerWidget {
  const BillsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billsAsync = ref.watch(allBillsProvider);

    return LifeBudgetScaffold(
      appBar: AppBar(
        title: const Text('Bills', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: const [AppMenuButton()],
      ),
      body: billsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (bills) {
          if (bills.isEmpty) {
            return const Center(
              child: Text(
                'No bills yet.\nTap + to add one!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
            );
          }

          // Separate bills into sections
          final overdue = bills.where((b) => b.isOverdue()).toList();
          final dueSoon = bills
              .where((b) => !b.isOverdue() && b.isDueSoon(days: 7))
              .toList();
          final upcoming = bills
              .where(
                  (b) => !b.isOverdue() && !b.isDueSoon(days: 7) && !b.isPaid)
              .toList();
          final paid = bills.where((b) => b.isPaid).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (overdue.isNotEmpty) ...[
                _buildSectionHeader('Overdue', AppColors.critical),
                const SizedBox(height: 8),
                ...overdue.map((bill) => _buildBillCard(context, ref, bill)),
                const SizedBox(height: 16),
              ],
              if (dueSoon.isNotEmpty) ...[
                _buildSectionHeader('Due Soon', AppColors.warning),
                const SizedBox(height: 8),
                ...dueSoon.map((bill) => _buildBillCard(context, ref, bill)),
                const SizedBox(height: 16),
              ],
              if (upcoming.isNotEmpty) ...[
                _buildSectionHeader('Upcoming', AppColors.primary),
                const SizedBox(height: 8),
                ...upcoming.map((bill) => _buildBillCard(context, ref, bill)),
                const SizedBox(height: 16),
              ],
              if (paid.isNotEmpty) ...[
                _buildSectionHeader('Paid', AppColors.onTrack),
                const SizedBox(height: 8),
                ...paid.map((bill) => _buildBillCard(context, ref, bill)),
                const SizedBox(height: 16),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBillDialog(context, ref),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }

  Widget _buildBillCard(BuildContext context, WidgetRef ref, BillModel bill) {
    final daysUntil = bill.daysUntilDue();
    String statusText;
    Color statusColor;

    if (bill.isPaid) {
      statusText = 'Paid';
      statusColor = AppColors.onTrack;
    } else if (bill.isOverdue()) {
      statusText = 'Overdue by ${-daysUntil} days';
      statusColor = AppColors.critical;
    } else if (daysUntil == 0) {
      statusText = 'Due today';
      statusColor = AppColors.critical;
    } else if (daysUntil == 1) {
      statusText = 'Due tomorrow';
      statusColor = AppColors.warning;
    } else {
      statusText = 'Due in $daysUntil days';
      statusColor = AppColors.primary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: bill.isOverdue()
            ? Border.all(color: AppColors.critical.withOpacity(0.3), width: 2)
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bill.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  bill.category,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (bill.isRecurring)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Monthly',
                      style: TextStyle(fontSize: 10, color: AppColors.primary),
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₱${bill.amount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 11,
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20),
            onSelected: (value) {
              if (value == 'mark_paid') {
                _markAsPaid(context, ref, bill);
              } else if (value == 'edit') {
                _showEditBillDialog(context, ref, bill);
              } else if (value == 'delete') {
                _showDeleteDialog(context, ref, bill);
              }
            },
            itemBuilder: (context) => [
              if (!bill.isPaid)
                const PopupMenuItem(
                  value: 'mark_paid',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle,
                          size: 18, color: AppColors.onTrack),
                      SizedBox(width: 8),
                      Text('Mark as Paid'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 18, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 18, color: AppColors.critical),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: AppColors.critical)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddBillDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => _BillDialog(
        onSave: (bill) async {
          final repo = ref.read(billRepositoryProvider);
          final id = await repo.insertBill(bill);

          // Schedule reminder for the newly added bill
          final savedBill = bill.copyWith(id: id);
          await NotificationService.instance.scheduleBillReminder(
            billId: savedBill.id!,
            title: savedBill.title,
            amount: savedBill.amount,
            dueDate: savedBill.dueDate,
            daysBefore: 3, // Remind 3 days before due date
          );

          ref.invalidate(allBillsProvider);
          ref.invalidate(unpaidBillsProvider);
          ref.invalidate(billsDueSoonProvider);
          ref.invalidate(overdueBillsProvider);
        },
      ),
    );
  }

  void _showEditBillDialog(
      BuildContext context, WidgetRef ref, BillModel bill) {
    showDialog(
      context: context,
      builder: (ctx) => _BillDialog(
        bill: bill,
        onSave: (updatedBill) async {
          final repo = ref.read(billRepositoryProvider);
          await repo.updateBill(updatedBill);

          // Reschedule reminder for the updated bill
          await NotificationService.instance
              .cancelBillReminder(updatedBill.id!);
          if (!updatedBill.isPaid) {
            await NotificationService.instance.scheduleBillReminder(
              billId: updatedBill.id!,
              title: updatedBill.title,
              amount: updatedBill.amount,
              dueDate: updatedBill.dueDate,
              daysBefore: 3,
            );
          }

          ref.invalidate(allBillsProvider);
          ref.invalidate(unpaidBillsProvider);
          ref.invalidate(billsDueSoonProvider);
          ref.invalidate(overdueBillsProvider);
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, BillModel bill) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Bill'),
        content: Text('Are you sure you want to delete "${bill.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final repo = ref.read(billRepositoryProvider);

              // Cancel reminder before deleting
              await NotificationService.instance.cancelBillReminder(bill.id!);

              await repo.deleteBill(bill.id!);
              ref.invalidate(allBillsProvider);
              ref.invalidate(unpaidBillsProvider);
              ref.invalidate(billsDueSoonProvider);
              ref.invalidate(overdueBillsProvider);
              if (context.mounted) {
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Delete',
                style: TextStyle(color: AppColors.critical)),
          ),
        ],
      ),
    );
  }

  void _markAsPaid(BuildContext context, WidgetRef ref, BillModel bill) async {
    final repo = ref.read(billRepositoryProvider);

    // Cancel reminder since bill is now paid
    await NotificationService.instance.cancelBillReminder(bill.id!);

    await repo.markAsPaid(bill.id!);
    ref.invalidate(allBillsProvider);
    ref.invalidate(unpaidBillsProvider);
    ref.invalidate(billsDueSoonProvider);
    ref.invalidate(overdueBillsProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${bill.title} marked as paid'),
          backgroundColor: AppColors.onTrack,
        ),
      );
    }
  }
}

class _BillDialog extends StatefulWidget {
  final BillModel? bill;
  final Future<void> Function(BillModel) onSave;

  const _BillDialog({this.bill, required this.onSave});

  @override
  State<_BillDialog> createState() => _BillDialogState();
}

class _BillDialogState extends State<_BillDialog> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  DateTime _dueDate = DateTime.now();
  bool _isRecurring = false;

  @override
  void initState() {
    super.initState();
    if (widget.bill != null) {
      _titleController.text = widget.bill!.title;
      _amountController.text = widget.bill!.amount.toString();
      _categoryController.text = widget.bill!.category;
      _dueDate = widget.bill!.dueDate;
      _isRecurring = widget.bill!.isRecurring;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.bill == null ? 'Add Bill' : 'Edit Bill'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Bill Title',
                hintText: 'e.g., Rent, Electric Bill',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '₱ ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'Category',
                hintText: 'e.g., Rent, Utilities, Subscriptions',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text('${_dueDate.month}/${_dueDate.day}/${_dueDate.year}'),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dueDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                );
                if (picked != null) {
                  setState(() => _dueDate = picked);
                }
              },
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Monthly Recurring'),
              subtitle: const Text('Repeats every month'),
              value: _isRecurring,
              onChanged: (value) => setState(() => _isRecurring = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            final title = _titleController.text.trim();
            final amount = double.tryParse(_amountController.text);
            final category = _categoryController.text.trim();

            if (title.isEmpty ||
                amount == null ||
                amount <= 0 ||
                category.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Please fill all fields correctly')),
              );
              return;
            }

            final bill = BillModel(
              id: widget.bill?.id,
              title: title,
              amount: amount,
              dueDate: _dueDate,
              category: category,
              isRecurring: _isRecurring,
              isPaid: widget.bill?.isPaid ?? false,
              paidDate: widget.bill?.paidDate,
            );

            await widget.onSave(bill);
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: const Text('Save', style: TextStyle(color: AppColors.primary)),
        ),
      ],
    );
  }
}
