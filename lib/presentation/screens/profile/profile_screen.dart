import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/expected_expense_model.dart';
import '../../providers/expected_expenses_provider.dart';
import '../../widgets/common/lifebudget_scaffold.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _titleController = TextEditingController();
  String _frequency = 'monthly';
  final _amountController = TextEditingController();
  int? _editingId; // if non-null, we are editing an existing item

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
      // Insert new
      final expense = ExpectedExpense(
        title: title,
        frequency: _frequency,
        amount: amount,
        month: month,
      );
      await repo.insert(expense);
    } else {
      // Update existing
      final expense = ExpectedExpense(
        id: _editingId,
        title: title,
        frequency: _frequency,
        amount: amount,
        month: month,
      );
      await repo.update(expense);
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

  Future<void> _delete(int id) async {
    final repo = ref.read(expectedExpenseRepositoryProvider);
    await repo.delete(id);
    ref.invalidate(expectedExpensesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expectedExpensesProvider);

    return LifeBudgetScaffold(
      appBar: AppBar(
        title: const Text('Expected Expenses',
            style: TextStyle(color: Colors.white)),
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
              items: ['daily', 'weekly', 'monthly']
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
                labelText: 'Amount (₱)',
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
                    onPressed: _clearForm,
                    child: const Text('Cancel'),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // --- List of expected expenses ---
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
                          '${exp.frequency[0].toUpperCase()}${exp.frequency.substring(1)} — ₱${exp.amount.toStringAsFixed(0)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit,
                                  color: AppColors.primary),
                              onPressed: () => _edit(exp),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: AppColors.critical),
                              onPressed: () => _delete(exp.id!),
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
