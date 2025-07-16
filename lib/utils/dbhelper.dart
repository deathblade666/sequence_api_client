import 'package:Seqeunce_API_Client/utils/history.dart';
import 'package:Seqeunce_API_Client/utils/sequence_api.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'sequence.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE accounts(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            type TEXT,
            balance REAL,
            hidden INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            timestamp TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<int> insertAccount(SequenceAccount account) async {
    final db = await database;
    return await db.insert(
      'accounts',
      account.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<SequenceAccount>> getAccounts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('accounts');

    return List.generate(maps.length, (i) {
      return SequenceAccount.fromMap(maps[i]);
    });
  }

  Future<int> updateAccount(SequenceAccount account) async {
    final db = await database;
    return await db.update(
      'accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<int> deleteAccount(int id) async {
    final db = await database;
    return await db.delete(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> printAllAccounts() async {
    final db = await database;
    final results = await db.query('history');
    for (var row in results) {
      print(row);
    }
  }

  Future<void> upsertAccountByName(SequenceAccount account) async {
    final db = await database;

    final existing = await db.query(
      'accounts',
      where: 'name = ?',
      whereArgs: [account.name],
    );

    if (existing.isNotEmpty) {
      await db.update(
        'accounts',
        account.toMap(),
        where: 'name = ?',
        whereArgs: [account.name],
      );
    } else {
      await db.insert(
        'accounts',
        account.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }


  Future<void> insertHistory(HistoryItem item) async {
  final db = await database;
  await db.insert('history', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
}

Future<List<HistoryItem>> getHistory() async {
  final db = await database;
  final maps = await db.query('history', orderBy: 'id DESC');
  return maps.map((map) => HistoryItem.fromMap(map)).toList();
}





}


