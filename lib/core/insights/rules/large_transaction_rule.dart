import '../insight_model.dart';
import '../insight_rule.dart';

/// Flags single expense transactions that exceed 30% of a jar's monthly budget.
class LargeTransactionRule extends InsightRule {
  @override
  List<Insight> analyze(InsightContext ctx) {
    if (ctx.totalIncome <= 0 || ctx.allocations.isEmpty) return [];

    final insights = <Insight>[];

    // Build jar budgets
    final jarBudget = <String, double>{};
    for (final alloc in ctx.allocations) {
      jarBudget[alloc.jarName.toLowerCase()] =
          ctx.totalIncome * (alloc.percentage / 100);
    }

    // Find large single transactions (current month only)
    for (final t in ctx.transactions) {
      if (t.type != 'expense') continue;
      final jarKey = t.jar.toLowerCase();
      final budget = jarBudget[jarKey] ?? 0;
      if (budget <= 0) continue;

      final share = t.amount / budget;
      if (share >= 0.3) {
        final pct = (share * 100).round();
        insights.add(Insight(
          type: share >= 0.5 ? InsightType.warning : InsightType.tip,
          title: 'Large ${t.jar} expense',
          message:
              'A single ${t.jar} expense of \$${t.amount.toStringAsFixed(0)} used $pct% of its monthly budget${t.note != null ? ' ("${t.note}")' : ''}.',
          action: share >= 0.5
              ? 'This single purchase ate half your ${t.jar} budget. Plan ahead for similar expenses.'
              : 'Big purchases are okay if planned. Make sure remaining ${t.jar} budget covers your needs.',
          metric: '\$${t.amount.toStringAsFixed(0)} ($pct%)',
          jarName: t.jar,
        ));
      }
    }

    return insights;
  }
}
