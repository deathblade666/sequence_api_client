import 'package:Seqeunce_API_Client/utils/history.dart';
import 'package:Seqeunce_API_Client/utils/rules.dart';
import 'package:Seqeunce_API_Client/utils/sequence_api.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static const int _version = 4;
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
      version: _version,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE accounts(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            type TEXT,
            balance REAL,
            hidden INTEGER,
            order_index INTEGER,
            lastsync TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            timestamp TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE rules (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            ruleid TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            token TEXT NOT NULL,
            order_index INTEGER DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE secrets (
            id INTEGER PRIMARY KEY,
            secret TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            ALTER TABLE rules ADD COLUMN order_index INTEGER DEFAULT 0
          ''');
          final rules = await db.query('rules', orderBy: 'id ASC');
          for (int i = 0; i < rules.length; i++) {
            await db.update(
              'rules',
              {'order_index': i},
              where: 'id = ?',
              whereArgs: [rules[i]['id']],
            );
          }
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE secrets (
              id INTEGER PRIMARY KEY,
              secret TEXT NOT NULL
            )
       ''');
        }
        if (oldVersion < 4) {
          await db.execute('''
          ALTER TABLE accounts ADD COLUMN lastsync TEXT DEFAULT NULL
          ''');
        }
      }
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
    final List<Map<String, dynamic>> maps = await db.query(
      'accounts',
      where: 'hidden = 0',
      orderBy: 'order_index ASC',
    );
    return maps.map((map) => SequenceAccount.fromMap(map)).toList();
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
      final existingOrder = existing.first['order_index'] as int? ?? 0;

      await db.update(
        'accounts',
        {
          ...account.toMap(),
          'order_index': existingOrder,
        },
        where: 'name = ?',
        whereArgs: [account.name],
      );
      print("Upserted ${account.name} with preserved order_index $existingOrder");

    } else {
      final maxOrderResult = await db.rawQuery('SELECT MAX(order_index) as max_order FROM accounts');
      final maxOrder = maxOrderResult.first['max_order'] as int? ?? 0;

      await db.insert(
        'accounts',
        {
          ...account.toMap(),
          'order_index': maxOrder + 1,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<List<SequenceAccount>> getHiddenAccounts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'accounts',
      where: 'hidden = 1',
      orderBy: 'order_index ASC',
    );
    return maps.map((map) => SequenceAccount.fromMap(map)).toList();
  }

  Future<void> updateAccountOrder(String name, int newOrder) async {
    final db = await database;
    await db.update(
      'accounts',
      {'order_index': newOrder},
      where: 'name = ?',
      whereArgs: [name],
    );
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

  Future<List<Rule>> getRules() async {
    final db = await database;
    final result = await db.query('rules', orderBy: 'order_index ASC');
    return result.map((r) => Rule(
      id: r['id'] as int?,
      name: r['name'] as String,
      ruleId: r['ruleid'] as String,
      timestamp: r['timestamp'] as String,
      token: r['token'] as String,
      orderIndex: r['order_index'] as int? ?? 0,
    )).toList();
  }

  Future<int> updateRule(Rule rule) async {
    final db = await database;
    return await db.update(
      'rules',
      {
        'name': rule.name,
        'ruleid': rule.ruleId,
        'token': rule.token,
        'timestamp': rule.timestamp,
        'order_index': rule.orderIndex,
      },
      where: 'id = ?',
      whereArgs: [rule.id],
    );
  }

  Future<void> updateRuleOrder(int? ruleId, int newOrder) async {
    final db = await database;
    await db.update(
      'rules',
      {'order_index': newOrder},
      where: 'id = ?',
      whereArgs: [ruleId],
    );
  }

  Future<void> upsertSecret(String secretValue) async {
    final db = await database;
    await db.insert(
      'secrets',
      {'id': 1, 'secret': secretValue},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSecret() async {
    final db = await database;
    final result = await db.query(
      'secrets',
      where: 'id = ?',
      whereArgs: [1],
    );

    if (result.isNotEmpty) {
      return result.first['secret'] as String?;
    }
    return null;
  }

  Future<void> deleteSecret() async {
    final db = await database;
    await db.delete(
      'secrets',
      where: 'id = ?',
      whereArgs: [1],
    );
  }
}