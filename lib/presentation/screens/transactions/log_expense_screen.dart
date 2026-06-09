import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/transaction_model.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/expected_expenses_provider.dart';
import '../../widgets/common/ad_banner_widget.dart';
import '../../widgets/common/app_menu_button.dart';
import '../../providers/safely_spend_provider.dart';
import '../../../core/utils/number_formatter.dart';

class LogExpenseScreen extends ConsumerStatefulWidget {
  const LogExpenseScreen({super.key});

  @override
  ConsumerState<LogExpenseScreen> createState() => _LogExpenseScreenState();
}

class _LogExpenseScreenState extends ConsumerState<LogExpenseScreen> {
  final _amountController = TextEditingController();
  String? _selectedJar;
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveExpense() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) return;
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    if (_selectedJar == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    // --- Safely Spend validation ---
    if (_selectedJar!.toLowerCase() == 'safely spend') {
      final remaining = await ref.read(safelySpendRemainingProvider.future);
      if (amount > remaining) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'You only have ${formatAmount(remaining)} left for safely spend this month.',
            ),
            backgroundColor: AppColors.critical,
          ),
        );
        return;
      }
    }

    // Proceed with saving...
    final transaction = TransactionModel(
      type: 'expense',
      jar: _selectedJar!.toLowerCase(),
      amount: amount,
      date: DateTime.now(),
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );

    final repo = ref.read(transactionRepositoryProvider);
    await repo.insertTransaction(transaction);

    ref.invalidate(jarSummariesProvider);
    ref.invalidate(allTransactionsProvider);
    ref.invalidate(expectedExpensesProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Got it! You’re doing great.'),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expectedExpensesProvider);

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Log an expense', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: const [AppMenuButton()],
      ),
      body: expensesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (expenses) {
          // --- Deduplicate titles (keep first occurrence order) ---
          final uniqueTitles = <String>[];
          final seen = <String>{};
          for (final e in expenses) {
            final title = e.title;
            if (seen.add(title)) uniqueTitles.add(title);
          }

          // If no categories exist, show a helpful message
          if (uniqueTitles.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'No expense categories found.\nAdd some in Profile → Your Expected Expenses.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            );
          }

          // Ensure selectedJar is valid
          if (_selectedJar == null || !uniqueTitles.contains(_selectedJar)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _selectedJar = uniqueTitles.first;
                });
              }
            });
          }

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('How much did you spend?',
                    style: TextStyle(fontSize: 18)),
                const SizedBox(height: 12),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: '₱ 0.00',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                const Text('What was it for?', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedJar,
                  items: uniqueTitles.map((title) {
                    return DropdownMenuItem(
                      value: title,
                      child: Text(title),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedJar = value);
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  hint: const Text('Select a category'),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    hintText: 'Any notes? (optional)',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _saveExpense,
                    child: const Text('Done', style: TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(height: 12),
                const AdBannerWidget(),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
