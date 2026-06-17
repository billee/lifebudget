import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/transaction_model.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/common/lifebudget_scaffold.dart';
import '../../../core/utils/number_formatter.dart';
import '../../widgets/common/app_menu_button.dart';
import '../../../services/month_transition_service.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _filterCategory;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> _getUniqueCategories(List<TransactionModel> transactions) {
    final categories = <String>{};
    for (final t in transactions) {
      if (t.type == 'income') {
        categories.add('Income');
      } else {
        categories.add(t.jar);
      }
    }
    return categories.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(allTransactionsProvider);
    final summariesAsync = ref.watch(jarSummariesProvider);

    return LifeBudgetScaffold(
      appBar: AppBar(
        title:
            const Text('Transactions', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: const [AppMenuButton()],
      ),
      body: transactionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (allTransactions) {
          // Filter transactions by current month using full date comparison
          final now =
              MonthTransitionService.debugOverrideDate ?? DateTime.now();
          final transactions = allTransactions.where((t) {
            final date = t.date;
            // Match by year AND month for consistency
            return date.year == now.year && date.month == now.month;
          }).toList();

          final summaries = summariesAsync.valueOrNull ?? {};

          // Calculate totals from filtered transactions
          double totalIncome = 0;
          for (final t in transactions) {
            if (t.type == 'income') {
              totalIncome += t.amount;
            }
          }

          double totalSpent = 0;
          for (final t in transactions) {
            if (t.type == 'expense' || t.type == 'savings') {
              totalSpent += t.amount;
            }
          }

          // Filter transactions based on search and category
          final filteredTransactions = transactions.where((t) {
            final matchesSearch = _searchQuery.isEmpty ||
                t.jar.toLowerCase().contains(_searchQuery) ||
                (t.note?.toLowerCase().contains(_searchQuery) ?? false) ||
                (t.source?.toLowerCase().contains(_searchQuery) ?? false);
            final matchesCategory = _filterCategory == null ||
                (_filterCategory == 'Income' && t.type == 'income') ||
                (_filterCategory != 'Income' && t.jar == _filterCategory);
            return matchesSearch && matchesCategory;
          }).toList();

          return Column(
            children: [
              // Summary cards – side by side
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: 'Income',
                        amount: totalIncome,
                        color: AppColors.onTrack,
                        icon: Icons.arrow_downward,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        title: 'Spent',
                        amount: totalSpent,
                        color: AppColors.critical,
                        icon: Icons.arrow_upward,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Search bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search transactions...',
                    prefixIcon: const Icon(Icons.search,
                        color: AppColors.textSecondary),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear,
                                color: AppColors.textSecondary),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),

              // Filter chips
              if (transactions.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: _filterCategory == null,
                        onSelected: (selected) {
                          setState(() {
                            _filterCategory = null;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      ..._getUniqueCategories(transactions)
                          .map((category) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(category),
                                  selected: _filterCategory == category,
                                  onSelected: (selected) {
                                    setState(() {
                                      _filterCategory =
                                          selected ? category : null;
                                    });
                                  },
                                ),
                              )),
                    ],
                  ),
                ),

              const Divider(height: 1),

              // Transaction list
              Expanded(
                child: filteredTransactions.isEmpty
                    ? const Center(
                        child: Text(
                          'No transactions yet.\nTap + to add one!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 16, color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredTransactions.length,
                        itemBuilder: (context, index) {
                          final t = filteredTransactions[index];
                          final isIncome = t.type == 'income';
                          final mainText = isIncome
                              ? (t.source ?? 'Income')
                              : t.jar[0].toUpperCase() + t.jar.substring(1);
                          final hasNote =
                              t.note != null && t.note!.trim().isNotEmpty;

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  isIncome
                                      ? Icons.add_circle_outline
                                      : Icons.remove_circle_outline,
                                  color: isIncome
                                      ? AppColors.onTrack
                                      : AppColors.critical,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  isIncome
                                      ? '+${t.amount.toStringAsFixed(0)}'
                                      : '-${t.amount.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        mainText,
                                        style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (hasNote) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          t.note!,
                                          style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 12,
                                              fontStyle: FontStyle.italic),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Text(
                                  '${t.date.month}/${t.date.day}',
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined,
                                      size: 18, color: AppColors.primary),
                                  onPressed: () =>
                                      _showEditDialog(context, ref, t),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      size: 18, color: AppColors.critical),
                                  onPressed: () =>
                                      _showDeleteDialog(context, ref, t),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteDialog(
      BuildContext context, WidgetRef ref, TransactionModel t) {
    // Check if this is a transfer transaction
    final isTransfer = t.note != null &&
        (t.note!.contains('Transfer to') || t.note!.contains('Transfer from'));

    if (isTransfer) {
      _showTransferDeleteDialog(context, ref, t);
    } else {
      _showRegularDeleteDialog(context, ref, t);
    }
  }

  void _showRegularDeleteDialog(
      BuildContext context, WidgetRef ref, TransactionModel t) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text(
            'Are you sure you want to delete this ${t.type}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final repo = ref.read(transactionRepositoryProvider);
              await repo.deleteTransaction(t.id!);
              ref.invalidate(allTransactionsProvider);
              if (context.mounted) {
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Delete',
                style: TextStyle(color: AppColors.critical)),
          ),
        ],
      ),
    );
  }

  void _showTransferDeleteDialog(
      BuildContext context, WidgetRef ref, TransactionModel t) {
    // Find the paired transfer transaction
    final transactionsAsync = ref.read(allTransactionsProvider);
    TransactionModel? pairedTransaction;

    transactionsAsync.whenData((transactions) {
      pairedTransaction = _findPairedTransfer(t, transactions);
    });

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Transfer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This transaction is part of a transfer.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            const Text(
              'To keep your budgets accurate, both transactions should be deleted together.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            if (pairedTransaction != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Paired transaction:',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${pairedTransaction!.jar}: ${pairedTransaction!.amount > 0 ? "+" : ""}${pairedTransaction!.amount.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 13),
                    ),
                    if (pairedTransaction!.note != null)
                      Text(
                        pairedTransaction!.note!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final repo = ref.read(transactionRepositoryProvider);
              // Delete both transactions
              await repo.deleteTransaction(t.id!);
              if (pairedTransaction != null) {
                await repo.deleteTransaction(pairedTransaction!.id!);
              }
              ref.invalidate(allTransactionsProvider);
              if (context.mounted) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Transfer cancelled successfully'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              }
            },
            child: const Text('Delete Both',
                style: TextStyle(color: AppColors.critical)),
          ),
        ],
      ),
    );
  }

  TransactionModel? _findPairedTransfer(
      TransactionModel t, List<TransactionModel> transactions) {
    // Determine if this is "Transfer to" or "Transfer from"
    final isTransferTo = t.note?.contains('Transfer to') ?? false;
    final isTransferFrom = t.note?.contains('Transfer from') ?? false;

    if (!isTransferTo && !isTransferFrom) return null;

    // Extract the category name from the note
    // "Transfer to Food" -> "Food"
    // "Transfer from Commute" -> "Commute"
    final noteParts = t.note!.split(' ');
    final targetCategory = noteParts.length > 2 ? noteParts[2] : null;

    if (targetCategory == null) return null;

    // Look for the paired transaction:
    // - Same date
    // - Opposite amount sign
    // - Complementary note
    for (final other in transactions) {
      if (other.id == t.id) continue; // Skip self

      // Check same date
      if (other.date.year != t.date.year ||
          other.date.month != t.date.month ||
          other.date.day != t.date.day) {
        continue;
      }

      // Check opposite amount
      if ((t.amount + other.amount).abs() > 0.01) {
        continue; // Amounts should cancel out
      }

      // Check complementary note
      if (other.note == null) continue;

      if (isTransferTo &&
          other.note!.contains('Transfer from $targetCategory')) {
        return other;
      }
      if (isTransferFrom &&
          other.note!.contains('Transfer to $targetCategory')) {
        return other;
      }
    }

    return null;
  }

  void _showEditDialog(
      BuildContext context, WidgetRef ref, TransactionModel t) {
    final amountController = TextEditingController(text: t.amount.toString());
    final noteController = TextEditingController(text: t.note ?? '');
    final isIncome = t.type == 'income';
    DateTime selectedDate = t.date;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('Edit ${isIncome ? "Income" : "Expense"}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixText: '₱ ',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: Text(
                      '${selectedDate.month}/${selectedDate.day}/${selectedDate.year}'),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => selectedDate = picked);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please enter a valid amount')),
                  );
                  return;
                }

                final updated = TransactionModel(
                  id: t.id,
                  type: t.type,
                  jar: t.jar,
                  amount: amount,
                  date: selectedDate,
                  note:
                      noteController.text.isEmpty ? null : noteController.text,
                  source: t.source,
                );

                final repo = ref.read(transactionRepositoryProvider);
                await repo.updateTransaction(updated);
                ref.invalidate(allTransactionsProvider);
                if (context.mounted) {
                  Navigator.of(ctx).pop();
                }
              },
              child: const Text('Save',
                  style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(title,
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              formatAmount(amount),
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
