import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../data/models/goal_model.dart';
import '../../providers/goal_provider.dart';
import '../../providers/expected_expenses_provider.dart';

class GoalsPreview extends ConsumerWidget {
  const GoalsPreview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsProvider);
    final expensesAsync = ref.watch(expectedExpensesProvider);

    // Build a map of title (lowercase) -> daily amount from expected expenses
    final expectedDailyAmounts = <String, double>{};
    for (final exp in expensesAsync.valueOrNull ?? []) {
      if (exp.frequency == 'daily') {
        expectedDailyAmounts[exp.title.toLowerCase().trim()] = exp.amount;
      }
    }

    return goalsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (goals) {
        final activeGoals = goals.where((g) => !g.isCompleted).toList();
        if (activeGoals.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your Goals',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 150, // enough room for all content
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: activeGoals.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final goal = activeGoals[index];
                  final progress = goal.progressPercent;
                  // Use ExpectedExpense amount if available, otherwise use Goal's dailyAmount
                  final dailyAmount =
                      expectedDailyAmounts[goal.title.toLowerCase().trim()] ??
                          goal.dailyAmount;
                  return GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 160,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(goal.emoji,
                                  style: const TextStyle(fontSize: 22)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(goal.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Save ${formatAmount(dailyAmount)}/day',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Target: ${formatAmount(goal.targetAmount)}',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          // Progress bar with visible track
                          Container(
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: progress.clamp(0.0, 1.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${formatAmount(goal.currentAmount)} / ${formatAmount(goal.targetAmount)}',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary),
                              ),
                              Text(
                                '${(progress * 100).toInt()}%',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
