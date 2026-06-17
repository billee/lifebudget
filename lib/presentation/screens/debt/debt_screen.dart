import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/debt_model.dart';
import '../../providers/debt_provider.dart';
import '../../widgets/common/lifebudget_scaffold.dart';
import '../../widgets/common/app_menu_button.dart';

class DebtScreen extends ConsumerWidget {
  const DebtScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debtsAsync = ref.watch(allDebtsProvider);
    final totalBalanceAsync = ref.watch(totalDebtBalanceProvider);

    return LifeBudgetScaffold(
      appBar: AppBar(
        title: const Text('Debts', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: const [AppMenuButton()],
      ),
      body: debtsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (debts) {
          if (debts.isEmpty) {
            return const Center(
              child: Text(
                'No debts yet.\nTap + to add one!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
            );
          }

          return Column(
            children: [
              // Total debt summary card
              totalBalanceAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (totalBalance) =>
                    _buildTotalDebtCard(totalBalance, debts.length),
              ),
              // Debt list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: debts.length,
                  itemBuilder: (context, index) {
                    return _buildDebtCard(context, ref, debts[index]);
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDebtDialog(context, ref),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTotalDebtCard(double totalBalance, int debtCount) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Debt Balance',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₱${totalBalance.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$debtCount debt${debtCount == 1 ? '' : 's'}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtCard(BuildContext context, WidgetRef ref, DebtModel debt) {
    final progress = debt.progressPercentage;
    final isPaidOff = debt.isPaidOff;
    final isOverdue = debt.isOverdue();
    final isDueSoon = debt.isDueSoon(days: 7);
    final daysUntil = debt.daysUntilDue();

    String statusText;
    Color statusColor;

    if (isPaidOff) {
      statusText = 'Paid Off! 🎉';
      statusColor = AppColors.onTrack;
    } else if (isOverdue) {
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: isOverdue
            ? Border.all(color: AppColors.critical.withOpacity(0.3), width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      debt.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (debt.interestRate > 0)
                      Text(
                        '${debt.interestRate}% APR',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                '₱${debt.currentBalance.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: isPaidOff ? AppColors.onTrack : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress / 100,
              backgroundColor: AppColors.background,
              valueColor: AlwaysStoppedAnimation<Color>(
                isPaidOff ? AppColors.onTrack : AppColors.primary,
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${progress.toStringAsFixed(1)}% paid',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ],
          ),
          if (!isPaidOff) ...[
            const SizedBox(height: 8),
            Text(
              'Min. payment: ₱${debt.minimumPayment.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!isPaidOff)
                TextButton.icon(
                  onPressed: () => _showMakePaymentDialog(context, ref, debt),
                  icon: const Icon(Icons.payment, size: 18),
                  label: const Text('Make Payment'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              IconButton(
                onPressed: () => _showEditDebtDialog(context, ref, debt),
                icon:
                    const Icon(Icons.edit, size: 20, color: AppColors.primary),
              ),
              IconButton(
                onPressed: () => _showDeleteDialog(context, ref, debt),
                icon: const Icon(Icons.delete,
                    size: 20, color: AppColors.critical),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddDebtDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => _DebtDialog(
        onSave: (debt) async {
          final repo = ref.read(debtRepositoryProvider);
          await repo.insertDebt(debt);
          ref.invalidate(allDebtsProvider);
          ref.invalidate(activeDebtsProvider);
          ref.invalidate(totalDebtBalanceProvider);
          ref.invalidate(debtsDueSoonProvider);
          ref.invalidate(overdueDebtsProvider);
        },
      ),
    );
  }

  void _showEditDebtDialog(
      BuildContext context, WidgetRef ref, DebtModel debt) {
    showDialog(
      context: context,
      builder: (ctx) => _DebtDialog(
        debt: debt,
        onSave: (updatedDebt) async {
          final repo = ref.read(debtRepositoryProvider);
          await repo.updateDebt(updatedDebt);
          ref.invalidate(allDebtsProvider);
          ref.invalidate(activeDebtsProvider);
          ref.invalidate(totalDebtBalanceProvider);
          ref.invalidate(debtsDueSoonProvider);
          ref.invalidate(overdueDebtsProvider);
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, DebtModel debt) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Debt'),
        content: Text('Are you sure you want to delete "${debt.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final repo = ref.read(debtRepositoryProvider);
              await repo.deleteDebt(debt.id!);
              ref.invalidate(allDebtsProvider);
              ref.invalidate(activeDebtsProvider);
              ref.invalidate(totalDebtBalanceProvider);
              ref.invalidate(debtsDueSoonProvider);
              ref.invalidate(overdueDebtsProvider);
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

  void _showMakePaymentDialog(
      BuildContext context, WidgetRef ref, DebtModel debt) {
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Pay ${debt.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current balance: ₱${debt.currentBalance.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Payment Amount',
                prefixText: '₱ ',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            if (debt.minimumPayment > 0) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  amountController.text = debt.minimumPayment.toString();
                },
                child: Text(
                  'Use minimum: ₱${debt.minimumPayment.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid amount')),
                );
                return;
              }

              if (amount > debt.currentBalance) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Amount cannot exceed balance')),
                );
                return;
              }

              final repo = ref.read(debtRepositoryProvider);
              await repo.makePayment(debt.id!, amount);

              ref.invalidate(allDebtsProvider);
              ref.invalidate(activeDebtsProvider);
              ref.invalidate(totalDebtBalanceProvider);
              ref.invalidate(debtsDueSoonProvider);
              ref.invalidate(overdueDebtsProvider);

              if (context.mounted) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Payment of ₱${amount.toStringAsFixed(0)} recorded!'),
                    backgroundColor: AppColors.onTrack,
                  ),
                );
              }
            },
            child:
                const Text('Pay', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

class _DebtDialog extends StatefulWidget {
  final DebtModel? debt;
  final Future<void> Function(DebtModel) onSave;

  const _DebtDialog({this.debt, required this.onSave});

  @override
  State<_DebtDialog> createState() => _DebtDialogState();
}

class _DebtDialogState extends State<_DebtDialog> {
  final _nameController = TextEditingController();
  final _totalAmountController = TextEditingController();
  final _currentBalanceController = TextEditingController();
  final _interestRateController = TextEditingController();
  final _minimumPaymentController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));

  @override
  void initState() {
    super.initState();
    if (widget.debt != null) {
      _nameController.text = widget.debt!.name;
      _totalAmountController.text = widget.debt!.totalAmount.toString();
      _currentBalanceController.text = widget.debt!.currentBalance.toString();
      _interestRateController.text = widget.debt!.interestRate.toString();
      _minimumPaymentController.text = widget.debt!.minimumPayment.toString();
      _notesController.text = widget.debt!.notes ?? '';
      _dueDate = widget.debt!.dueDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _totalAmountController.dispose();
    _currentBalanceController.dispose();
    _interestRateController.dispose();
    _minimumPaymentController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.debt == null ? 'Add Debt' : 'Edit Debt'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Debt Name',
                hintText: 'e.g., Credit Card, Student Loan',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _totalAmountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Total Amount',
                prefixText: '₱ ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _currentBalanceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Current Balance',
                prefixText: '₱ ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _interestRateController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Interest Rate (APR)',
                suffixText: '%',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _minimumPaymentController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Minimum Payment',
                prefixText: '₱ ',
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
                  lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                );
                if (picked != null) {
                  setState(() => _dueDate = picked);
                }
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
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
            final name = _nameController.text.trim();
            final totalAmount = double.tryParse(_totalAmountController.text);
            final currentBalance =
                double.tryParse(_currentBalanceController.text);
            final interestRate =
                double.tryParse(_interestRateController.text) ?? 0;
            final minimumPayment =
                double.tryParse(_minimumPaymentController.text);

            if (name.isEmpty ||
                totalAmount == null ||
                totalAmount <= 0 ||
                currentBalance == null ||
                currentBalance < 0 ||
                minimumPayment == null ||
                minimumPayment <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Please fill all fields correctly')),
              );
              return;
            }

            final debt = DebtModel(
              id: widget.debt?.id,
              name: name,
              totalAmount: totalAmount,
              currentBalance: currentBalance,
              interestRate: interestRate,
              minimumPayment: minimumPayment,
              dueDate: _dueDate,
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
            );

            await widget.onSave(debt);
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
