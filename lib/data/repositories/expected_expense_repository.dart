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
  Future<void> upsertSafelySpend(double amount, String month) async {
    final db = await _dbHelper.database;

    // Find all existing Safely Spend rows for this month
    final existing = await db.query(
      DatabaseConstants.expectedExpensesTable,
      where: 'LOWER(title) = ? AND month = ?',
      whereArgs: ['safely spend', month],
    );

    if (existing.length > 1) {
      // Delete all but the first one
      final idsToDelete =
          existing.skip(1).map((row) => row['id'] as int).toList();
      await db.delete(
        DatabaseConstants.expectedExpensesTable,
        where: 'id IN (${idsToDelete.map((_) => '?').join(',')})',
        whereArgs: idsToDelete,
      );
    }

    if (existing.isNotEmpty) {
      // Update the first (remaining) row
      await db.update(
        DatabaseConstants.expectedExpensesTable,
        {'amount': amount},
        where: 'id = ?',
        whereArgs: [existing.first['id']],
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
}
