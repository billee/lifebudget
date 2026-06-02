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
}
