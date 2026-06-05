import '../insight_model.dart';
import '../insight_rule.dart';

/// Checks if savings goals are on track based on daily_amount and days elapsed.
class GoalPacingRule extends InsightRule {
  @override
  List<Insight> analyze(InsightContext ctx) {
    final insights = <Insight>[];

    for (final goal in ctx.goals) {
      if (goal.isCompleted) continue;
      if (goal.dailyAmount <= 0 || goal.targetAmount <= 0) continue;

      final daysSinceCreated =
          DateTime.now().difference(goal.createdDate).inDays.clamp(1, 365);

      // Expected progress: dailyAmount × days since creation
      final expectedAmount = goal.dailyAmount * daysSinceCreated;
      final remaining = goal.targetAmount - goal.currentAmount;

      // Behind pace: saved less than expected
      if (goal.currentAmount < expectedAmount * 0.75 && daysSinceCreated > 3) {
        final shortfall = expectedAmount - goal.currentAmount;
        insights.add(Insight(
          type: InsightType.warning,
          title: '${goal.emoji} "${goal.title}" is behind pace',
          message:
              'You\'ve saved \$${goal.currentAmount.toStringAsFixed(0)} so far, but at \$${goal.dailyAmount.toStringAsFixed(2)}/day you should have ~\$${expectedAmount.toStringAsFixed(0)} by now.',
          action:
              'Try increasing your daily contribution by \$${(shortfall / (ctx.daysInMonth - ctx.daysElapsed).clamp(1, 999)).toStringAsFixed(2)} to catch up this month.',
          metric: '\$${shortfall.toStringAsFixed(0)} behind',
        ));
      }

      // Ahead of pace — positive reinforcement
      else if (goal.currentAmount > expectedAmount * 1.25 &&
          daysSinceCreated > 3) {
        insights.add(Insight(
          type: InsightType.achievement,
          title: '${goal.emoji} "${goal.title}" ahead of schedule!',
          message:
              'You\'ve saved \$${goal.currentAmount.toStringAsFixed(0)} — that\'s ahead of the expected \$${expectedAmount.toStringAsFixed(0)}.',
          action:
              'Great discipline! Keep this pace and you\'ll hit your goal early.',
          metric:
              '${((goal.currentAmount / expectedAmount) * 100).round()}% of expected',
        ));
      }

      // Almost done — motivation nudge
      if (remaining > 0 && remaining <= goal.dailyAmount * 7) {
        final daysToGo = (remaining / goal.dailyAmount).ceil();
        insights.add(Insight(
          type: InsightType.tip,
          title: '${goal.emoji} "${goal.title}" is almost there',
          message:
              'Only \$${remaining.toStringAsFixed(0)} left! At your daily rate, you\'ll reach it in ~$daysToGo day${daysToGo == 1 ? '' : 's'}.',
          action: 'Stay consistent — the finish line is in sight.',
          metric: '$daysToGo day${daysToGo == 1 ? '' : 's'} to go',
        ));
      }
    }

    return insights;
  }
}
