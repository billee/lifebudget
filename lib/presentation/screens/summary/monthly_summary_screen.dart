import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/budget_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/common/lifebudget_scaffold.dart';
import '../../widgets/common/app_menu_button.dart';

class MonthlySummaryScreen extends ConsumerWidget {
  const MonthlySummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetAsync = ref.watch(budgetStateProvider);
    final transactionsAsync = ref.watch(allTransactionsProvider);

    return LifeBudgetScaffold(
      appBar: AppBar(
        title: const Text('Monthly Summary',
            style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: const [AppMenuButton()],
      ),
      body: budgetAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (budget) {
          return transactionsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
            data: (transactions) {
              return _buildSummary(context, budget, transactions);
            },
          );
        },
      ),
    );
  }

  Widget _buildSummary(
      BuildContext context, dynamic budget, List transactions) {
    final totalIncome = budget.effectiveIncome;
    final totalExpenses = budget.actualExpensesTotal;
    final savings = totalIncome - totalExpenses;
    final savingsRate = totalIncome > 0 ? (savings / totalIncome * 100) : 0;

    // Group expenses by category
    final categoryExpenses = <String, double>{};
    for (final t in transactions.where((t) => t.type == 'expense')) {
      final category = t.category;
      categoryExpenses[category] = (categoryExpenses[category] ?? 0) + t.amount;
    }

    // Sort by amount (descending)
    final sortedCategories = categoryExpenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          _buildSummaryCard(
            title: 'Total Income',
            amount: totalIncome,
            icon: Icons.arrow_downward,
            color: AppColors.onTrack,
          ),
          const SizedBox(height: 12),
          _buildSummaryCard(
            title: 'Total Expenses',
            amount: totalExpenses,
            icon: Icons.arrow_upward,
            color: AppColors.critical,
          ),
          const SizedBox(height: 12),
          _buildSummaryCard(
            title: 'Savings',
            amount: savings,
            icon: savings >= 0 ? Icons.check_circle : Icons.warning,
            color: savings >= 0 ? AppColors.onTrack : AppColors.critical,
          ),
          const SizedBox(height: 12),
          _buildSavingsRateCard(savingsRate),
          const SizedBox(height: 24),

          // Spending by category
          const Text(
            'Spending by Category',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (sortedCategories.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No expenses this month',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            ...sortedCategories.map((entry) => _buildCategoryRow(
                  entry.key,
                  entry.value,
                  totalExpenses,
                )),

          const SizedBox(height: 24),

          // Key insights
          _buildInsightsSection(budget, totalIncome, totalExpenses, savings),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₱${amount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsRateCard(double savingsRate) {
    final isPositive = savingsRate >= 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPositive
              ? [AppColors.onTrack, AppColors.onTrack.withOpacity(0.7)]
              : [AppColors.critical, AppColors.critical.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Savings Rate',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${savingsRate.toStringAsFixed(1)}%',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isPositive ? 'Great job saving!' : 'Spending more than income',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(String category, double amount, double total) {
    final percentage = total > 0 ? (amount / total * 100) : 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  category,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Text(
                '₱${amount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: AppColors.background,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${percentage.toStringAsFixed(1)}% of total',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsSection(
      dynamic budget, double income, double expenses, double savings) {
    final insights = <String>[];

    // Generate insights
    if (savings > 0) {
      insights.add('✅ You saved ₱${savings.toStringAsFixed(0)} this month!');
    } else if (savings < 0) {
      insights.add(
          '⚠️ You spent ₱${(-savings).toStringAsFixed(0)} more than your income');
    }

    if (expenses > income * 0.9) {
      insights.add('💡 Consider reducing expenses to improve savings');
    }

    if (budget.expectedExpenses.isNotEmpty) {
      final dailyExpenses =
          budget.expectedExpenses.where((e) => e.frequency == 'daily').toList();
      if (dailyExpenses.isNotEmpty) {
        insights.add(
            '📊 You have ${dailyExpenses.length} daily budget${dailyExpenses.length == 1 ? '' : 's'} to track');
      }
    }

    if (budget.carryover > 0) {
      insights.add(
          '💰 You have ₱${budget.carryover.toStringAsFixed(0)} carryover from last month');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Key Insights',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (insights.isEmpty)
            const Text(
              'Add more transactions to see insights!',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            )
          else
            ...insights.map((insight) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    insight,
                    style: const TextStyle(fontSize: 13),
                  ),
                )),
        ],
      ),
    );
  }
}
