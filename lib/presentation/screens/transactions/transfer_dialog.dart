import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../providers/transaction_provider.dart';

class TransferDialog extends ConsumerStatefulWidget {
  final List<String> categories;

  const TransferDialog({super.key, required this.categories});

  @override
  ConsumerState<TransferDialog> createState() => _TransferDialogState();
}

class _TransferDialogState extends ConsumerState<TransferDialog> {
  String? _fromCategory;
  String? _toCategory;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Transfer Between Categories'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _fromCategory,
              decoration: const InputDecoration(
                labelText: 'From Category',
                border: OutlineInputBorder(),
              ),
              items: widget.categories
                  .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _fromCategory = value;
                  // Clear toCategory if it's the same as fromCategory
                  if (_toCategory == _fromCategory) {
                    _toCategory = null;
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _toCategory,
              decoration: const InputDecoration(
                labelText: 'To Category',
                border: OutlineInputBorder(),
              ),
              items: widget.categories
                  .where((cat) => cat != _fromCategory)
                  .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                  .toList(),
              onChanged: (value) => setState(() => _toCategory = value),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '₱ ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
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
          onPressed: _performTransfer,
          child: const Text('Transfer',
              style: TextStyle(color: AppColors.primary)),
        ),
      ],
    );
  }

  Future<void> _performTransfer() async {
    final amount = double.tryParse(_amountController.text);

    if (_fromCategory == null || _toCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both categories')),
      );
      return;
    }

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    final repo = ref.read(transactionRepositoryProvider);
    await repo.transferBetweenCategories(
      fromCategory: _fromCategory!,
      toCategory: _toCategory!,
      amount: amount,
      date: DateTime.now(),
      note: _noteController.text.isEmpty ? null : _noteController.text,
    );

    ref.invalidate(allTransactionsProvider);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Transferred ₱${amount.toStringAsFixed(0)} from $_fromCategory to $_toCategory'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }
}
