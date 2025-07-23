import 'package:Seqeunce_API_Client/utils/db/dbhelper.dart';
import 'package:Seqeunce_API_Client/utils/historyprovider.dart';
import 'package:Seqeunce_API_Client/utils/secretservice.dart';
import 'package:Seqeunce_API_Client/utils/sequence_api.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class TransferRules extends StatefulWidget {
  TransferRules({super.key});

@override
State<TransferRules> createState() => _TransferRulesState();
}

class _TransferRulesState extends State<TransferRules>{
  TextEditingController _ruleController = TextEditingController();
  TextEditingController _nameController = TextEditingController();
  TextEditingController _tokencontroller = TextEditingController();
  String ruleId = "";
  String name = "";
  String token = "";
  List rules = [];
  String lastRan = "Never";
  String apitoken = "";

  @override
  void initState(){
    super.initState();
    _loadRules();
  }

  Future<void> _loadRules() async {
    final ruleList = await DatabaseHelper().getRules();
    setState(() {
      rules = ruleList;
    });
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final rule = rules.removeAt(oldIndex);
      rules.insert(newIndex, rule);
    });
    for (int i = 0; i < rules.length; i++) {
      await DatabaseHelper().updateRuleOrder(rules[i].id, i);
    }
  }

  Future<void> debugHistory() async {
    final historyItems = await DatabaseHelper().getHistory();
    for (var item in historyItems) {
      print('Name: ${item.name} at ${item.timestamp}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      floatingActionButton: IconButton.filled(
        onPressed: () async {
          await showModalBottomSheet(context: context, builder: (BuildContext context){
            return SizedBox(
              height: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(padding: EdgeInsetsGeometry.directional(top: 15)),
                  Center(
                    child: const Text("Trigger a Rule"),
                  ),
                  Padding(
                    padding: EdgeInsetsGeometry.directional(start: 15, end: 15),
                    child: TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        label: const Text("Name"),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsetsGeometry.directional(start: 15, end: 15),
                    child: TextField(
                      controller: _ruleController,
                      decoration: InputDecoration(
                        label: const Text("Rule ID")
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsetsGeometry.directional(start: 15, end: 15),
                    child: TextField(
                      controller: _tokencontroller,
                      decoration: InputDecoration(
                        label: const Text("Token")
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                    child: TextButton(
                      onPressed: () async {
                        ruleId = _ruleController.text;
                        name = _nameController.text;
                        final rawToken = _tokencontroller.text;
                        final encryptedToken = await SecretService.instance.encryptToken(rawToken);
                        final db = await DatabaseHelper().database;
                        final maxOrderResult = await db.rawQuery('SELECT MAX(order_index) as max_order FROM rules');
                        final maxOrder = maxOrderResult.first['max_order'] as int? ?? -1;
                        await db.insert('rules', {
                          'name': name,
                          'ruleid': ruleId,
                          'timestamp': 'Never',
                          'token': encryptedToken,
                          'order_index': maxOrder + 1,
                        });
                        await _loadRules();
                        _nameController.clear();
                        _ruleController.clear();
                        _tokencontroller.clear();
                        Navigator.pop(context);
                      },
                      child: const Text("Save Trigger")
                    ),
                  )
                ],
              ),
            );
          });
        }, 
        icon: Icon(Icons.add)
      ),
      body: ReorderableListView.builder(
        buildDefaultDragHandles: false,
        onReorder: _onReorder,
        itemCount: rules.length,
        itemBuilder: (context, index) {
          final rule = rules[index];
          return Card(
              key: Key(rule.id.toString()),
              margin: EdgeInsets.symmetric(horizontal: 3, vertical: 3),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                leading: ReorderableDragStartListener(
                  index: index,
                  child: Icon(Icons.drag_handle),
                ),
                title: Text(rule.name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      rule.timestamp == 'Never' || rule.timestamp.isEmpty
                      ? 'Last Ran\nNever'
                      : 'Last Ran\n${DateFormat('MM/dd hh:mma').format(DateTime.parse(rule.timestamp))}',
                    ),
                  ],
                ),
              onLongPress: () async {
                final encryptedToken = rule.token;
                final decryptedToken = await SecretService.instance.decryptToken(encryptedToken);
                _nameController.text = rule.name;
                _ruleController.text = rule.ruleId;
                _tokencontroller.text = decryptedToken!;
                showModalBottomSheet(context: context, builder: (BuildContext context) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: SizedBox(
                      height: 300,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Center(
                            child: Text("Edit"),
                          ),
                          Padding(
                            padding: EdgeInsetsGeometry.directional(start: 15, end: 15),
                            child: TextField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                label: const Text("Name"),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsetsGeometry.directional(start: 15, end: 15),
                            child: TextField(
                              controller: _ruleController,
                              decoration: InputDecoration(
                                label: const Text("Rule ID")
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsetsGeometry.directional(start: 15, end: 15),
                            child: TextField(
                              controller: _tokencontroller,
                              decoration: InputDecoration(
                                label: const Text("Token")
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                            child: Row(
                              children: [
                                Spacer(flex: 1,),
                                TextButton(
                                  onPressed: () async {
                                    final db = await DatabaseHelper().database;
                                    await db.delete(
                                      'rules',
                                      where: 'id = ?',
                                      whereArgs: [rule.id],
                                    );
                                    final updatedRules = await DatabaseHelper().getRules();
                                    setState(() {
                                      rules = updatedRules;
                                    });
                                    Navigator.pop(context);
                                  }, 
                                  child: Text("Delete")
                                ),
                                Spacer(flex: 1,),
                                TextButton(
                                  onPressed: () async {
                                    final updatedName = _nameController.text;
                                    final updatedRuleId = _ruleController.text;
                                    final rawToken = _tokencontroller.text;
                                    final encryptedToken = await SecretService.instance.encryptToken(rawToken);
                                    final db = await DatabaseHelper().database;
                                    await db.update(
                                      'rules',
                                      {
                                        'name': updatedName,
                                        'ruleid': updatedRuleId,
                                        'token': encryptedToken,
                                        'timestamp': rule.timestamp,
                                      },
                                      where: 'id = ?',
                                      whereArgs: [rule.id],
                                    );
                                    final updatedRules = await DatabaseHelper().getRules();
                                    setState(() {
                                      rules = updatedRules;
                                    });
                                    _nameController.clear();
                                    _ruleController.clear();
                                    _tokencontroller.clear();
                                    Navigator.pop(context);
                                  },
                                  child: Text("Save") 
                                ),
                                Spacer(flex: 1,)
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                });
              },
              onTap: () async {
                final decryptedToken = await SecretService.instance.decryptToken(rule.token);
                if (decryptedToken == null) {
                  print("❌ Unable to decrypt token for rule ${rule.name}");
                  return;
                }
                var statusCode = await SequenceApi.runTrigger(rule.ruleId, decryptedToken);
                Provider.of<HistoryProvider>(context, listen: false)
                .addHistory("${rule.name} - $statusCode");
                final db = await DatabaseHelper().database;
                await db.update(
                  'rules',
                    {'timestamp': DateTime.now().toIso8601String()},
                    where: 'id = ?',
                    whereArgs: [rule.id],
                );
                final updatedRules = await DatabaseHelper().getRules();
                setState(() {
                  rules = updatedRules;
                  lastRan = DateFormat('yyyy-MM-dd hh:mma').format(DateTime.now());
                });
              },
            )
          );
        },
      ),
    );
  }
}