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
  final _dailyController = TextEditingController();
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
    _dailyController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _titleController.clear();
    _targetController.clear();
    _dailyController.clear();
    setState(() {
      _selectedEmoji = '💰';
      _editingId = null;
    });
  }

  double _computeDailyAllowance() {
    final transactions = ref.read(allTransactionsProvider).valueOrNull ?? [];
    final expectedExpenses =
        ref.read(expectedExpensesProvider).valueOrNull ?? [];

    double income = 0;
    double spent = 0;
    for (final t in transactions) {
      if (t.type == 'income') {
        income += t.amount;
      } else {
        spent += t.amount;
      }
    }

    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    double allocated = 0;
    for (final exp in expectedExpenses) {
      switch (exp.frequency) {
        case 'daily':
          allocated += exp.amount * daysInMonth;
          break;
        case 'weekly':
          allocated += exp.amount * (daysInMonth / 7);
          break;
        case 'monthly':
          allocated += exp.amount;
          break;
      }
    }

    double free = income - allocated;
    if (free < 0) free = 0;
    final daysLeft =
        DateTime(now.year, now.month + 1, 0).difference(now).inDays + 1;
    return daysLeft > 0 ? free / daysLeft : free;
  }

  Future<Goal?> _getGoal(int id) async {
    final goals = await ref.read(goalsProvider.future);
    return goals
        .cast<Goal?>()
        .firstWhere((g) => g!.id == id, orElse: () => null);
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final targetText = _targetController.text.trim();
    final dailyText = _dailyController.text.trim();

    if (title.isEmpty || targetText.isEmpty || dailyText.isEmpty) return;
    final target = double.tryParse(targetText);
    final dailyAmount = double.tryParse(dailyText);
    if (target == null ||
        dailyAmount == null ||
        target <= 0 ||
        dailyAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid amounts')),
      );
      return;
    }

    final allowance = _computeDailyAllowance();
    if (dailyAmount > allowance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Daily save (${formatAmount(dailyAmount)}) cannot exceed your safe spend (${formatAmount(allowance)})'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final goalRepo = ref.read(goalRepositoryProvider);
    final expectedRepo = ref.read(expectedExpenseRepositoryProvider);
    final transactionRepo = ref.read(transactionRepositoryProvider);
    final month =
        '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';

    if (_editingId == null) {
      final goal = Goal(
        title: title,
        targetAmount: target,
        currentAmount: dailyAmount,
        dailyAmount: dailyAmount,
        emoji: _selectedEmoji,
        isCompleted: dailyAmount >= target,
        createdDate: DateTime.now(),
      );
      await goalRepo.insert(goal);

      final expectedExpense = ExpectedExpense(
        title: title,
        frequency: 'daily',
        amount: dailyAmount,
        month: month,
      );
      await expectedRepo.insert(expectedExpense);

      final transaction = TransactionModel(
        type: 'savings',
        jar: title.toLowerCase(),
        amount: dailyAmount,
        date: DateTime.now(),
        note: 'Daily savings toward $title',
      );
      await transactionRepo.insertTransaction(transaction);

      if (goal.isCompleted && mounted) {
        showDialog(
          context: context,
          builder: (ctx) => GoalCelebrateScreen(
            goalTitle: title,
            emoji: _selectedEmoji,
          ),
        );
      }
    } else {
      final existingGoal = await _getGoal(_editingId!);
      if (existingGoal != null) {
        final updated = existingGoal.copyWith(
          title: title,
          targetAmount: target,
          dailyAmount: dailyAmount,
          emoji: _selectedEmoji,
        );
        await goalRepo.update(updated);

        // Replace expected expense
        await expectedRepo.deleteByTitle(updated.title);
        await expectedRepo.insert(ExpectedExpense(
          title: updated.title,
          frequency: 'daily',
          amount: dailyAmount,
          month: month,
        ));
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
          content: Text('Goal created! Daily savings added to your budget.'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  Future<void> _addMoney(Goal goal) async {
    final controller = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add extra savings'),
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

      final transactionRepo = ref.read(transactionRepositoryProvider);
      await transactionRepo.insertTransaction(TransactionModel(
        type: 'savings',
        jar: goal.title.toLowerCase(),
        amount: amount,
        date: DateTime.now(),
        note: 'Extra savings for ${goal.title}',
      ));

      ref.invalidate(goalsProvider);
      ref.invalidate(allTransactionsProvider);
      ref.invalidate(jarSummariesProvider);

      if (completed && mounted) {
        showDialog(
          context: context,
          builder: (ctx) => GoalCelebrateScreen(
            goalTitle: goal.title,
            emoji: goal.emoji,
          ),
        );
      }
    }
  }

  void _edit(Goal goal) {
    setState(() {
      _editingId = goal.id;
      _titleController.text = goal.title;
      _targetController.text = goal.targetAmount.toStringAsFixed(0);
      _dailyController.text = goal.dailyAmount.toStringAsFixed(0);
      _selectedEmoji = goal.emoji;
    });
  }

  Future<void> _delete(int id) async {
    final repo = ref.read(goalRepositoryProvider);
    await repo.delete(id);
    ref.invalidate(goalsProvider);
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
              controller: _dailyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Save per day',
                hintText: 'Less than your safe daily spend',
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
                  onSelected: (selected) {
                    setState(() => _selectedEmoji = emoji);
                  },
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

                // Build a map of title (lowercase) -> daily amount from expected expenses
                final expectedExpenses =
                    ref.watch(expectedExpensesProvider).valueOrNull ?? [];
                final expectedDailyAmounts = <String, double>{};
                for (final exp in expectedExpenses) {
                  if (exp.frequency == 'daily') {
                    expectedDailyAmounts[exp.title.toLowerCase().trim()] =
                        exp.amount;
                  }
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: goals.length,
                  itemBuilder: (context, index) {
                    final goal = goals[index];
                    final progress = goal.progressPercent;
                    // Use ExpectedExpense amount if available
                    final dailyAmount =
                        expectedDailyAmounts[goal.title.toLowerCase().trim()] ??
                            goal.dailyAmount;
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
                                        'Save ${formatAmount(dailyAmount)}/day',
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: AppColors.textSecondary),
                                  onPressed: () => _edit(goal),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: AppColors.critical),
                                  onPressed: () => _delete(goal.id!),
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
                            const SizedBox(height: 8),
                            Text(
                              '${formatAmount(goal.currentAmount)} of ${formatAmount(goal.targetAmount)}',
                              style: const TextStyle(fontSize: 14),
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
