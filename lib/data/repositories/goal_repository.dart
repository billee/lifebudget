import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../database/database_constants.dart';
import '../models/goal_model.dart';

class GoalRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> insert(Goal goal) async {
    final db = await _dbHelper.database;
    return await db.insert(
      DatabaseConstants.goalsTable,
      goal.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Goal>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseConstants.goalsTable,
      orderBy: 'createdDate DESC',
    );
    return maps.map((map) => Goal.fromMap(map)).toList();
  }

  Future<int> update(Goal goal) async {
    final db = await _dbHelper.database;
    return await db.update(
      DatabaseConstants.goalsTable,
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      DatabaseConstants.goalsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
