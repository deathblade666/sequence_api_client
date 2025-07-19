import 'dart:convert';
import 'dart:io';

import 'package:Seqeunce_API_Client/utils/db/dbhelper.dart';

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
print(responseBody);
    if (jsonData != null &&
        jsonData is Map &&
        jsonData['data'] != null &&
        jsonData['data']['balances'] != null) {
      List<dynamic> balancesJson = jsonData['data']['balances'];
      List<SequenceAccount> accountList = [];
      final existingAccounts = await dbHelper.getAccounts();
      final hiddenAccounts = await dbHelper.getHiddenAccounts();
      final allExistingAccounts = [...existingAccounts, ...hiddenAccounts];
      final orderMap = {
        for (var acc in existingAccounts)
          acc.name: acc.orderIndex ?? 0,
      };
      final hiddenMap = {
        for (var acc in allExistingAccounts)
          acc.name: acc.hidden ?? false,
      };
      for (var data in balancesJson) {
        final name = data['name'];
        final preservedOrder = orderMap[name] ?? orderMap.length;
        final preservedHidden = hiddenMap[name] ?? false;
        final account = SequenceAccount.fromJson(data).copyWith(
          orderIndex: preservedOrder,
          hidden: preservedHidden,
        );
        await dbHelper.upsertAccountByName(account);
        if (!preservedHidden) {
          accountList.add(account);
        }
      }
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
  final int? orderIndex;
  final String? lastsync;

  SequenceAccount({
    required this.balance,
    required this.type,
    required this.name,
    this.hidden,
    this.id,
    this.orderIndex,
    this.lastsync
  });

  factory SequenceAccount.fromJson(Map<String, dynamic> json) {
    return SequenceAccount(
      balance: (json['balance'] as num?)?.toDouble(),
      type: json['type'],
      name: json['name'],
      hidden: false,
      orderIndex: null,
      lastsync: null
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'balance': balance,
      'hidden': hidden == true ? 1 : 0,
      'order_index': orderIndex ?? 0,
      'lastsync': lastsync
    };
  }

  static SequenceAccount fromMap(Map<String, dynamic> map) {
    return SequenceAccount(
      name: map['name'],
      type: map['type'],
      balance: (map['balance'] as num?)?.toDouble(),
      hidden: map['hidden'] == 1,
      id: map['id'],
      orderIndex: map['order_index'],
      lastsync: map['lastsync']
    );
  }
}

extension SequenceAccountCopy on SequenceAccount {
  SequenceAccount copyWith({
    String? name,
    String? type,
    double? balance,
    bool? hidden,
    int? id,
    int? orderIndex,
    String? lastsync
  }) {
    return SequenceAccount(
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      hidden: hidden ?? this.hidden,
      id: id ?? this.id,
      orderIndex: orderIndex ?? this.orderIndex,
      lastsync: lastsync ?? this.lastsync 
    );
  }
}


class ApiDataException implements Exception {
  final String message;
  ApiDataException(this.message);

  @override
  String toString() => message;
}
