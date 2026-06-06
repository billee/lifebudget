import 'insight_model.dart';
import 'insight_rule.dart';
import 'rules/overspend_rule.dart';
import 'rules/spending_trend_rule.dart';
import 'rules/emotional_spending_rule.dart';
import 'rules/goal_pacing_rule.dart';
import 'rules/jar_imbalance_rule.dart';
import 'rules/large_transaction_rule.dart';
import 'rules/expected_vs_actual_rule.dart';
import 'rules/streak_rule.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/budget_plan_model.dart';
import '../../data/models/expected_expense_model.dart';
import '../../data/models/goal_model.dart';
import '../../data/models/slip_up_model.dart';
import '../../data/models/journal_entry_model.dart';

/// Orchestrates all rules and produces insights.
class RulesEngine {
  final List<InsightRule> _rules;

  RulesEngine({
    required Map<String, double> lastMonthJarSpent,
  }) : _rules = [
          OverspendRule(),
          SpendingTrendRule(lastMonthJarSpent: lastMonthJarSpent),
          EmotionalSpendingRule(),
          GoalPacingRule(),
          JarImbalanceRule(),
          LargeTransactionRule(),
          ExpectedVsActualRule(),
          StreakRule(),
        ];

  /// Run all rules against the given data and return collected insights.
  List<Insight> generate({
    required List<TransactionModel> transactions,
    required List<JarAllocation> allocations,
    required List<ExpectedExpense> expectedExpenses,
    required List<Goal> goals,
    required List<SlipUp> slipUps,
    required List<JournalEntry> journalEntries,
  }) {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysElapsed = now.difference(firstDay).inDays + 1;

    // Compute totals — current month only
    double totalIncome = 0;
    final Map<String, double> jarSpent = {};
    final Map<String, double> expenseOnlySpent = {};
    final currentMonthStart = DateTime(now.year, now.month, 1);
    final currentMonthTxns = <TransactionModel>[];

    for (final t in transactions) {
      // Skip transactions from previous months
      if (t.date.isBefore(currentMonthStart)) continue;
      currentMonthTxns.add(t);

      if (t.type == 'income') {
        totalIncome += t.amount;
      } else {
        var jar = t.jar.toLowerCase();
        // Normalize legacy goal jar names: 'goal_tv' → 'tv'
        if (jar.startsWith('goal_')) jar = jar.substring(5);
        jarSpent[jar] = (jarSpent[jar] ?? 0) + t.amount;
        // Track actual expenses only (exclude savings)
        if (t.type == 'expense') {
          expenseOnlySpent[jar] = (expenseOnlySpent[jar] ?? 0) + t.amount;
        }
      }
    }

    final ctx = InsightContext(
      transactions: currentMonthTxns,
      allocations: allocations,
      expectedExpenses: expectedExpenses,
      goals: goals,
      slipUps: slipUps,
      journalEntries: journalEntries,
      totalIncome: totalIncome,
      jarSpent: jarSpent,
      expenseOnlySpent: expenseOnlySpent,
      daysElapsed: daysElapsed,
      daysInMonth: daysInMonth,
    );

    // Run all rules, collecting insights
    final insights = <Insight>[];
    for (final rule in _rules) {
      try {
        insights.addAll(rule.analyze(ctx));
      } catch (_) {
        // Silently skip broken rules so the rest still work.
      }
    }

    // Sort: warnings first, then tips, then achievements
    insights.sort((a, b) => _priority(a.type) - _priority(b.type));

    return insights;
  }

  int _priority(InsightType t) {
    switch (t) {
      case InsightType.warning:
        return 0;
      case InsightType.tip:
        return 1;
      case InsightType.achievement:
        return 2;
    }
  }
}
