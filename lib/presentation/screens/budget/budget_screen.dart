import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/transaction_model.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/common/lifebudget_scaffold.dart';
import '../../../core/utils/number_formatter.dart';
import '../../widgets/common/app_menu_button.dart';
import '../../../services/month_transition_service.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

              // Transaction list
              Expanded(
                child: transactions.isEmpty
                    ? const Center(
                        child: Text(
                          'No transactions yet.\nTap + to add one!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 16, color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final t = transactions[index];
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
