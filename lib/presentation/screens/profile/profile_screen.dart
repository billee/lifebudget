import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../data/models/expected_expense_model.dart';
import '../../../data/models/goal_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../providers/expected_expenses_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/goal_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/slip_up_provider.dart';
import '../../providers/settings_provider.dart';
import '../../../services/notification_service.dart';
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

  final _nameController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _titleController.clear();
    _amountController.clear();
    setState(() {
      _frequency = 'monthly';
      _editingId = null;
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
      );
      await repo.insert(expense);
    } else {
      final expense = ExpectedExpense(
        id: _editingId,
        title: title,
        frequency: _frequency,
        amount: amount,
        month: month,
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

  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    ref.invalidate(userNameProvider);
  }

  void _showFreshStartDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Start Fresh?'),
        content: const Text(
          'This will clear all your logged expenses and income for this month. '
          'They’ll be saved in your history, but your current spending will reset to zero.\n\n'
          'Are you sure?',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final month =
                  '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';
              final repo = ref.read(transactionRepositoryProvider);
              await repo.archiveMonth(month);

              ref.invalidate(allTransactionsProvider);
              ref.invalidate(jarSummariesProvider);
              ref.invalidate(daysSinceLastSlipUpProvider);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fresh start! Your month is clean.'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Start Fresh'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to budget state changes and refresh expected expenses
    // This ensures Safely Spend is always up to date
    ref.listen(budgetStateProvider, (previous, next) {
      // When budget state changes, Safely Spend may have been updated
      // Invalidate expectedExpensesProvider to pick up the latest Safely Spend
      ref.invalidate(expectedExpensesProvider);
    });

    final expensesAsync = ref.watch(expectedExpensesProvider);
    final nameAsync = ref.watch(userNameProvider);
    final currentName = nameAsync.value ?? '';

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
            const Text('Your Name',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController..text = currentName,
                    decoration: InputDecoration(
                      hintText: 'Enter your name',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _saveName,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
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
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(exp.title,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          '${exp.frequency[0].toUpperCase()}${exp.frequency.substring(1)} — ${formatAmount(exp.amount)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (exp.title.toLowerCase() != 'safely spend')
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: AppColors.primary),
                                onPressed: () => _edit(exp),
                              ),
                            if (exp.amount > 0 &&
                                exp.title.toLowerCase() != 'safely spend')
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
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Daily Check‑in Reminder',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'A gentle nudge to stay on track. No pressure.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Consumer(
              builder: (context, ref, _) {
                final settings = ref.watch(reminderSettingsProvider);
                return Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Enable daily reminder'),
                      value: settings.enabled,
                      onChanged: (val) {
                        ref
                            .read(reminderSettingsProvider.notifier)
                            .setEnabled(val);
                        NotificationService.instance.scheduleDailyReminder(
                          enabled: val,
                          time: settings.time,
                        );
                      },
                      activeColor: AppColors.primary,
                    ),
                    if (settings.enabled)
                      ListTile(
                        title: const Text('Reminder time'),
                        subtitle: Text(settings.time.format(context)),
                        trailing: const Icon(Icons.access_time),
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: settings.time,
                          );
                          if (picked != null) {
                            ref
                                .read(reminderSettingsProvider.notifier)
                                .setTime(picked);
                            NotificationService.instance.scheduleDailyReminder(
                              enabled: true,
                              time: picked,
                            );
                          }
                        },
                      ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Survival Budget Mode'),
                      subtitle: const Text(
                          'Show only essentials – food, transport, rent, utilities'),
                      value: settings.survivalMode,
                      onChanged: (val) {
                        ref
                            .read(reminderSettingsProvider.notifier)
                            .setSurvivalMode(val);
                      },
                      activeColor: AppColors.primary,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Need a fresh start?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'If this month feels too heavy, you can wipe your spending clean and start over. '
              'Your past transactions will be saved in your history.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _showFreshStartDialog,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Start Fresh This Month',
                    style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
