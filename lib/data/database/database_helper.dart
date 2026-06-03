import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'database_constants.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('lifebudget.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path,
        version: 3, onCreate: _createDB, onUpgrade: _upgradeDB);
  }

  Future<void> _createDB(Database db, int version) async {
    // Create transactions table (unchanged)
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.transactionsTable} (
        ${DatabaseConstants.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DatabaseConstants.colType} TEXT NOT NULL,
        ${DatabaseConstants.colJar} TEXT NOT NULL,
        ${DatabaseConstants.colAmount} REAL NOT NULL,
        ${DatabaseConstants.colDate} TEXT NOT NULL,
        ${DatabaseConstants.colNote} TEXT
      )
    ''');

    // Create jar_allocations table with percentage
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.jarAllocationsTable} (
        ${DatabaseConstants.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DatabaseConstants.colMonth} TEXT NOT NULL,
        ${DatabaseConstants.colJarName} TEXT NOT NULL,
        ${DatabaseConstants.colPercentage} REAL NOT NULL,
        UNIQUE(${DatabaseConstants.colMonth}, ${DatabaseConstants.colJarName})
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DatabaseConstants.expectedExpensesTable} (
        ${DatabaseConstants.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        frequency TEXT NOT NULL,
        amount REAL NOT NULL,
        month TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DatabaseConstants.slipUpsTable} (
        ${DatabaseConstants.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        amount REAL,
        mood TEXT NOT NULL,
        note TEXT
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseConstants.expectedExpensesTable} (
        ${DatabaseConstants.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        frequency TEXT NOT NULL,
        amount REAL NOT NULL,
        month TEXT NOT NULL
      )
    ''');
    }
  }
}
