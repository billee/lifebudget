import '../database/database_helper.dart';
import '../database/database_constants.dart';
import '../models/expected_expense_model.dart';

class ExpectedExpenseRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<ExpectedExpense>> getForMonth(String month) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseConstants.expectedExpensesTable,
      where: 'month = ?',
      whereArgs: [month],
      orderBy: 'title ASC',
    );
    return maps.map((m) => ExpectedExpense.fromMap(m)).toList();
  }

  Future<int> insert(ExpectedExpense expense) async {
    final db = await _dbHelper.database;
    return await db.insert(
        DatabaseConstants.expectedExpensesTable, expense.toMap());
  }

  Future<int> update(ExpectedExpense expense) async {
    final db = await _dbHelper.database;
    return await db.update(
      DatabaseConstants.expectedExpensesTable,
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      DatabaseConstants.expectedExpensesTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteByTitle(String title) async {
    final db = await _dbHelper.database;
    // Case-insensitive delete
    await db.delete(
      DatabaseConstants.expectedExpensesTable,
      where: 'LOWER(title) = LOWER(?)',
      whereArgs: [title],
    );
  }

  // Upsert "Safely Spend" expense (creates or updates based on calculation)
  // Ensures only one row exists per month.
  Future<void> upsertSafelySpend(double amount, String month) async {
    final db = await _dbHelper.database;

    // Find all existing Safely Spend rows for this month
    final existing = await db.query(
      DatabaseConstants.expectedExpensesTable,
      where: 'LOWER(title) = ? AND month = ?',
      whereArgs: ['safely spend', month],
    );

    // Delete all but the first one (clean up any duplicates)
    if (existing.length > 1) {
      final idsToDelete =
          existing.skip(1).map((row) => row['id'] as int).toList();
      await db.delete(
        DatabaseConstants.expectedExpensesTable,
        where: 'id IN (${idsToDelete.map((_) => '?').join(',')})',
        whereArgs: idsToDelete,
      );
    }

    // Now get the single remaining row (or null if none)
    final single = existing.isEmpty ? null : existing.first;

    if (single != null) {
      // Update existing
      await db.update(
        DatabaseConstants.expectedExpensesTable,
        {'amount': amount},
        where: 'id = ?',
        whereArgs: [single['id']],
      );
    } else {
      // Insert new
      await db.insert(DatabaseConstants.expectedExpensesTable, {
        'title': 'Safely Spend',
        'frequency': 'monthly',
        'amount': amount,
        'month': month,
      });
    }
  }

  /// Remove duplicate "Safely Spend" entries for the current month.
  /// Call this once (e.g., after database initialization) to clean up existing duplicates.
  Future<void> deduplicateSafelySpend() async {
    final db = await _dbHelper.database;
    final month = DateTime.now().toIso8601String().substring(0, 7); // "YYYY-MM"

    final rows = await db.query(
      DatabaseConstants.expectedExpensesTable,
      where: 'LOWER(title) = ? AND month = ?',
      whereArgs: ['safely spend', month],
      orderBy: 'id ASC',
    );

    if (rows.length > 1) {
      final idsToDelete = rows.skip(1).map((row) => row['id'] as int).toList();
      await db.delete(
        DatabaseConstants.expectedExpensesTable,
        where: 'id IN (${idsToDelete.map((_) => '?').join(',')})',
        whereArgs: idsToDelete,
      );
    }
  }
}
