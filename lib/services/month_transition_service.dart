import 'package:flutter/foundation.dart';
import '../data/database/database_helper.dart';
import '../data/database/database_constants.dart';
import '../data/models/transaction_model.dart';
import '../data/models/expected_expense_model.dart';
import '../data/repositories/transaction_repository.dart';
import '../data/repositories/expected_expense_repository.dart';
import '../data/repositories/goal_repository.dart';

/// Service to handle month transitions (e.g., June → July)
class MonthTransitionService {
  final TransactionRepository _transactionRepo = TransactionRepository();
  final ExpectedExpenseRepository _expenseRepo = ExpectedExpenseRepository();
  final GoalRepository _goalRepo = GoalRepository();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // DEBUG: Override current date for testing (set to null for production)
  static DateTime? debugOverrideDate;

  /// Check if we've entered a new month since last recorded data
  Future<bool> isNewMonth() async {
    final lastMonth = await _getLastRecordedMonth();
    if (lastMonth == null) return false; // No data yet

    final currentMonth = _getCurrentMonth();
    return lastMonth != currentMonth;
  }

  /// Get the last month that has recorded transactions or expenses
  Future<String?> _getLastRecordedMonth() async {
    final db = await _dbHelper.database;

    // Check transactions
    final transactions = await db.query(
      DatabaseConstants.transactionsTable,
      orderBy: '${DatabaseConstants.colDate} DESC',
      limit: 1,
    );

    // Check expected expenses
    final expenses = await db.query(
      DatabaseConstants.expectedExpensesTable,
      orderBy: 'month DESC',
      limit: 1,
    );

    String? lastMonth;

    if (transactions.isNotEmpty) {
      final date = DateTime.parse(
          transactions.first[DatabaseConstants.colDate] as String);
      lastMonth = '${date.year}-${date.month.toString().padLeft(2, '0')}';
    }

    if (expenses.isNotEmpty) {
      final expMonth = expenses.first['month'] as String;
      if (lastMonth == null || expMonth.compareTo(lastMonth) > 0) {
        lastMonth = expMonth;
      }
    }

    return lastMonth;
  }

