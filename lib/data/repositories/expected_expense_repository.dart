import 'package:sqflite/sqflite.dart';
import '../models/expected_expense_model.dart';
import '../database/database_helper.dart';

class ExpectedExpenseRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Local constants – no external file needed
  static const String _table = 'expected_expenses';
  static const String _colId = 'id';
  static const String _colMonth = 'month';
  static const String _colTitle = 'title';
  static const String _colFrequency = 'frequency';
  static const String _colAmount = 'amount';
  static const String _colDueDate = 'due_date';

  Future<Database> get database async => await _dbHelper.database;

  Future<int> insert(ExpectedExpense expense) async {
    final db = await database;
    final map = expense.toMap();
    map.remove(_colId);
    return await db.insert(_table, map);
  }

  Future<int> update(ExpectedExpense expense) async {
    final db = await database;
    final map = expense.toMap();
    return await db.update(
      _table,
      map,
      where: '$_colId = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await database;
    return await db.delete(
      _table,
      where: '$_colId = ?',
      whereArgs: [id],
    );
  }

  Future<List<ExpectedExpense>> getAllForMonth(String month) async {
    final db = await database;
    final result = await db.query(
      _table,
      where: '$_colMonth = ?',
      whereArgs: [month],
      orderBy: '$_colTitle ASC',
    );
    return result.map((map) => ExpectedExpense.fromMap(map)).toList();
  }

  // Alias for compatibility
  Future<List<ExpectedExpense>> getForMonth(String month) =>
      getAllForMonth(month);

  Future<List<ExpectedExpense>> getAll() async {
    final db = await database;
    final result = await db.query(
      _table,
      orderBy: '$_colMonth DESC, $_colTitle ASC',
    );
    return result.map((map) => ExpectedExpense.fromMap(map)).toList();
  }

  Future<ExpectedExpense?> getById(int id) async {
    final db = await database;
    final result = await db.query(
      _table,
      where: '$_colId = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return ExpectedExpense.fromMap(result.first);
    }
    return null;
  }

  Future<void> upsertSafelySpend(double amount, String month) async {
    final db = await database;
    final existing = await db.query(
      _table,
      where: '$_colTitle = ? AND $_colMonth = ?',
      whereArgs: ['Safely Spend', month],
    );
    if (existing.isNotEmpty) {
      final id = existing.first[_colId] as int;
      await db.update(
        _table,
        {_colAmount: amount, _colDueDate: null},
        where: '$_colId = ?',
        whereArgs: [id],
      );
    } else {
      await db.insert(
        _table,
        {
          _colTitle: 'Safely Spend',
          _colFrequency: 'monthly',
          _colAmount: amount,
          _colMonth: month,
          _colDueDate: null,
        },
      );
    }
  }

  Future<void> deduplicateSafelySpend() async {
    final db = await database;
    final all = await db.query(
      _table,
      where: '$_colTitle = ?',
      whereArgs: ['Safely Spend'],
      orderBy: '$_colMonth DESC',
    );
    if (all.length <= 1) return;
    for (int i = 1; i < all.length; i++) {
      final id = all[i][_colId] as int;
      await db.delete(
        _table,
        where: '$_colId = ?',
        whereArgs: [id],
      );
    }
  }

  Future<void> deleteForMonth(String month) async {
    final db = await database;
    await db.delete(
      _table,
      where: '$_colMonth = ?',
      whereArgs: [month],
    );
  }

  Future<void> markAsPaid(int id) async {
    final db = await database;
    await db.update(
      _table,
      {'is_paid': 1},
      where: '$_colId = ?',
      whereArgs: [id],
    );
  }
}
