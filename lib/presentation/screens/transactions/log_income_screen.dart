import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/transaction_provider.dart';
import '../../../data/models/transaction_model.dart';
import '../../providers/budget_provider.dart';
import '../../widgets/common/ad_banner_widget.dart';
import '../../widgets/common/app_menu_button.dart';

class LogIncomeScreen extends ConsumerStatefulWidget {
  const LogIncomeScreen({super.key});

  @override
  ConsumerState<LogIncomeScreen> createState() => _LogIncomeScreenState();
}

class _LogIncomeScreenState extends ConsumerState<LogIncomeScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  // Dropdown state
  String _selectedSource = 'Salary';
  final List<String> _incomeSources = [
    'Salary',
    'Freelance',
    'Gift',
    'Refund',
    'Other'
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveIncome() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) return;
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    final transaction = TransactionModel(
      type: 'income',
      jar: 'income',
      amount: amount,
      date: DateTime.now(),
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      source: _selectedSource, // store selected source
    );

    final repo = ref.read(transactionRepositoryProvider);
    await repo.insertTransaction(transaction);
    ref.invalidate(jarSummariesProvider);
    ref.invalidate(allTransactionsProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Income added! You’re moving forward.'),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Income', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: const [AppMenuButton()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('How much did you receive?',
                style: TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: '₱ 0.00',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            // Dropdown for source
            const Text('Source',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedSource,
              decoration: InputDecoration(
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              items: _incomeSources.map((source) {
                return DropdownMenuItem(value: source, child: Text(source));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedSource = value;
                  });
                }
              },
            ),
            const SizedBox(height: 20),

            // Optional note field (still available for extra details)
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: 'Additional note (optional)',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                onPressed: _saveIncome,
                child: const Text('Done', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 12),
            const AdBannerWidget(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
