import 'dart:io';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:Seqeunce_API_Client/utils/db/dbhelper.dart';
import 'package:sqflite/sqflite.dart';

class SecretService {
  static SecretService? _instance;
  final encrypt.Encrypter _encrypter;
  static final encrypt.IV _iv = encrypt.IV.fromUtf8(dotenv.env['ENCRYPTION_IV']!);


  final _dbHelper = DatabaseHelper();

  SecretService._(this._encrypter);

  static Future<void> init() async {
    await dotenv.load(fileName: "assets/env/.env");
    final keyString = dotenv.env['ENCRYPTION_KEY'];
    if (keyString == null || keyString.length != 32) {
      throw Exception("Missing or invalid ENCRYPTION_KEY");
    }
    final key = encrypt.Key.fromUtf8(keyString);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    _instance = SecretService._(encrypter);
  }

  static SecretService get instance {
    if (_instance == null) {
      throw Exception("SecretService not initialized. Call SecretService.init() first.");
    }
    return _instance!;
  }

  Future<void> saveToken(String token) async {
    final encrypted = _encrypter.encrypt(token.trim(), iv: _iv).base64;
    final db = await _dbHelper.database;
    await db.insert(
      'secrets',
      {'id': 1, 'secret': encrypted},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getToken() async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'secrets',
      where: 'id = ?',
      whereArgs: [1],
    );
    if (result.isNotEmpty) {
      final encrypted = result.first['secret'] as String;
      try {
        final decrypted = _encrypter.decrypt64(encrypted, iv: _iv);
        return decrypted;
      } catch (e) {
        print("❌ Decryption failed: $e");
        return null;
      }
    }
    return null;
  }

  Future<void> deleteToken() async {
    final db = await _dbHelper.database;
    await db.delete('secrets', where: 'id = ?', whereArgs: [1]);
  }
}

