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
    return await openDatabase(
      path,
      version: 3, // <--- bump version every time schema changes
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Use IF NOT EXISTS to avoid errors when table already exists
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseConstants.transactionsTable} (
        ${DatabaseConstants.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DatabaseConstants.colType} TEXT NOT NULL,
        ${DatabaseConstants.colJar} TEXT NOT NULL,
        ${DatabaseConstants.colAmount} REAL NOT NULL,
        ${DatabaseConstants.colDate} TEXT NOT NULL,
        ${DatabaseConstants.colNote} TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseConstants.jarAllocationsTable} (
        ${DatabaseConstants.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DatabaseConstants.colMonth} TEXT NOT NULL,
        ${DatabaseConstants.colJarName} TEXT NOT NULL,
        ${DatabaseConstants.colPercentage} REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseConstants.expectedExpensesTable} (
        ${DatabaseConstants.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        frequency TEXT NOT NULL,
        amount REAL NOT NULL,
        month TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseConstants.slipUpsTable} (
        ${DatabaseConstants.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        amount REAL,
        mood TEXT NOT NULL,
        note TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseConstants.archivedTransactionsTable} (
        ${DatabaseConstants.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DatabaseConstants.colType} TEXT NOT NULL,
        ${DatabaseConstants.colJar} TEXT NOT NULL,
        ${DatabaseConstants.colAmount} REAL NOT NULL,
        ${DatabaseConstants.colDate} TEXT NOT NULL,
        ${DatabaseConstants.colNote} TEXT,
        archived_month TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseConstants.journalTable} (
        ${DatabaseConstants.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        mood TEXT NOT NULL,
        went_well TEXT,
        do_differently TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseConstants.goalsTable} (
        ${DatabaseConstants.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        target_amount REAL NOT NULL,
        current_amount REAL NOT NULL DEFAULT 0,
        daily_amount REAL NOT NULL DEFAULT 0,
        emoji TEXT NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0,
        created_date TEXT NOT NULL
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // For development simplicity, drop all tables and recreate.
    // In production you'd write proper migrations.
    final tables = [
      DatabaseConstants.transactionsTable,
      DatabaseConstants.expectedExpensesTable,
      DatabaseConstants.slipUpsTable,
      DatabaseConstants.archivedTransactionsTable,
      DatabaseConstants.journalTable,
      DatabaseConstants.goalsTable,
    ];
    for (final table in tables) {
      await db.execute('DROP TABLE IF EXISTS $table');
    }
    await _createDB(db, newVersion);
  }
}
