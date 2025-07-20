import 'package:Seqeunce_API_Client/utils/db/dbhelper.dart';
import 'package:Seqeunce_API_Client/utils/secretservice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:intl/intl.dart';
import 'package:Seqeunce_API_Client/utils/sequence_api.dart';

class AccountPage extends StatefulWidget {
  AccountPage({Key? key}) : super(key: key);

  @override
  AccountPageState createState() => AccountPageState();
}

class AccountPageState extends State<AccountPage> {
  List<SequenceAccount> _accounts = [];
  String? apitoken = "";
  bool obscure = true;
  String apiResponse = '';
  TextEditingController token = TextEditingController();
  final secretService = SecretService.instance;
  Color pickerColor = Colors.transparent;

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
    final token = await secretService.getToken();
    if (token == null || token.isEmpty) {
      print("No token found — skipping account refresh.");
      return;
    }
    final now = DateTime.now().toIso8601String();
    final accountsFromApi = await SequenceApi.getAccounts(token);
    for (var account in accountsFromApi) {
      final updatedAccount = account.copyWith(lastsync: now);
      await DatabaseHelper().upsertAccountByName(updatedAccount);
    }
    await loadAccounts();
  }

  void loadPrefs() async {
    final existingToken = await secretService.getToken();
    if (existingToken != null) {
      setState(() {
        token.text = existingToken;
      });
    }
  }

  Future<void> updateOrderInDb() async {
    for (int i = 0; i < _accounts.length; i++) {
      await DatabaseHelper().updateAccountOrder(_accounts[i].name!, i);
    }
    loadAccounts();
  }

  void onReorder(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _accounts.removeAt(oldIndex);
      _accounts.insert(newIndex, item);
    });
    await updateOrderInDb();
  }

  Color hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  String colorToHex(Color color, {bool leadingHashSign = true}) {
    final alpha = (color.alpha).toRadixString(16).padLeft(2, '0');
    final red = (color.red).toRadixString(16).padLeft(2, '0');
    final green = (color.green).toRadixString(16).padLeft(2, '0');
    final blue = (color.blue).toRadixString(16).padLeft(2, '0');
    return '${leadingHashSign ? '#' : ''}$alpha$red$green$blue';
  }

  void updateColor(color){
    setState(() => pickerColor = color);
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
                                    onSubmitted: (value) async {
                                      if (value.isEmpty) {
                                        await secretService.deleteToken();
                                      } else {
                                        await secretService.saveToken(value);
                                      }
                                      refreshAccounts();
                                      Navigator.pop(context, value);
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
                                onPressed: () async {
                                  final apitoken = token.text;
                                  if (apitoken.isEmpty) {
                                    await secretService.deleteToken();
                                  } else {
                                    await secretService.saveToken(apitoken);
                                  }
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
                                  constraints: BoxConstraints(maxHeight: 270),
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
            final lastSyncString = item.lastsync;
            final lastSyncFormatted = lastSyncString != null
            ? DateFormat('yyyy-MM-dd hh:mma').format(DateTime.parse(lastSyncString))
            : 'Never';
            List<String>? tagList = item.tags?.split(',');
            return Card(
              key: ValueKey(item.id),
              margin: EdgeInsets.symmetric(horizontal: 3, vertical: 3),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                leading: ReorderableDragStartListener(
                  index: index,
                  child: Icon(Icons.drag_handle),
                ),
                title: Text(item.name ?? 'Unnamed Account'),
                subtitle: Text(
                  'Type: ${item.type ?? 'N/A'}\nBalance: \$${item.balance?.toStringAsFixed(2) ?? '0.00'}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(padding: EdgeInsetsGeometry.directional(end: 15)),
                    Text(
                      "Last Sync\n$lastSyncFormatted\n",
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      textAlign: TextAlign.right,
                    ),
                    Padding(
                      padding: EdgeInsetsGeometry.directional(start: 15),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children:[
                          ...(item.tags ?? '')
                          .split(',')
                          .where((tag) => tag.trim().isNotEmpty)
                          .map((tag) => Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: hexToColor(item.color!),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: hexToColor(item.color!)),
                            ),
                            child: Text(
                              tag.trim(),
                              style: TextStyle(fontSize: 12, color: Colors.white),
                            ),
                          ))
                          .toList() 
                        ]
                      ),
                    ),
                  ],
                ),
                onLongPress: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) {
                      return SizedBox(
                        height: 300,
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsetsGeometry.directional(top: 30),
                              child: ListTile(
                                title: Text("Hide ${item.name}?"),
                                trailing: Icon(Icons.visibility_off),
                                onTap: () async {
                                  final updated = item.copyWith(hidden: true);
                                  await DatabaseHelper().upsertAccountByName(updated);
                                  loadAccounts();
                                  Navigator.pop(context);
                                },
                              ),
                            ),
                            Wrap(   //TODO: add methos to remove tags
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                ...(item.tags ?? '')
                                .split(',')
                                .where((tag) => tag.trim().isNotEmpty)
                                .map((tag) => Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: hexToColor(item.color!),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: hexToColor(item.color!)),
                                  ),
                                  child: Text(
                                    tag.trim(),
                                    style: TextStyle(fontSize: 12, color: Colors.white),
                                  ),
                                ))
                                .toList(),
                                if ((item.tags ?? '').trim().isEmpty)
                                GestureDetector(
                                  onTap: () {
                                    showDialog(context: context, builder: (BuildContext context) {
                                      TextEditingController _tagController = TextEditingController();
                                      return AlertDialog(
                                        title: Text("Create Tag for ${item.name}"),
                                        actions: [
                                          TextField(
                                            decoration: InputDecoration(
                                              label: const Text("Tag Name"),
                                            ),
                                            controller: _tagController,
                                            autofocus: true,
                                            onSubmitted: (value) async{
                                              String hexColor = colorToHex(pickerColor);
                                              SequenceAccount updatedAccount = SequenceAccount(
                                                id: item.id, 
                                                balance: item.balance,
                                                name: item.name,
                                                type: item.type,
                                                color: hexColor,
                                                lastsync: item.lastsync,
                                                hidden: item.hidden,
                                                tags: value,
                                                orderIndex: item.orderIndex
                                              );
                                              await DatabaseHelper().updateAccount(updatedAccount);
                                              loadAccounts();
                                              _tagController.clear();
                                              Navigator.of(context).pop();
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                          Padding(padding: EdgeInsetsGeometry.directional(bottom: 15)),
                                          ColorPicker(
                                            pickerColor: pickerColor, 
                                            onColorChanged: updateColor,
                                            displayThumbColor: true,
                                          ),
                                          TextButton(
                                            onPressed: () async {
                                              String hexColor = colorToHex(pickerColor);
                                              SequenceAccount updatedAccount = SequenceAccount(
                                                id: item.id, 
                                                balance: item.balance,
                                                name: item.name,
                                                type: item.type,
                                                color: hexColor,
                                                lastsync: item.lastsync,
                                                hidden: item.hidden,
                                                tags: _tagController.text,
                                                orderIndex: item.orderIndex
                                              );
                                              await DatabaseHelper().updateAccount(updatedAccount);
                                              loadAccounts();
                                              _tagController.clear();
                                              Navigator.of(context).pop();
                                              Navigator.of(context).pop();
                                            },
                                            child: const Text("Done"),
                                          ),
                                        ],
                                      );
                                    });
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.blueAccent,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'Add Tag',
                                      style: TextStyle(fontSize: 12, color: Colors.black87),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            );
          }
        ),
      ),
    );
  }
}