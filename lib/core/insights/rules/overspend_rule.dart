import '../insight_model.dart';
import '../insight_rule.dart';

/// Fires when a jar's actual spending exceeds its allocated percentage of income.
class OverspendRule extends InsightRule {
  @override
  List<Insight> analyze(InsightContext ctx) {
    if (ctx.totalIncome <= 0) return [];

    final insights = <Insight>[];

    for (final alloc in ctx.allocations) {
      final jarKey = alloc.jarName.toLowerCase();
      final spent = ctx.jarSpent[jarKey] ?? 0;
      final budgeted = ctx.totalIncome * (alloc.percentage / 100);

      if (budgeted <= 0) continue;
      final ratio = spent / budgeted;

      if (ratio > 1.0) {
        final percentUsed = (ratio * 100).round();
        insights.add(Insight(
          type: ratio > 1.5 ? InsightType.warning : InsightType.warning,
          title: '${alloc.jarName} overspent',
          message:
              'You\'ve used $percentUsed% of your ${alloc.jarName} budget (${_fmt(spent)} / ${_fmt(budgeted)}).',
          action: ratio > 1.5
              ? 'Consider pausing ${alloc.jarName} spending for the rest of the month.'
              : 'Try to keep ${alloc.jarName} spending minimal this week.',
          metric: '$percentUsed%',
          jarName: alloc.jarName,
        ));
      }
    }

    return insights;
  }

  String _fmt(double v) => '\$${v.toStringAsFixed(0)}';
}
