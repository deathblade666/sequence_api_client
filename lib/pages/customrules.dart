import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:Seqeunce_API_Client/utils/sequence_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomRules extends StatefulWidget {
  CustomRules(this.prefs,{super.key});
  SharedPreferences prefs;

@override
State<CustomRules> createState() => _CustomRulesState();
}

class _CustomRulesState extends State<CustomRules>{
  TextEditingController _ruleController = TextEditingController();
  TextEditingController _nameController = TextEditingController();
  String ruleId = "";
  String name = "";
  List Rules = [];
  String lastRan = "Never";
  String apitoken = "";

  @override
  void initState(){
    super.initState();
    loadPrefs();
  }

  void loadPrefs(){
    //TODO: restore listitems
    widget.prefs.reload();
    String? sequence_api_token = widget.prefs.getString("sequenceToken");
    widget.prefs.getString(name);
    if (sequence_api_token != null) {
      setState(() {
        apitoken = sequence_api_token;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: IconButton.filled(
        onPressed: () async {
          final result = await showDialog(context: context, builder: (BuildContext context){
            return AlertDialog(
              title: const Text("Trigger a transfer based on custom criteria"),
              actions: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    label: const Text("Name"),
                  ),
                ),
                TextField(
                  controller: _ruleController,
                  decoration: InputDecoration(
                    label: const Text("Custom Rule")
                  ),
                ),
                TextButton(
                  onPressed: (){
                    //TODO: Store prompt values and save to prefs

                    ruleId = _ruleController.text;
                    name = _nameController.text;
                    widget.prefs.setString(name,ruleId);
                    Rules.add(name);
                    print(Rules);
                    Navigator.pop(context, Rules);
                    
                  }, 
                  child: const Text("Save Tigger")
                )
              ],
            );
          });
          setState(() {
             Rules = result;
          });
        }, 
        icon: Icon(Icons.add)
      ),
      body: ListView.builder(
        itemCount: Rules.length,
        itemBuilder: (context, index) {
          final item = Rules[index];
          return ListTile(
            title: Text(item ?? "Unknown"),
            trailing: Text('Last Ran\n$lastRan'),
            onTap: (){
              //TODO: Run Rule Trigger API Event
              //SequenceApi.runTrigger(ruleId,apitoken);
              setState(() {
                lastRan = DateFormat('yyyy-MM-dd hh:mma').format(DateTime.now());
              });
            },
          );
        }),
    );
  }
}