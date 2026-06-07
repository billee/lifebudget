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
    // One query to get sum of expenses per jar
    final expenseResult = await db.rawQuery('''
      SELECT ${DatabaseConstants.colJar}, SUM(${DatabaseConstants.colAmount}) as total
      FROM ${DatabaseConstants.transactionsTable}
      WHERE ${DatabaseConstants.colType} IN ('expense', 'savings')
      GROUP BY ${DatabaseConstants.colJar}
    ''');

    // One query to get total income
    final incomeResult = await db.rawQuery('''
      SELECT SUM(${DatabaseConstants.colAmount}) as total
      FROM ${DatabaseConstants.transactionsTable}
      WHERE ${DatabaseConstants.colType} = 'income'
    ''');

    final Map<String, double> summaries = {};
    for (final row in expenseResult) {
      final jar = row[DatabaseConstants.colJar] as String;
      final total = (row['total'] as num?)?.toDouble() ?? 0.0;
      summaries[jar] = total;
    }

    // total income stored under a special key
    final totalIncome =
        (incomeResult.first['total'] as num?)?.toDouble() ?? 0.0;
    summaries['__total_income__'] = totalIncome;

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
