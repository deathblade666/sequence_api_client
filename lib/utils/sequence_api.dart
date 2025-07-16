import 'dart:convert';
import 'dart:io';

class SequenceApi{

  //TODO: Create function to run Trigger API Event
  static runTrigger(String ruleId, String apitoken) async {
    var uri = Uri.parse('https://api.getsequence.io/rule/$ruleId/tigger');
    var client = HttpClient();
    var request = await client.postUrl(uri);
    request.headers.contentType = ContentType('application', 'json');
    request.headers.set('x-sequence-access-token', 'Bearer $apitoken');
    request.write(jsonEncode({}));
    var response = await request.close();
    var responseBody = await response.transform(utf8.decoder).join();
    var jsonData = jsonDecode(responseBody);
  }

  static Future<List<SequenceAccount>> getAccounts(String apitoken) async {
    var uri = Uri.parse('https://api.getsequence.io/accounts');
    var client = HttpClient();
    var request = await client.postUrl(uri);
    request.headers.contentType = ContentType('application', 'json');
    request.headers.set('x-sequence-access-token', 'Bearer $apitoken');
    request.write(jsonEncode({}));
    var response = await request.close();
    var responseBody = await response.transform(utf8.decoder).join();
    var jsonData = jsonDecode(responseBody);

    if (jsonData != null && jsonData is Map && jsonData['data'] != null && jsonData['data']['balances'] != null) {
      List<dynamic> balancesJson = jsonData['data']['balances'];
      List<SequenceAccount> accountList = balancesJson
        .map((data) => SequenceAccount.fromJson(data))
        .toList();
      return accountList;
    } else {
      throw Exception('\nInvalid or missing data in API response\nThis is likely due to an invalid or missing API token\nPlease press the settings button to add or review your token');
    }
  }
}

class SequenceAccount {
  final String? name;
  final String? type;
  final double? balance;
  SequenceAccount({required this.balance, required this.type, required this.name});

  factory SequenceAccount.fromJson(Map<String, dynamic> json) {
    return SequenceAccount(
      balance: (json['balance'] as num?)?.toDouble(),
      type: json['type'],
      name: json['name'],
    );
  }
}