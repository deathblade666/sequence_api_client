import 'package:Seqeunce_API_Client/utils/dbhelper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:Seqeunce_API_Client/utils/sequence_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountPage extends StatefulWidget {
  AccountPage(this.prefs,{Key? key}) : super(key: key);
  SharedPreferences prefs;

  @override
  AccountPageState createState() => AccountPageState();
}

class AccountPageState extends State<AccountPage> {
  List<SequenceAccount> _accounts = [];
  String? apitoken = "";
  bool obscure = true;
  String apiResponse = '';
  TextEditingController token = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadPrefs();
    loadAccounts();
  }

  Future<void> loadAccounts() async {
    final accounts = await DatabaseHelper().getAccounts();
    setState(() {
      _accounts = accounts;
    });
  }

  Future<void> refreshAccounts() async {
    widget.prefs.setString('lastSync', DateTime.now().toIso8601String());
    final accountsFromApi = await SequenceApi.getAccounts(apitoken!);
    for (var account in accountsFromApi) {
      await DatabaseHelper().upsertAccountByName(account);
    }
    await loadAccounts();
  }

  void loadPrefs() {
    widget.prefs.reload();
    String? sequence_api_token = widget.prefs.getString("sequenceToken");
    if (sequence_api_token != null) {
      setState(() {
        token.text = sequence_api_token;
        apitoken = sequence_api_token;
      });
    }
  }

  Future<void> updateOrderInDb() async {
    for (int i = 0; i < _accounts.length; i++) {
      await DatabaseHelper().updateAccountOrder(_accounts[i].name!, i);
    }
  }

  void onReorder(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _accounts.removeAt(oldIndex);
      _accounts.insert(newIndex, item);
    });
    await updateOrderInDb();
  }

  
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      floatingActionButton: IconButton.filled(
        onPressed: () async {
          final result = await showModalBottomSheet<String>(isScrollControlled: true ,showDragHandle: true ,context: context, builder: (BuildContext context) {
            Future<List<SequenceAccount>> hiddenAccountsFuture = DatabaseHelper().getHiddenAccounts();
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
                                Flexible(
                                child: Padding(
                                  padding: EdgeInsetsGeometry.directional(start: 15),
                                  child: TextField(
                                    onSubmitted: (value) {
                                      String apitoken = value;
                                      if (apitoken == ""){
                                        widget.prefs.remove("sequenceToken");
                                      }
                                      widget.prefs.setString("sequenceToken", apitoken);
                                      refreshAccounts();
                                      Navigator.pop(context, apitoken);
                                    },
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
                                  refreshAccounts();
                                  Navigator.pop(context, apitoken);
                                }, 
                                child: Text("Save")
                              ),
                            ],
                          )
                        ],
                      ),
                      Flexible( 
                        child: ExpansionTile(
                          title: const Text("Hidden Accounts"),
                          children: [
                            FutureBuilder<List<SequenceAccount>>(
                              future: hiddenAccountsFuture,
                              builder: (context, snapshot) {
                                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                  return Text("No hidden accounts");
                                }
                                return ConstrainedBox(
                                  constraints: BoxConstraints(maxHeight: 350),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: snapshot.data!.length,
                                    itemBuilder: (context, index) {
                                      final account = snapshot.data![index];
                                      return CheckboxListTile(
                                        title: Text(account.name ?? 'Unnamed'),
                                        value: false,
                                        onChanged: (val) async {
                                          final updated = account.copyWith(hidden: false);
                                          await DatabaseHelper().upsertAccountByName(updated);
                                          await loadAccounts();
                                          setState(() {
                                            hiddenAccountsFuture = DatabaseHelper().getHiddenAccounts();
                                          });
                                        },
                                      );
                                    },
                                  ),
                                );
                              },
                            )
                          ],
                        ),
                      )
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
      body: RefreshIndicator(
        onRefresh: refreshAccounts,
        child: ReorderableListView.builder(
          buildDefaultDragHandles: false,
          itemCount: _accounts.length,
          onReorder: onReorder,
          itemBuilder: (context, index) {
            final item = _accounts[index];
            final lastSyncString = widget.prefs.getString('lastSync');
            final lastSyncFormatted = lastSyncString != null
            ? DateFormat('yyyy-MM-dd hh:mma').format(DateTime.parse(lastSyncString))
            : 'Never';
            return ListTile(
              key: ValueKey(item.name),
              leading: ReorderableDragStartListener(
                index: index,
                child: Icon(Icons.drag_handle),
              ),
              title: Text(item.name ?? 'Unnamed Account'),
              subtitle: Text(
                'Type: ${item.type ?? 'N/A'}\nBalance: \$${item.balance?.toStringAsFixed(2) ?? '0.00'}',
              ),
              trailing: Text(
                "Last Sync\n$lastSyncFormatted",
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              onLongPress: () {
                showModalBottomSheet( context: context, builder: (context) {
                  return SizedBox(
                    height: 100,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 30, bottom: 30),
                      child: ListTile(
                        title: Text("Hide ${item.name}?"),
                        trailing: Icon(Icons.visibility_off),
                        onTap: () async {
                          final updated = item.copyWith(hidden: true);
                          await DatabaseHelper().upsertAccountByName(updated);
                          await loadAccounts();
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  );
                });
              },
            );
          }
        ),
      ),
    );
  }
}