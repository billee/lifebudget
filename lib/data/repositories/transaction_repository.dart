import '../database/database_helper.dart';
import '../database/database_constants.dart';
import '../models/transaction_model.dart';
import 'package:sqflite/sqflite.dart';

class TransactionRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Insert a transaction
  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await _dbHelper.database;
    return await db.insert(
      DatabaseConstants.transactionsTable,
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all transactions for a specific jar (for jar detail screen)
  Future<List<TransactionModel>> getTransactionsByJar(String jar) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseConstants.transactionsTable,
      where: '${DatabaseConstants.colJar} = ?',
      whereArgs: [jar],
      orderBy: '${DatabaseConstants.colDate} DESC',
    );
    return maps.map((map) => TransactionModel.fromMap(map)).toList();
  }

  // N+1‑free summary: returns total spent per jar and total income
  Future<Map<String, double>> getJarSummaries() async {
    final db = await _dbHelper.database;
    // One query to get sum of expenses per jar (excluding _deduction and safely_spend jars)
    final expenseResult = await db.rawQuery('''
      SELECT ${DatabaseConstants.colJar}, SUM(${DatabaseConstants.colAmount}) as total
      FROM ${DatabaseConstants.transactionsTable}
      WHERE ${DatabaseConstants.colType} IN ('expense', 'savings')
        AND ${DatabaseConstants.colJar} NOT LIKE '%_deduction'
        AND LOWER(${DatabaseConstants.colJar}) != 'safely spend'
      GROUP BY ${DatabaseConstants.colJar}
    ''');

    // One query to get total income
    final incomeResult = await db.rawQuery('''
      SELECT COALESCE(SUM(${DatabaseConstants.colAmount}), 0) as total
      FROM ${DatabaseConstants.transactionsTable}
      WHERE ${DatabaseConstants.colType} = 'income'
    ''');

    // Query to get total deductions (both _deduction jars and safely_spend)
    final deductionResult = await db.rawQuery('''
      SELECT COALESCE(SUM(${DatabaseConstants.colAmount}), 0) as total
      FROM ${DatabaseConstants.transactionsTable}
      WHERE ${DatabaseConstants.colType} = 'expense'
        AND (${DatabaseConstants.colJar} LIKE '%_deduction' OR LOWER(${DatabaseConstants.colJar}) = 'safely spend')
    ''');

    final Map<String, double> summaries = {};
    for (final row in expenseResult) {
      final jar = row[DatabaseConstants.colJar] as String;
      final total = (row['total'] as num?)?.toDouble() ?? 0.0;
      summaries[jar] = total;
    }

    // Store both raw income and effective income (after deductions)
    final totalIncome =
        (incomeResult.first['total'] as num?)?.toDouble() ?? 0.0;
    final totalDeductions =
        (deductionResult.first['total'] as num?)?.toDouble() ?? 0.0;
    summaries['__total_income__'] = totalIncome; // Raw total income for display
    summaries['__effective_income__'] =
        totalIncome - totalDeductions; // For calculations

    // Also store safely_spend total separately for UI display
    final safelySpendResult = await db.rawQuery('''
      SELECT COALESCE(SUM(${DatabaseConstants.colAmount}), 0) as total
      FROM ${DatabaseConstants.transactionsTable}
      WHERE ${DatabaseConstants.colType} = 'expense'
        AND LOWER(${DatabaseConstants.colJar}) = 'safely spend'
    ''');
    summaries['__safely_spend_spent__'] =
        (safelySpendResult.first['total'] as num?)?.toDouble() ?? 0.0;

    return summaries;
  }

  // Get all transactions (both income and expense) for current month, newest first
  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseConstants.transactionsTable,
      orderBy: '${DatabaseConstants.colDate} DESC',
    );
    return maps.map((map) => TransactionModel.fromMap(map)).toList();
  }

  /// Get jar spending totals for a specific archived month.
  Future<Map<String, double>> getArchivedJarSummaries(String month) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT ${DatabaseConstants.colJar}, SUM(${DatabaseConstants.colAmount}) as total
      FROM ${DatabaseConstants.archivedTransactionsTable}
      WHERE archived_month = ? AND ${DatabaseConstants.colType} = 'expense'
      GROUP BY ${DatabaseConstants.colJar}
    ''', [month]);

    final Map<String, double> summaries = {};
    for (final row in result) {
      final jar = row[DatabaseConstants.colJar] as String;
      final total = (row['total'] as num?)?.toDouble() ?? 0.0;
      summaries[jar] = total;
    }
    return summaries;
  }

  // Delete all transactions for a specific jar (for expense cascade delete)
  Future<void> deleteByJar(String jar) async {
    final db = await _dbHelper.database;
    await db.delete(
      DatabaseConstants.transactionsTable,
      where: '${DatabaseConstants.colJar} = ?',
      whereArgs: [jar],
    );
  }

  // Get total spent for a specific jar this month
  Future<double> getJarSpentThisMonth(String jar) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(${DatabaseConstants.colAmount}), 0) as total
      FROM ${DatabaseConstants.transactionsTable}
      WHERE ${DatabaseConstants.colJar} = ?
        AND ${DatabaseConstants.colType} != 'income'
        AND ${DatabaseConstants.colDate} >= ?
    ''', [jar, firstDay.toIso8601String()]);
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // Delete all savings transactions for a specific jar (for goal cascade delete)
  Future<void> deleteSavingsByJar(String jar) async {
    final db = await _dbHelper.database;
    await db.delete(
      DatabaseConstants.transactionsTable,
      where:
          '${DatabaseConstants.colJar} = ? AND ${DatabaseConstants.colType} = ?',
      whereArgs: [jar, 'savings'],
    );
  }

  // Delete a single transaction by ID
  Future<void> deleteTransaction(int id) async {
    final db = await _dbHelper.database;
    await db.delete(
      DatabaseConstants.transactionsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Update a transaction
  Future<void> updateTransaction(TransactionModel transaction) async {
    final db = await _dbHelper.database;
    await db.update(
      DatabaseConstants.transactionsTable,
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  // Transfer money between categories (creates two linked transactions)
  Future<void> transferBetweenCategories({
    required String fromCategory,
    required String toCategory,
    required double amount,
    required DateTime date,
    String? note,
  }) async {
    final db = await _dbHelper.database;

    // Create expense from source category
    await db.insert(DatabaseConstants.transactionsTable, {
      'type': 'expense',
      'jar': fromCategory,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note ?? 'Transfer to $toCategory',
    });

    // Create income to destination category
    await db.insert(DatabaseConstants.transactionsTable, {
      'type': 'expense',
      'jar': toCategory,
      'amount': -amount, // Negative amount = credit
      'date': date.toIso8601String(),
      'note': note ?? 'Transfer from $fromCategory',
    });
  }

// Archive all transactions for the given month and delete them from active
  Future<void> archiveMonth(String month) async {
    final db = await _dbHelper.database;

    // 1. Copy transactions to archive
    await db.rawInsert('''
    INSERT INTO ${DatabaseConstants.archivedTransactionsTable}
    (${DatabaseConstants.colType}, ${DatabaseConstants.colJar}, ${DatabaseConstants.colAmount}, ${DatabaseConstants.colDate}, ${DatabaseConstants.colNote}, archived_month)
    SELECT ${DatabaseConstants.colType}, ${DatabaseConstants.colJar}, ${DatabaseConstants.colAmount}, ${DatabaseConstants.colDate}, ${DatabaseConstants.colNote}, ? 
    FROM ${DatabaseConstants.transactionsTable}
    WHERE strftime('%Y-%m', ${DatabaseConstants.colDate}) = ?
    ''', [month, month]);

    // 2. Delete active transactions for that month
    await db.delete(
      DatabaseConstants.transactionsTable,
      where: "strftime('%Y-%m', ${DatabaseConstants.colDate}) = ?",
      whereArgs: [month],
    );
  }
}
