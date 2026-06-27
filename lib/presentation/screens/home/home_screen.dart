import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'health_ring_widget.dart';
import 'jar_row_widget.dart';
import 'home_header.dart';
import 'daily_allowance_card.dart';
import 'goals_preview.dart';
import '../../providers/budget_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/expected_expenses_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/emotional_messages.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../services/month_transition_service.dart';
import '../../widgets/month_transition_dialog.dart';
// The speed dial is placed elsewhere in the UI (e.g., in the main scaffold)

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _checkedMonthTransition = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForNewMonth();
    });
  }

  // ---- Month transition (unchanged) ----
  Future<void> _checkForNewMonth() async {
    if (_checkedMonthTransition) return;
    _checkedMonthTransition = true;

    try {
      final service = MonthTransitionService();
      final isNewMonth = await service.isNewMonth();
      if (isNewMonth && mounted) {
        final currentMonth = _getCurrentMonth();
        final previousMonth = service.getPreviousMonth(currentMonth);
        final surplus =
            await service.calculatePreviousMonthSurplus(previousMonth);
        if (mounted) {
          final result = await showMonthTransitionDialog(
            context,
            previousMonth,
            currentMonth,
            surplus,
          );
          if (result) {
            ref.invalidate(allTransactionsProvider);
            ref.invalidate(expectedExpensesProvider);
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) ref.invalidate(expectedExpensesProvider);
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking for new month: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Month transition error: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  String _getCurrentMonth() {
    final now = MonthTransitionService.debugOverrideDate ?? DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  // ---- DEBUG toggle (unchanged) ----
  void _toggleDebugDate() async {
    try {
      if (MonthTransitionService.debugOverrideDate != null) {
        final simulatedDate = MonthTransitionService.debugOverrideDate!;
        final simulatedMonth =
            '${simulatedDate.year}-${simulatedDate.month.toString().padLeft(2, '0')}';
        final service = MonthTransitionService();
        await service.cleanupTestData(simulatedMonth);
        MonthTransitionService.debugOverrideDate = null;
        _checkedMonthTransition = false;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'DEBUG: Reset to real date and cleaned up $simulatedMonth data')),
          );
          ref.invalidate(allTransactionsProvider);
          ref.invalidate(expectedExpensesProvider);
        }
        return;
      }

      final currentYear = DateTime.now().year;
      final simulatedDate = DateTime(currentYear, 7, 1);
      MonthTransitionService.debugOverrideDate = simulatedDate;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DEBUG: Simulating July 1, $currentYear'),
                Text(
                    'debugOverrideDate: ${MonthTransitionService.debugOverrideDate}'),
                Text('Tap again to reset and clean up test data'),
              ],
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      _checkedMonthTransition = false;
      await _checkForNewMonth();
    } catch (e) {
      debugPrint('Error in _toggleDebugDate: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Simulate error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ---- BUILD ----
  @override
  Widget build(BuildContext context) {
    final budgetAsync = ref.watch(budgetStateProvider);
    final settings = ref.watch(reminderSettingsProvider);
    final survivalMode = settings.survivalMode;

    final isDebugMode = MonthTransitionService.debugOverrideDate != null;

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

        return Column(
          children: [
            const HomeHeader(),
            // DEBUG button
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: ElevatedButton.icon(
                onPressed: _toggleDebugDate,
                icon: Icon(
                  isDebugMode ? Icons.close : Icons.bug_report,
                  size: 16,
                ),
                label: Text(
                  isDebugMode
                      ? 'DEBUG: Reset to Real Date'
                      : 'DEBUG: Simulate July 1',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDebugMode ? Colors.green : Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
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
                        daysLeft: budget.daysLeft,
                        daysLeftPerCategory: budget.daysLeftPerCategory,
                        daysInPeriod: budget.daysInPeriod,
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

// ============================================================
// Safely Spend Section (unchanged)
// ============================================================
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
