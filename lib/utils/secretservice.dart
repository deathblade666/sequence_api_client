import 'dart:io';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:Seqeunce_API_Client/utils/db/dbhelper.dart';
import 'package:sqflite/sqflite.dart';

class SecretService {
  static SecretService? _instance;
  final encrypt.Encrypter _encrypter;
  static final encrypt.IV _iv = encrypt.IV.fromUtf8(
    dotenv.env['ENCRYPTION_IV']!,
  );

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
      throw Exception(
        "SecretService not initialized. Call SecretService.init() first.",
      );
    }
    return _instance!;
  }

  Future<void> saveToken(String token) async {
    final encrypted = _encrypter.encrypt(token.trim(), iv: _iv).base64;
    final db = await _dbHelper.database;
    await db.insert('secrets', {
      'id': 1,
      'secret': encrypted,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getToken() async {
    final db = await _dbHelper.database;
    final result = await db.query('secrets', where: 'id = ?', whereArgs: [1]);
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

  Future<String> encryptToken(String token) async {
    return _encrypter.encrypt(token.trim(), iv: _iv).base64;
  }

  String _padBase64(String input) {
    final trimmed = input.trim();
    final padLength = (4 - trimmed.length % 4) % 4;
    return trimmed + '=' * padLength;
  }

  Future<String?> decryptToken(String encryptedToken) async {
    try {
      final paddedToken = _padBase64(encryptedToken);
      return _encrypter.decrypt64(paddedToken, iv: _iv);
    } catch (e) {
      print("❌ Decryption failed: $e");
      return null;
    }
  }

  bool _isBase64Safe(String input) {
    final trimmed = input.trim();
    if (trimmed.length < 8 || trimmed.length % 4 != 0) return false;
    final base64Regex = RegExp(r'^[A-Za-z0-9+/]+={0,2}$');
    return base64Regex.hasMatch(trimmed);
  }

  Future<bool> isTokenEncrypted(String token) async {
    final cleaned = token.trim();
    if (!_isBase64Safe(cleaned)) return false;
    try {
      final decrypted = _encrypter.decrypt64(cleaned, iv: _iv);
      return decrypted.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
