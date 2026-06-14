import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'health_ring_widget.dart';
import 'jar_row_widget.dart';
import 'focus_card_widget.dart';
import 'home_header.dart';
import 'daily_allowance_card.dart';
import 'goals_preview.dart';
import '../../providers/budget_provider.dart';
import '../../providers/settings_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/emotional_messages.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../core/engine/budget_engine.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetAsync = ref.watch(budgetStateProvider);
    final settings = ref.watch(reminderSettingsProvider);
    final survivalMode = settings.survivalMode;

    return budgetAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (budget) {
        final dailyAllowance =
            budget.currentDailyAllowance.clamp(0.0, double.infinity);
        final totalIncome = budget.totalActualIncome;
        final totalSpent =
            budget.actualSpentPerCategory.values.fold(0.0, (a, b) => a + b) +
                budget.safelySpendSpent;
        final remaining =
            (totalIncome - totalSpent).clamp(0.0, double.infinity);
        final daysLeft = budget.daysLeft;

        // Emotional message (simplified – you can use budget to detect overspending)
        String statusLine = getRandomMessage('on_track');
        // (Optional: derive from budget.plannedUpToTodayPerCategory vs actualSpentPerCategory)

        return Column(
          children: [
            const HomeHeader(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(budgetStateProvider);
                },
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HealthRingWidget(
                        leftAmount: remaining,
                        totalBudget: totalIncome,
                      ),
                      const SizedBox(height: 16),
                      DailyAllowanceCard(
                        dailyAllowance: dailyAllowance,
                        daysLeft: daysLeft,
                      ),
                      const SizedBox(height: 16),
                      JarRowWidget(
                        expectedExpenses: budget.expectedExpenses,
                        jarSpent: budget.actualSpentPerCategory,
                        plannedTotalPerCategory: budget.plannedTotalPerCategory,
                      ),
                      const SizedBox(height: 24),
                      const GoalsPreview(),
                      const SizedBox(height: 24),
                      if (!survivalMode && budget.remainingSafelySpend > 0)
                        _SafelySpendSection(
                          budget: budget.totalSafelySpendBudget,
                          spent: budget.safelySpendSpent,
                          daysLeft: daysLeft,
                          dailyAllowance: dailyAllowance,
                        ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SafelySpendSection extends StatelessWidget {
  final double budget;
  final double spent;
  final int daysLeft;
  final double dailyAllowance;

  const _SafelySpendSection({
    required this.budget,
    required this.spent,
    required this.daysLeft,
    required this.dailyAllowance,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = budget - spent;
    final progress = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet,
                  size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Safely Spend',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary),
              ),
              const Spacer(),
              Text(
                '${formatAmount(dailyAllowance)}/day',
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: Colors.grey.shade300,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Spent: ${formatAmount(spent)}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
              Text('Budget: ${formatAmount(budget)}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Remaining: ${formatAmount(remaining > 0 ? remaining : 0)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: remaining > 0 ? AppColors.onTrack : AppColors.critical,
            ),
          ),
        ],
      ),
    );
  }
}
