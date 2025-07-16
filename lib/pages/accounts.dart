import 'dart:io';

import 'package:Seqeunce_API_Client/utils/dbhelper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:Seqeunce_API_Client/utils/sequence_api.dart';
import 'package:shared_preferences/shared_preferences.dart';


//TODO: Implement a dialog to select which accounts to add to the page.


class AccountPage extends StatefulWidget {
  AccountPage(this.prefs,{Key? key}) : super(key: key);
  SharedPreferences prefs;

  @override
  AccountPageState createState() => AccountPageState();
}

class AccountPageState extends State<AccountPage> {
  late Future<List<SequenceAccount>> _accountFuture;
    String? apitoken ="";
    bool obscure = true;
    String apiResponse = '';
    TextEditingController token = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadPrefs();
    _accountFuture = DatabaseHelper().getAccounts();
  }

  Future<void> refreshAccounts() async {
    widget.prefs.setString('lastSync', DateTime.now().toIso8601String());
    final accounts = await SequenceApi.getAccounts(apitoken!);
    for (var account in accounts) {
      await DatabaseHelper().upsertAccountByName(account);
    }

    setState(() {
      _accountFuture = DatabaseHelper().getAccounts();
    });
  }

  void loadPrefs(){
    widget.prefs.reload();
    String? sequence_api_token = widget.prefs.getString("sequenceToken");
    if (sequence_api_token != null) {
      setState(() {
        token.text = sequence_api_token;
        apitoken = sequence_api_token;
      });
    }
  }
  
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: IconButton.filled(
        onPressed: () async {
          final result = await showModalBottomSheet<String>(isScrollControlled: true ,showDragHandle: true ,context: context, builder: (BuildContext context) {
            return StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
              return Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                child: SizedBox(
                  height: 500,
                  child: Column(
                    children: [
                      const Text("Settings"),
                      ExpansionTile(
                        title: const Text("Sequence API Settings"),
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 400,
                                height: 80,
                                child: Padding(
                                  padding: EdgeInsetsGeometry.directional(start: 15),
                                  child: TextField(
                                    controller: token,
                                    decoration: InputDecoration(
                                      suffix: IconButton(
                                        onPressed: (){
                                          setState((){
                                            if (obscure == true){
                                              obscure = false;
                                            } else if (obscure == false){
                                              obscure = true;
                                            }
                                          });
                                        }, 
                                        icon: Icon(Icons.remove_red_eye_outlined)
                                      ),
                                      labelText: "Token",
                                    ),
                                    obscureText: obscure,
                                  )
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  String apitoken = token.text;
                                  if (apitoken == ""){
                                    widget.prefs.remove("sequenceToken");
                                  }
                                  widget.prefs.setString("sequenceToken", apitoken);
                                  Navigator.pop(context, apitoken);
                                }, 
                                child: Text("Save")
                              ),
                            ],
                          )
                        ],
                      ),
                      //TODO: History Toggle, hide Drawer when disabled
                    ],
                  ),
                )
              );
            });
          });
          if (result != null ) {
            setState(() {
              apitoken = result;
            });
            refreshAccounts();
          }
        },
        icon: Icon(
          Icons.settings
        )
      ),
      body: FutureBuilder<List<SequenceAccount>>(
        future: _accountFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No items found'));
          } else {
            return RefreshIndicator(
              onRefresh: refreshAccounts,
              child: ListView.builder(
                physics: AlwaysScrollableScrollPhysics(),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index)  {
                  final item = snapshot.data![index];
                  final lastSyncString = widget.prefs.getString('lastSync');
                  final lastSyncFormatted = lastSyncString != null
                    ? DateFormat('yyyy-MM-dd hh:mma').format(DateTime.parse(lastSyncString))
                    : 'Never';
                  return ListTile(
                    title: Text(item.name ?? 'Unnamed Account'),
                    subtitle: Text(
                      'Type: ${item.type ?? 'N/A'}\nBalance: \$${item.balance?.toStringAsFixed(2) ?? '0.00'}', 
                    ),
                    trailing: Text(
                      "Last Sync\n$lastSyncFormatted",
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  );
                },
              ),
            );
          }
        },
      )
    );
  }
}