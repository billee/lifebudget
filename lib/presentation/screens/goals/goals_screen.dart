import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../data/models/goal_model.dart';
import '../../providers/goal_provider.dart';
import '../../widgets/common/lifebudget_scaffold.dart';
import 'goal_celebrate_screen.dart';
import '../../providers/transaction_provider.dart';
import '../../../data/models/transaction_model.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  final _titleController = TextEditingController();
  final _targetController = TextEditingController();
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
    super.dispose();
  }

  void _clearForm() {
    _titleController.clear();
    _targetController.clear();
    setState(() {
      _selectedEmoji = '💰';
      _editingId = null;
    });
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final targetText = _targetController.text.trim();
    if (title.isEmpty || targetText.isEmpty) return;
    final target = double.tryParse(targetText);
    if (target == null || target <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }

    final repo = ref.read(goalRepositoryProvider);
    if (_editingId == null) {
      final goal = Goal(
        title: title,
        targetAmount: target,
        currentAmount: 0,
        emoji: _selectedEmoji,
        isCompleted: false,
        createdDate: DateTime.now(),
      );
      await repo.insert(goal);
    } else {
      final existingGoal = await _getGoal(_editingId!);
      if (existingGoal != null) {
        final updated = existingGoal.copyWith(
          title: title,
          targetAmount: target,
          emoji: _selectedEmoji,
        );
        await repo.update(updated);
      }
    }

    ref.invalidate(goalsProvider);
    _clearForm();
  }

  Future<Goal?> _getGoal(int id) async {
    final goals = await ref.read(goalsProvider.future);
    return goals
        .cast<Goal?>()
        .firstWhere((g) => g!.id == id, orElse: () => null);
  }

  Future<void> _addMoney(Goal goal) async {
    final controller = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add to goal'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Amount to save'),
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

      // ---- Create a savings transaction ----
      final transactionRepo = ref.read(transactionRepositoryProvider);
      final transaction = TransactionModel(
        type: 'savings', // new type
        jar: 'goal_${goal.title.toLowerCase()}',
        amount: amount,
        date: DateTime.now(),
        note: 'Saved toward ${goal.title}',
      );
      await transactionRepo.insertTransaction(transaction);

      // Invalidate providers so home screen refreshes
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Form ---
            Text(
              _editingId == null ? 'Create a Goal' : 'Edit Goal',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'What do you want to save for?',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _targetController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Target amount',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            // Emoji picker
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

            // --- Goal List ---
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
                                  child: Text(goal.title,
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
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
                            // Progress bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: progress.clamp(0.0, 1.0),
                                minHeight: 12,
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    goal.isCompleted
                                        ? AppColors.onTrack
                                        : AppColors.primary),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${formatAmount(goal.currentAmount)} of ${formatAmount(goal.targetAmount)}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                if (!goal.isCompleted)
                                  ElevatedButton.icon(
                                    onPressed: () => _addMoney(goal),
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text('Add'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
                                  ),
                              ],
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
