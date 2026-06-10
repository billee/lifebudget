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
  final _monthlyController = TextEditingController();
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
    _monthlyController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _titleController.clear();
    _monthlyController.clear();
    setState(() {
      _selectedEmoji = '💰';
      _editingId = null;
    });
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final monthlyText = _monthlyController.text.trim();

    if (title.isEmpty) {
      _showSnackbar('Please enter a goal title');
      return;
    }
    if (monthlyText.isEmpty) {
      _showSnackbar('Please enter a monthly budget');
      return;
    }

    final monthlyAmount = double.tryParse(monthlyText);
    if (monthlyAmount == null || monthlyAmount <= 0) {
      _showSnackbar('Monthly budget must be a positive number');
      return;
    }

    final targetAmount = monthlyAmount; // monthly target

    final goalRepo = ref.read(goalRepositoryProvider);
    final expectedRepo = ref.read(expectedExpenseRepositoryProvider);
    final month =
        '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';

    try {
      if (_editingId == null) {
        final goal = Goal(
          title: title,
          targetAmount: targetAmount,
          currentAmount: 0.0,
          emoji: _selectedEmoji,
          isCompleted: false,
          createdDate: DateTime.now(),
        );
        await goalRepo.insert(goal);

        final expectedExpense = ExpectedExpense(
          title: title,
          frequency: 'monthly',
          amount: monthlyAmount,
          month: month,
        );
        await expectedRepo.insert(expectedExpense);

        _showSnackbar('Goal created! Monthly budget added.', isError: false);
      } else {
        final existingGoal = await _getGoal(_editingId!);
        if (existingGoal == null) {
          _showSnackbar('Goal not found');
          return;
        }
        final updatedGoal = existingGoal.copyWith(
          title: title,
          targetAmount: targetAmount,
          emoji: _selectedEmoji,
        );
        await goalRepo.update(updatedGoal);

        final allExpenses = await expectedRepo.getForMonth(month);
        bool found = false;
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
            found = true;
            break;
          }
        }
        if (!found) {
          await expectedRepo.insert(ExpectedExpense(
            title: title,
            frequency: 'monthly',
            amount: monthlyAmount,
            month: month,
          ));
        }
        _showSnackbar('Goal updated', isError: false);
      }

      ref.invalidate(goalsProvider);
      ref.invalidate(expectedExpensesProvider);
      ref.invalidate(allTransactionsProvider);
      ref.invalidate(jarSummariesProvider);

      _clearForm();
    } catch (e) {
      _showSnackbar('Error saving goal: $e');
    }
  }

  void _showSnackbar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.critical : AppColors.primary,
      ),
    );
  }

  Future<Goal?> _getGoal(int id) async {
    final goals = await ref.read(goalsProvider.future);
    try {
      return goals.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }

  void _edit(Goal goal) async {
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

    final expenses = await expectedRepo.getForMonth(month);
    for (final exp in expenses) {
      if (exp.title.toLowerCase().trim() == goalTitleLower) {
        await expectedRepo.delete(exp.id!);
        break;
      }
    }

    await transactionRepo.deleteSavingsByJar(goalTitleLower);
    await goalRepo.delete(goal.id!);

    ref.invalidate(goalsProvider);
    ref.invalidate(expectedExpensesProvider);
    ref.invalidate(allTransactionsProvider);
    ref.invalidate(jarSummariesProvider);

    _showSnackbar('Goal deleted', isError: false);
  }

  // Helper to calculate days left in current month
  int _getDaysLeftInMonth() {
    final now = DateTime.now();
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final daysLeft = lastDayOfMonth.difference(now).inDays + 1;
    return daysLeft > 0 ? daysLeft : 1;
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
                    child: Text(
                      'No goals created yet',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: goals.length,
                  itemBuilder: (context, index) {
                    final goal = goals[index];
                    final progress = goal.progressPercent;
                    final daysLeft = _getDaysLeftInMonth();
                    final dailyRate = goal.targetAmount / daysLeft;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 1,
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
                                      Text(
                                        goal.title,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Daily rate: ${formatAmount(dailyRate)} / day',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
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
                                  onPressed: () => _delete(goal),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: progress.clamp(0.0, 1.0),
                                minHeight: 10,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    AppColors.primary),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Saved: ${formatAmount(goal.currentAmount)}',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  'Target: ${formatAmount(goal.targetAmount)}',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                            if (goal.isCompleted)
                              Container(
                                margin: const EdgeInsets.only(top: 12),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.onTrack.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Completed! 🎉',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.onTrack,
                                  ),
                                ),
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
