import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../data/models/goal_model.dart';
import '../../../data/models/expected_expense_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../providers/goal_provider.dart';
import '../../providers/expected_expenses_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/common/lifebudget_scaffold.dart';
import 'goal_celebrate_screen.dart';
import '../../widgets/common/app_menu_button.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  final _titleController = TextEditingController();
  final _targetController = TextEditingController();
  final _monthlyController =
      TextEditingController(); // monthly allocation (expected expense)
  String _selectedEmoji = '💰';
  int? _editingId;

  final List<String> _emojiList = [
    '💰',
    '🏠',
    '🚗',
    '🎓',
    '💻',
    '🐷',
    '✈️',
    '🎁',
    '🏥',
    '📱'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    _monthlyController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _titleController.clear();
    _targetController.clear();
    _monthlyController.clear();
    setState(() {
      _selectedEmoji = '💰';
      _editingId = null;
    });
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final targetText = _targetController.text.trim();
    final monthlyText = _monthlyController.text.trim();

    if (title.isEmpty || targetText.isEmpty || monthlyText.isEmpty) return;
    final target = double.tryParse(targetText);
    final monthlyAmount = double.tryParse(monthlyText);
    if (target == null ||
        monthlyAmount == null ||
        target <= 0 ||
        monthlyAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid amounts')),
      );
      return;
    }

    final goalRepo = ref.read(goalRepositoryProvider);
    final expectedRepo = ref.read(expectedExpenseRepositoryProvider);
    final month =
        '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';

    if (_editingId == null) {
      // Create Goal
      final goal = Goal(
        title: title,
        targetAmount: target,
        currentAmount: 0.0,
        emoji: _selectedEmoji,
        isCompleted: false,
        createdDate: DateTime.now(),
      );
      await goalRepo.insert(goal);

      // Create Expected Expense (monthly frequency) for the goal
      final expectedExpense = ExpectedExpense(
        title: title,
        frequency: 'monthly',
        amount: monthlyAmount,
        month: month,
      );
      await expectedRepo.insert(expectedExpense);

      // No automatic transaction – user will add money manually
    } else {
      // Edit existing goal
      final existingGoal = await _getGoal(_editingId!);
      if (existingGoal != null) {
        final updated = existingGoal.copyWith(
          title: title,
          targetAmount: target,
          emoji: _selectedEmoji,
        );
        await goalRepo.update(updated);

        // Update expected expense (monthly amount)
        final allExpenses = await expectedRepo.getForMonth(month);
        for (final exp in allExpenses) {
          if (exp.title.toLowerCase().trim() ==
              existingGoal.title.toLowerCase().trim()) {
            final updatedExpense = ExpectedExpense(
              id: exp.id,
              title: title,
              frequency: 'monthly',
              amount: monthlyAmount,
              month: month,
            );
            await expectedRepo.update(updatedExpense);
            break;
          }
        }
      }
    }

    ref.invalidate(goalsProvider);
    ref.invalidate(expectedExpensesProvider);
    ref.invalidate(allTransactionsProvider);
    ref.invalidate(jarSummariesProvider);

    _clearForm();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Goal created! Monthly budget added.'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  Future<Goal?> _getGoal(int id) async {
    final goals = await ref.read(goalsProvider.future);
    return goals.cast<Goal?>().firstWhere(
          (g) => g!.id == id,
          orElse: () => null,
        );
  }

  Future<void> _addMoney(Goal goal) async {
    final controller = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add savings to goal'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Amount'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              Navigator.pop(ctx, val);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (amount != null && amount > 0) {
      final newCurrent = goal.currentAmount + amount;
      final completed = newCurrent >= goal.targetAmount;
      final updated = goal.copyWith(
        currentAmount: newCurrent,
        isCompleted: completed,
      );
      final goalRepo = ref.read(goalRepositoryProvider);
      await goalRepo.update(updated);

      // Log a savings transaction (type: savings, jar: goal_title)
      final transactionRepo = ref.read(transactionRepositoryProvider);
      await transactionRepo.insertTransaction(TransactionModel(
        type: 'savings',
        jar: goal.title.toLowerCase(),
        amount: amount,
        date: DateTime.now(),
        note: 'Manual savings for ${goal.title}',
      ));

      ref.invalidate(goalsProvider);
      ref.invalidate(allTransactionsProvider);
      ref.invalidate(jarSummariesProvider);

      if (completed && mounted) {
        showDialog(
          context: context,
          builder: (ctx) =>
              GoalCelebrateScreen(goalTitle: goal.title, emoji: goal.emoji),
        );
      }
    }
  }

  void _edit(Goal goal) async {
    // Fetch its expected expense to get monthly amount
    final month =
        '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';
    final expectedRepo = ref.read(expectedExpenseRepositoryProvider);
    final expenses = await expectedRepo.getForMonth(month);
    double monthlyAmount = 0;
    for (final exp in expenses) {
      if (exp.title.toLowerCase().trim() == goal.title.toLowerCase().trim()) {
        monthlyAmount = exp.amount;
        break;
      }
    }
    setState(() {
      _editingId = goal.id;
      _titleController.text = goal.title;
      _targetController.text = goal.targetAmount.toStringAsFixed(0);
      _monthlyController.text = monthlyAmount.toStringAsFixed(0);
      _selectedEmoji = goal.emoji;
    });
  }

  Future<void> _delete(Goal goal) async {
    final goalTitleLower = goal.title.toLowerCase().trim();
    final expectedRepo = ref.read(expectedExpenseRepositoryProvider);
    final transactionRepo = ref.read(transactionRepositoryProvider);
    final goalRepo = ref.read(goalRepositoryProvider);
    final month =
        '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';

    // Delete expected expense
    final expenses = await expectedRepo.getForMonth(month);
    for (final exp in expenses) {
      if (exp.title.toLowerCase().trim() == goalTitleLower) {
        await expectedRepo.delete(exp.id!);
        break;
      }
    }

    // Delete savings transactions for this goal
    await transactionRepo.deleteSavingsByJar(goalTitleLower);

    // Delete goal
    await goalRepo.delete(goal.id!);

    ref.invalidate(goalsProvider);
    ref.invalidate(expectedExpensesProvider);
    ref.invalidate(allTransactionsProvider);
    ref.invalidate(jarSummariesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final goalsAsync = ref.watch(goalsProvider);

    return LifeBudgetScaffold(
      appBar: AppBar(
        title: const Text('Goals', style: TextStyle(color: Colors.white)),
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
              _editingId == null ? 'Create a Goal' : 'Edit Goal',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'What do you want to save for?',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12))),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _targetController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Target amount',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12))),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _monthlyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monthly budget for this goal',
                hintText: 'How much you plan to save each month',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12))),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            const Text('Choose an icon:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _emojiList.map((emoji) {
                return ChoiceChip(
                  label: Text(emoji),
                  selected: _selectedEmoji == emoji,
                  onSelected: (selected) =>
                      setState(() => _selectedEmoji = emoji),
                  selectedColor: AppColors.primary.withOpacity(0.2),
                );
              }).toList(),
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
                    child: Text(_editingId == null ? 'Create' : 'Update',
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
            const Text('Your Goals',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            goalsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (goals) {
                if (goals.isEmpty) {
                  return const Center(
                    child: Text('No goals yet. Create one above!',
                        style: TextStyle(color: AppColors.textSecondary)),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: goals.length,
                  itemBuilder: (context, index) {
                    final goal = goals[index];
                    final progress = goal.progressPercent;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(goal.emoji,
                                    style: const TextStyle(fontSize: 32)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(goal.title,
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold)),
                                      Text(
                                        'Saved: ${formatAmount(goal.currentAmount)} / ${formatAmount(goal.targetAmount)}',
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add,
                                      color: AppColors.primary),
                                  onPressed: () => _addMoney(goal),
                                  tooltip: 'Add money',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: AppColors.textSecondary),
                                  onPressed: () => _edit(goal),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: AppColors.critical),
                                  onPressed: () => _delete(goal),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: progress.clamp(0.0, 1.0),
                                minHeight: 12,
                                backgroundColor: Colors.grey[200],
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    AppColors.primary),
                              ),
                            ),
                            if (goal.isCompleted)
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.onTrack.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text('Completed! 🎉',
                                    style: TextStyle(color: AppColors.onTrack)),
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
