import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:Seqeunce_API_Client/utils/db/dbhelper.dart';
import 'package:sqflite/sqflite.dart';

class SecretService {
  static final encrypt.IV _iv = encrypt.IV.fromLength(16);

  static final String keyString = dotenv.env['ENCRYPTION_KEY']!;
  static final encrypt.Key _key = encrypt.Key.fromUtf8(keyString);
  static final encrypt.Encrypter _encrypter = encrypt.Encrypter(encrypt.AES(_key));

  final _dbHelper = DatabaseHelper();

  SecretService() {
    if (keyString.length != 32) {
      throw Exception("Invalid ENCRYPTION_KEY length");
    }
  }

  Future<void> saveToken(String token) async {
    final encrypted = _encrypter.encrypt(token, iv: _iv).base64;
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
        return _encrypter.decrypt64(encrypted, iv: _iv);
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
