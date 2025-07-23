import 'package:Seqeunce_API_Client/pages/utils/filter_notifier.dart';
import 'package:Seqeunce_API_Client/utils/db/dbhelper.dart';
import 'package:Seqeunce_API_Client/utils/secretservice.dart';
import 'package:Seqeunce_API_Client/utils/tags.dart';
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
  TextEditingController _tagController = TextEditingController();

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
        child: ValueListenableBuilder<String?>(
          valueListenable: selectedTagNotifier,
          builder: (context, selectedTag, _) {
            final filteredAccounts = selectedTag == null
              ? _accounts
              : _accounts.where((account) {
                final tags = account.tags?.split(',') ?? [];
                return tags.map((t) => t.trim()).contains(selectedTag);
              }).toList();
            return ReorderableListView.builder(
              buildDefaultDragHandles: false,
              itemCount: filteredAccounts.length,
              onReorder: onReorder,
              itemBuilder: (context, index) {
                final item = filteredAccounts[index];
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
                        Wrap(
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
                          ]
                        ),
                        Padding(padding: EdgeInsetsGeometry.directional(end: 15)),
                        Text(
                          "Last Sync\n$lastSyncFormatted\n",
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          textAlign: TextAlign.right,
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
                                FutureBuilder<List<Tag>>(
                                  future: DatabaseHelper().fetchTagsByType('account'),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) return CircularProgressIndicator();
                                    final tagsList = snapshot.data!;
                                    final currentTags = item.tags?.split(',').map((t) => t.trim()).toList() ?? [];
                                    final filteredTags = tagsList.where((tag) => !currentTags.contains(tag.name)).toList();
                                    return Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(left: 15),
                                          child: Align(alignment: Alignment.centerLeft,
                                            child: Text("Current Tag"),
                                          ),
                                        ),
                                        if (item.tags != null && item.tags!.isNotEmpty)
                                        GestureDetector(
                                          onTap: () async {
                                            final clearedAccount = item.copyWith(tags: null, color: null);
                                            await DatabaseHelper().updateAccount(clearedAccount);
                                            selectedTagNotifier.value = null;
                                            loadAccounts();
                                          },
                                          onLongPress: () async {
                                            final confirmed = await showDialog<bool>(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: Text("Delete '${item.tags}'?"),
                                                content: Text("This will remove the tag from the database and from any account using it."),
                                                actions: [
                                                  TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Cancel")),
                                                  TextButton(onPressed: () => Navigator.pop(context, true), child: Text("Delete")),
                                                ],
                                              ),
                                            );
                                            if (confirmed == true) {
                                              await DatabaseHelper().deleteTag(item.tags!, 'account');
                                              await DatabaseHelper().clearTagFromAccounts(item.tags!);
                                              selectedTagNotifier.value = null;
                                              loadAccounts();
                                            }
                                          },
                                          child: Container(
                                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: hexToColor(item.color ?? '#000000'),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(color: hexToColor(item.color ?? '#000000')),
                                            ),
                                            child: Text(
                                              item.tags!,
                                              style: TextStyle(fontSize: 12, color: Colors.white),
                                            ),
                                          ),
                                        ),
                                        Divider(thickness: 1.5,),
                                        Padding(
                                          padding: const EdgeInsetsGeometry.directional(start: 15, end: 15),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(bottom: 15),
                                                child: Align(
                                                  alignment: Alignment.center,
                                                  child: Text("Suggested tags"),
                                                ),
                                              ),
                                              Spacer(),
                                              GestureDetector(
                                                onTap: () {
                                                  showDialog(context: context, builder: (BuildContext context) {
                                                    return AlertDialog(
                                                      title: Text("Create tag for ${item.name}"),
                                                      content: Column(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          TextField(
                                                            decoration: InputDecoration(labelText: "Tag Name"),
                                                            controller: _tagController,
                                                            autofocus: true,
                                                          ),
                                                          const SizedBox(height: 15),
                                                          ColorPicker(
                                                            pickerColor: pickerColor,
                                                            onColorChanged: updateColor,
                                                            displayThumbColor: true,
                                                          ),
                                                        ],
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () async {
                                                            final tagName = _tagController.text.trim();
                                                            final hexColor = colorToHex(pickerColor);
                                                            if (tagName.isEmpty) return;
                                                            await DatabaseHelper().createTag(tagName, 'account', hexColor);
                                                            final updatedAccount = item.copyWith(
                                                              tags: tagName,
                                                              color: hexColor,
                                                            );
                                                            await DatabaseHelper().updateAccount(updatedAccount);
                                                            loadAccounts();
                                                            _tagController.clear();
                                                            Navigator.of(context).pop();
                                                            Navigator.of(context).pop();
                                                          },
                                                          child: Text("Save"),
                                                        )
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
                                                    style: TextStyle(fontSize: 12, color: Colors.white),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 4,
                                          children: [
                                            ...filteredTags.map((tag) => GestureDetector(
                                              onLongPress: () async {
                                                final confirm = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
                                                  title: Text("Delete '${tag.name}' tag?"),
                                                  content: Text("This will remove the tag from the database and from any account that uses it."),
                                                  actions: [
                                                    TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Cancel")),
                                                    TextButton(onPressed: () => Navigator.pop(context, true), child: Text("Delete")),
                                                  ],
                                                ));
                                                if (confirm == true) {
                                                  await DatabaseHelper().deleteTag(tag.name, tag.type);
                                                  await DatabaseHelper().clearTagFromAccounts(tag.name);
                                                  loadAccounts();
                                                }
                                              },
                                              onTap: () async {
                                                final updatedAccount = item.copyWith(
                                                  tags: tag.name,
                                                  color: tag.color,
                                                );
                                                await DatabaseHelper().updateAccount(updatedAccount);
                                                loadAccounts();
                                              },
                                              child: Container(
                                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: hexToColor(tag.color),
                                                  borderRadius: BorderRadius.circular(20),
                                                  border: Border.all(color: hexToColor(tag.color)),
                                                ),
                                                child: Text(
                                                  tag.name,
                                                  style: TextStyle(fontSize: 12, color: Colors.white),
                                                ),
                                              ),
                                            )),
                                          ],
                                        ),
                                      ],
                                    );
                                  },
                                )
                              ],
                            )
                          );       
                        },
                      );
                    },
                  ),
                );
              }
            );
          }
        ),
      )
    );
  }
}