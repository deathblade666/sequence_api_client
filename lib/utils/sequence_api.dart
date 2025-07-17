import 'dart:convert';
import 'dart:io';

import 'package:Seqeunce_API_Client/utils/dbhelper.dart';
import 'package:sqflite/sqflite.dart';

class SequenceApi{

  static runTrigger(String ruleId, String apitoken) async {
    var uri = Uri.parse('https://api.getsequence.io/remote-api/rules/$ruleId/trigger');
    var client = HttpClient();
    var request = await client.postUrl(uri);
    request.headers.contentType = ContentType('application', 'json');
    request.headers.set('x-sequence-signature', 'Bearer $apitoken');
    request.write(jsonEncode({}));
    var response = await request.close();
    var responseBody = await response.transform(utf8.decoder).join();
    var jsonData = jsonDecode(responseBody);
    var statusCode = response.statusCode;
    return statusCode;

  }

  static Future<List<SequenceAccount>> getAccounts(String apitoken) async {
    final dbHelper = DatabaseHelper();
    var uri = Uri.parse('https://api.getsequence.io/accounts');
    var client = HttpClient();
    var request = await client.postUrl(uri);
    request.headers.contentType = ContentType('application', 'json');
    request.headers.set('x-sequence-access-token', 'Bearer $apitoken');
    request.write(jsonEncode({}));
    var response = await request.close();
    var responseBody = await response.transform(utf8.decoder).join();
    var jsonData = jsonDecode(responseBody);

    if (jsonData != null &&
        jsonData is Map &&
        jsonData['data'] != null &&
        jsonData['data']['balances'] != null) {
      List<dynamic> balancesJson = jsonData['data']['balances'];
      List<SequenceAccount> accountList = balancesJson
        .map((data) => SequenceAccount.fromJson(data))
        .toList();
      for (var account in accountList) {
        await dbHelper.upsertAccountByName(account);
      }
      List<SequenceAccount> allAccounts = await dbHelper.getAccounts();
      return accountList;
    } else {
      throw ApiDataException(
        '\nInvalid or missing data in API response\nThis is likely due to an invalid or missing API token\nPlease press the settings button to add or review your token',
      );
    }
  }
}

class SequenceAccount {
  final String? name;
  final String? type;
  final double? balance;
  final bool? hidden;
  final int? id;
  SequenceAccount({required this.balance, required this.type, required this.name, this.hidden, this.id});

  factory SequenceAccount.fromJson(Map<String, dynamic> json) {
    return SequenceAccount(
      balance: (json['balance'] as num?)?.toDouble(),
      type: json['type'],
      name: json['name'],
      hidden: false,
    );
  }

  Map<String, dynamic> toMap() {
  return {
    'name': name,
    'type': type,
    'balance': balance,
    'hidden': hidden == true ? 1 : 0,
  };
}

  static SequenceAccount fromMap(Map<String, dynamic> map) {
    return SequenceAccount(
      name: map['name'],
      type: map['type'],
      balance: (map['balance'] as num?)?.toDouble(),
      hidden: map['hidden'] == 1,
      id: map['id'],
    );
  }
}


class ApiDataException implements Exception {
  final String message;
  ApiDataException(this.message);

  @override
  String toString() => message;
}
