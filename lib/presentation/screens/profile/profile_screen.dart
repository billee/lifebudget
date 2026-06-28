import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../data/models/expected_expense_model.dart';
import '../../../data/models/goal_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../providers/expected_expenses_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/goal_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/slip_up_provider.dart';
import '../../widgets/common/lifebudget_scaffold.dart';
import '../../widgets/common/app_menu_button.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _titleController = TextEditingController();
  String _frequency = 'monthly';
  final _amountController = TextEditingController();
  int? _editingId;
  DateTime? _dueDate; // NEW: optional due date

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _titleController.clear();
    _amountController.clear();
    setState(() {
      _frequency = 'monthly';
      _editingId = null;
      _dueDate = null; // NEW
    });
  }

  // NEW: show date picker
  Future<void> _selectDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  // NEW: clear due date
  void _clearDueDate() {
    setState(() {
      _dueDate = null;
    });
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final amountText = _amountController.text.trim();
    if (title.isEmpty || amountText.isEmpty) return;
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }

    final month =
        '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';
    final repo = ref.read(expectedExpenseRepositoryProvider);

    if (_editingId == null) {
      final expense = ExpectedExpense(
        title: title,
        frequency: _frequency,
        amount: amount,
        month: month,
        dueDate: _dueDate, // NEW
      );
      await repo.insert(expense);
    } else {
      final expense = ExpectedExpense(
        id: _editingId,
        title: title,
        frequency: _frequency,
        amount: amount,
        month: month,
        dueDate: _dueDate, // NEW
      );
      await repo.update(expense);
    }

    // Sync to matching Goal if one exists (manual search to avoid nullable issues)
    final goalRepo = ref.read(goalRepositoryProvider);
    final goals = await goalRepo.getAll();
    Goal? matchingGoal;
    for (final goal in goals) {
      if (goal.title.toLowerCase().trim() == title.toLowerCase().trim()) {
        matchingGoal = goal;
        break;
      }
    }
    if (matchingGoal != null) {
      // No further action – goal's monthly budget is already represented by ExpectedExpense
    }

    ref.invalidate(expectedExpensesProvider);
    _clearForm();
  }

  void _edit(ExpectedExpense expense) {
    setState(() {
      _editingId = expense.id;
      _titleController.text = expense.title;
      _frequency = expense.frequency;
      _amountController.text = expense.amount.toStringAsFixed(0);
      _dueDate = expense.dueDate; // NEW
    });
  }

  Future<void> _delete(ExpectedExpense expense) async {
    final transactionRepo = ref.read(transactionRepositoryProvider);
    final jarName = expense.title.toLowerCase();
    final spent = await transactionRepo.getJarSpentThisMonth(jarName);

    if (spent > 0 && mounted) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Delete "${expense.title}"?'),
          content: Text(
            'You\'ve already spent ${formatAmount(spent)} on ${expense.title} this month.\n\n'
            '• Budget will be set to \$0\n'
            '• Your ${formatAmount(spent)} spending will be deducted from your income\n'
            '• This keeps your daily allowance accurate\n\n'
            'Your spending history will be preserved.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.critical),
              child: const Text('Delete Expense'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      final repo = ref.read(expectedExpenseRepositoryProvider);
      final updated = ExpectedExpense(
        id: expense.id,
        title: expense.title,
        frequency: expense.frequency,
        amount: 0,
        month: expense.month,
        dueDate: expense.dueDate, // keep dueDate (optional)
      );
      await repo.update(updated);

      final deduction = TransactionModel(
        type: 'expense',
        jar: '${jarName}_deduction',
        amount: spent,
        date: DateTime.now(),
        note: 'Past spending on ${expense.title} (budget deleted)',
      );
      await transactionRepo.insertTransaction(deduction);

      final goalRepo = ref.read(goalRepositoryProvider);
      final goals = await goalRepo.getAll();
      for (final goal in goals) {
        if (goal.title.toLowerCase().trim() == jarName) {
          await goalRepo.delete(goal.id!);
          ref.invalidate(goalsProvider);
          break;
        }
      }

      ref.invalidate(expectedExpensesProvider);
      ref.invalidate(allTransactionsProvider);
      ref.invalidate(jarSummariesProvider);
    } else {
      final repo = ref.read(expectedExpenseRepositoryProvider);
      await repo.delete(expense.id!);
      ref.invalidate(expectedExpensesProvider);

      final goalRepo = ref.read(goalRepositoryProvider);
      final goals = await goalRepo.getAll();
      for (final goal in goals) {
        if (goal.title.toLowerCase().trim() == jarName) {
          await goalRepo.delete(goal.id!);
          ref.invalidate(goalsProvider);
          break;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expectedExpensesProvider);
    final budgetAsync = ref.watch(budgetStateProvider);

    return LifeBudgetScaffold(
      appBar: AppBar(
        title: const Text('Your Budget', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: const [AppMenuButton()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _editingId == null
                  ? 'Add Expected Expense'
                  : 'Edit Expected Expense',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _frequency,
              items: ['daily', 'monthly']
                  .map((f) => DropdownMenuItem(
                        value: f,
                        child: Text(f[0].toUpperCase() + f.substring(1)),
                      ))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _frequency = val);
              },
              decoration: InputDecoration(
                labelText: 'Frequency',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            // ======= NEW: DUE DATE SECTION =======
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading:
                  const Icon(Icons.calendar_today, color: AppColors.primary),
              title: Text(
                _dueDate == null
                    ? 'No due date (optional)'
                    : 'Due: ${_dueDate!.toLocal().toString().split(' ')[0]}',
                style: TextStyle(
                  color: _dueDate == null ? AppColors.textSecondary : null,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_dueDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.critical),
                      onPressed: _clearDueDate,
                    ),
                  IconButton(
                    icon: const Icon(Icons.edit_calendar,
                        color: AppColors.primary),
                    onPressed: () => _selectDueDate(context),
                  ),
                ],
              ),
              onTap: () => _selectDueDate(context),
            ),
            // =====================================
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(_editingId == null ? 'Save' : 'Update',
                        style: const TextStyle(fontSize: 16)),
                  ),
                ),
                if (_editingId != null) ...[
                  const SizedBox(width: 12),
                  TextButton(
                      onPressed: _clearForm, child: const Text('Cancel')),
                ],
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            const Text('Your Expected Expenses',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            expensesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (expenses) {
                // Get the calculated Safely Spend from budget state
                final calculatedSafelySpend =
                    budgetAsync.valueOrNull?.totalSafelySpendBudget ?? 0.0;

                if (expenses.isEmpty) {
                  return const Center(
                    child: Text(
                      'No expected expenses yet.\nAdd one above!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final exp = expenses[index];
                    final isSafelySpend =
                        exp.title.toLowerCase() == 'safely spend';
                    // Use calculated Safely Spend from budget state for display
                    final displayAmount =
                        isSafelySpend ? calculatedSafelySpend : exp.amount;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(exp.title,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${exp.frequency[0].toUpperCase()}${exp.frequency.substring(1)} — ${formatAmount(displayAmount)}',
                            ),
                            if (exp.dueDate != null) // NEW: show due date
                              Text(
                                'Due: ${exp.dueDate!.toLocal().toString().split(' ')[0]}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isSafelySpend)
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: AppColors.primary),
                                onPressed: () => _edit(exp),
                              ),
                            if (exp.amount > 0 && !isSafelySpend)
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: AppColors.critical),
                                onPressed: () => _delete(exp),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