  /// Get current month in YYYY-MM format
  String _getCurrentMonth() {
    final now = debugOverrideDate ?? DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  /// Calculate surplus from previous month (income - total spent)
  Future<double> calculatePreviousMonthSurplus(String previousMonth) async {
    final db = await _dbHelper.database;

    // Parse the previous month to get the month number
    final parts = previousMonth.split('-');
    final monthNum = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;

    // In debug mode, match by month only (ignore year)
    // In production, match by full YYYY-MM
    final isDebugMode = debugOverrideDate != null;

    String whereClause;
    List<dynamic> params;

    if (isDebugMode && monthNum > 0) {
      // Match by month number only
      whereClause =
          "CAST(strftime('%m', ${DatabaseConstants.colDate}) AS INTEGER) = ?";
      params = [monthNum];
    } else {
      // Match by full YYYY-MM
      whereClause = "strftime('%Y-%m', ${DatabaseConstants.colDate}) = ?";
      params = [previousMonth];
    }

    // Get all income for previous month
    final incomeResult = await db.rawQuery('''
      SELECT COALESCE(SUM(${DatabaseConstants.colAmount}), 0) as total
      FROM ${DatabaseConstants.transactionsTable}
      WHERE ${DatabaseConstants.colType} = 'income'
        AND $whereClause
    ''', params);

    // Get all expenses for previous month
    final expenseResult = await db.rawQuery('''
      SELECT COALESCE(SUM(${DatabaseConstants.colAmount}), 0) as total
      FROM ${DatabaseConstants.transactionsTable}
      WHERE ${DatabaseConstants.colType} != 'income'
        AND $whereClause
    ''', params);

    final income = (incomeResult.first['total'] as num?)?.toDouble() ?? 0.0;
    final expenses = (expenseResult.first['total'] as num?)?.toDouble() ?? 0.0;

    return income - expenses;
  }

  /// Perform month transition: create carryover and copy recurring expenses
  Future<void> performMonthTransition(
      String previousMonth, String currentMonth) async {
    // 1. Calculate surplus from previous month
    final surplus = await calculatePreviousMonthSurplus(previousMonth);
    debugPrint(
        '[MonthTransition] Calculated surplus: $surplus for previousMonth: $previousMonth');

    // 2. Create carryover income transaction (only if surplus > 0)
    if (surplus > 0) {
      // Use debug override date if set, otherwise use current date
      // Parse the currentMonth to get the first day of that month
      final parts = currentMonth.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final transactionDate = debugOverrideDate ?? DateTime(year, month, 1);

      debugPrint(
          '[MonthTransition] Creating carryover: amount=$surplus, date=$transactionDate, jar=${previousMonth}_carryover');

      final carryover = TransactionModel(
        type: 'income',
        jar: '${previousMonth}_carryover',
        amount: surplus,
        date: transactionDate,
        note: 'Carryover from ${_formatMonthName(previousMonth)}',
      );
      await _transactionRepo.insertTransaction(carryover);
      debugPrint('[MonthTransition] Carryover inserted successfully');
    } else {
      debugPrint(
          '[MonthTransition] No surplus to carry over (surplus = $surplus)');
    }

    // 3. Copy recurring expenses to new month
    await _copyRecurringExpenses(previousMonth, currentMonth);

    // 4. Carry over goals (create new month allocations)
    await _carryOverGoals(currentMonth);
  }

  /// Copy recurring expenses from previous month to current month
  Future<void> _copyRecurringExpenses(
      String previousMonth, String currentMonth) async {
    debugPrint(
        '[MonthTransition] Copying recurring expenses from $previousMonth to $currentMonth');
    final previousExpenses = await _expenseRepo.getForMonth(previousMonth);
    debugPrint(
        '[MonthTransition] Found ${previousExpenses.length} expenses in $previousMonth');

    for (final expense in previousExpenses) {
      debugPrint(
          '[MonthTransition] Processing expense: ${expense.title}, amount: ${expense.amount}');
      // Skip Safely Spend (it's auto-calculated)
      if (expense.title.toLowerCase() == 'safely spend') {
        debugPrint('[MonthTransition] Skipping Safely Spend (auto-calculated)');
        continue;
      }

      // Skip zero-budget expenses (deleted items)
      if (expense.amount <= 0) {
        debugPrint('[MonthTransition] Skipping zero-budget expense');
        continue;
      }

      // Check if already exists in current month
      final existing = await _expenseRepo.getForMonth(currentMonth);
      final alreadyExists = existing
          .any((e) => e.title.toLowerCase() == expense.title.toLowerCase());

      if (!alreadyExists) {
        debugPrint(
            '[MonthTransition] Copying ${expense.title} to $currentMonth');
        // Create new expense for current month
        final newExpense = ExpectedExpense(
          title: expense.title,
          frequency: expense.frequency,
          amount: expense.amount,
          month: currentMonth,
        );
        await _expenseRepo.insert(newExpense);
        debugPrint('[MonthTransition] Copied successfully');
      } else {
        debugPrint(
            '[MonthTransition] ${expense.title} already exists in $currentMonth');
      }
    }
  }

  /// Carry over goals to new month (create budget allocations)
  Future<void> _carryOverGoals(String currentMonth) async {
    final goals = await _goalRepo.getAll();

    for (final goal in goals) {
      // Skip completed goals
      if (goal.isCompleted) continue;

      // Check if goal budget already exists for current month
      final existing = await _expenseRepo.getForMonth(currentMonth);
      final alreadyExists = existing
          .any((e) => e.title.toLowerCase() == goal.title.toLowerCase());

      if (!alreadyExists) {
        // Calculate remaining amount
        final remaining = goal.targetAmount - goal.currentAmount;

        // Skip if no remaining amount
        if (remaining <= 0) continue;

        // Assume 3 months to complete (can be adjusted later)
        final monthlyAllocation = remaining / 3;

        final goalExpense = ExpectedExpense(
          title: goal.title,
          frequency: 'monthly',
          amount: monthlyAllocation,
          month: currentMonth,
        );
        await _expenseRepo.insert(goalExpense);
      }
    }
  }

  /// Format month string to readable name (e.g., "2025-06" → "June 2025")
  String _formatMonthName(String monthStr) {
    final parts = monthStr.split('-');
    final year = parts[0];
    final month = int.parse(parts[1]);
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${monthNames[month - 1]} $year';
  }

  /// Get previous month string from current month
  String getPreviousMonth(String currentMonth) {
    try {
      final parts = currentMonth.split('-');
      if (parts.length < 2) return currentMonth;

      var year = int.parse(parts[0]);
      var month = int.parse(parts[1]);

      month--;
      if (month < 1) {
        month = 12;
        year--;
      }

      return '$year-${month.toString().padLeft(2, '0')}';
    } catch (e) {
      return currentMonth;
    }
  }

  /// Clean up test data created during debug simulation
  /// Deletes transactions and expenses for the simulated month
  Future<void> cleanupTestData(String simulatedMonth) async {
    final db = await _dbHelper.database;

    debugPrint('[Cleanup] Deleting test data for month: $simulatedMonth');

    // Delete transactions for the simulated month
    final deletedTransactions = await db.delete(
      DatabaseConstants.transactionsTable,
      where: "strftime('%Y-%m', ${DatabaseConstants.colDate}) = ?",
      whereArgs: [simulatedMonth],
    );
    debugPrint('[Cleanup] Deleted $deletedTransactions transactions');

    // Delete expected expenses for the simulated month
    final deletedExpenses = await db.delete(
      DatabaseConstants.expectedExpensesTable,
      where: 'month = ?',
      whereArgs: [simulatedMonth],
    );
    debugPrint('[Cleanup] Deleted $deletedExpenses expected expenses');
  }
}
