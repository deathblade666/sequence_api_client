import 'package:Seqeunce_API_Client/utils/db/dbhelper.dart';
import 'package:Seqeunce_API_Client/utils/historyprovider.dart';
import 'package:Seqeunce_API_Client/utils/rules.dart';
import 'package:Seqeunce_API_Client/utils/secretservice.dart';
import 'package:Seqeunce_API_Client/utils/sequence_api.dart';
import 'package:Seqeunce_API_Client/utils/tags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
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
  bool obscure = true;
  Color pickerColor = Colors.transparent;
  TextEditingController _tagController = TextEditingController();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      floatingActionButton: IconButton.filled(
        onPressed: () async {
          await showModalBottomSheet(context: context, builder: (BuildContext context){
            return StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
              return SizedBox(
              height: 800,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Padding(
                          padding: const EdgeInsetsGeometry.directional(top: 8, end: 8),
                          child: IconButton(
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
                            icon: Icon(Icons.save)
                          ),
                        )
                      ],
                    ),
                    Center(
                      child: const Text("Create a Rule Trigger"),
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
                      padding: EdgeInsetsGeometry.directional(start: 15, end:15),
                      child: TextField(
                        controller: _tokencontroller,
                        decoration: InputDecoration(
                          label: const Text("Token"),
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
                          icon: Icon(Icons.remove_red_eye_outlined),
                          )
                        ),
                        obscureText: obscure,
                      ),
                    ),
                    Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom))
                  ]
                )
              );
            });
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
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: ((rule.tags ?? '') as String)
                    .split(',')
                    .map((tag) => tag.trim())
                    .where((tag) => tag.isNotEmpty)
                    .map<Widget>((tag) => Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: hexToColor(rule.color ?? '#000000'),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: hexToColor(rule.color ?? '#000000')),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ))
                    .toList(),
                  ),
                  Padding(padding: EdgeInsetsGeometry.directional(end: 15)),
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
                  Rule localItem = rule;
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: SizedBox(
                      height: 800,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
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
                                icon: Icon(Icons.delete)
                              ),
                              Spacer(),
                              IconButton(
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
                                icon: Icon(Icons.save),
                              ),
                            ],
                          ),
                          Text("Edit ${rule.name}"),
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
                            padding: EdgeInsetsGeometry.directional(start: 15, end: 15, bottom: 15),
                            child: TextField(
                              controller: _tokencontroller,
                              decoration: InputDecoration(
                                label: const Text("Token")
                              ),
                            ),
                          ),
                          StatefulBuilder( builder: (context, setState) {
                            Future<List<Tag>> futureTags = DatabaseHelper().fetchTagsByType('rule');
                            return FutureBuilder<List<Tag>>( future: futureTags, builder: (context, snapshot) {
                              if (!snapshot.hasData) return CircularProgressIndicator();
                              final tagsList = snapshot.data!;
                              final currentTags = localItem.tags?.split(',').map((t) => t.trim()).toList() ?? [];
                              final filteredTags = tagsList.where((tag) => !currentTags.contains(tag.name)).toList();
                              return Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 15),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                       child: Text("Current Tag"),
                                    ),
                                  ),
                                  if (localItem.tags != null && localItem.tags!.isNotEmpty)
                                  GestureDetector(
                                    onTap: () async {
                                      final clearedRule = localItem.copyWith(tags: null, color: null);
                                      await DatabaseHelper().updateRule(clearedRule);
                                      _loadRules();
                                      setState(() {
                                        localItem = clearedRule;
                                      });
                                    },
                                    onLongPress: () async {
                                      final confirmed = await showDialog<bool>( context: context, builder: (context) => AlertDialog(
                                        title: Text("Delete '${localItem.tags}'?"),
                                        content: Text("This will remove the tag from the database and from any account using it."),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Cancel")),
                                          TextButton(onPressed: () => Navigator.pop(context, true), child: Text("Delete")),
                                        ],
                                      ));
                                      if (confirmed == true) {                              
                                        await DatabaseHelper().deleteTag(localItem.tags!, 'rule');
                                        await DatabaseHelper().clearTagFromRule(localItem.tags!);
                                        _loadRules();
                                        setState(() {
                                          localItem = localItem.copyWith(tags: null, color: null);
                                        });
                                      }
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: hexToColor(localItem.color ?? '#000000'),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: hexToColor(localItem.color ?? '#000000')),
                                      ),
                                      child: Text(
                                        localItem.tags!,
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
                                            child: Text("Available tags"),
                                          ),
                                        ),
                                        Spacer(),
                                        GestureDetector(
                                          onTap: () {
                                            showDialog(context: context, builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: Text("Create tag for ${rule.name}"),
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
                                                      await DatabaseHelper().createTag(tagName, 'rule', hexColor);
                                                      final updatedRule = rule.copyWith(
                                                        tags: tagName,
                                                        color: hexColor,
                                                      );
                                                      await DatabaseHelper().updateRule(updatedRule);
                                                      _loadRules();
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
                                              color: Theme.of(context).colorScheme.primary,
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              'Create New Tag',
                                              style: TextStyle(fontSize: 12, color: Colors.black),
                                            ),
                                          ),
                                        ),
                                      ]
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
                                            content: Text("This will remove the tag from the database and from any Rule that uses it."),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Cancel")),
                                              TextButton(onPressed: () => Navigator.pop(context, true), child: Text("Delete")),
                                            ],
                                          ));
                                          if (confirm == true) {
                                            await DatabaseHelper().deleteTag(tag.name, tag.type);
                                            await DatabaseHelper().clearTagFromRule(tag.name);
                                            _loadRules();
                                            futureTags = DatabaseHelper().fetchTagsByType('rule');
                                            localItem = localItem.copyWith(
                                              tags: null,
                                              color: null,
                                            );
                                            setState(() {});
                                          }
                                        },
                                        onTap: () async {
                                          final updatedRule = rule.copyWith(
                                            tags: tag.name,
                                            color: tag.color,
                                          );                                                    
                                          await DatabaseHelper().updateRule(updatedRule);
                                          _loadRules();
                                          localItem = updatedRule;
                                          futureTags = DatabaseHelper().fetchTagsByType('rule');
                                          setState(() {});
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
                            });
                          })
                        ]
                      )
                    )
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