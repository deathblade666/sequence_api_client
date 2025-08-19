import 'dart:ffi';

import 'package:flutter/material.dart';

class Rule_Sim extends StatelessWidget {
  Rule_Sim({super.key});

  @override
  Widget build(BuildContext context) {
    List simRules = [];
    List ruleFucntions = [];
    List<String> conditionItems = <String>["Day of the Month", "Transfer Amount", "Balance"];
    List<String> conditionOperator = <String>[
      "equals",
      "is not equals to",
      "is later than",
      "is equal to or later than",
      "is ealier than",
      "is equal to or earlier than",
    ];
    int items = 2;
    List<String> conditionAndOr = <String>["and", "or"];
    List<String> accounts = ["Capital One"];
    TextEditingController _name = TextEditingController();

    return Scaffold(
      body: ListView.builder(
        itemCount: simRules.length,
        itemBuilder: (BuildContext context, index) {
          ListTile();
        },
      ),
      floatingActionButton: IconButton.filled(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (context) {
              String dropdownValue = conditionItems.first;
              String dropdownOpsValue = conditionOperator.first;
              String dropdownandorValue = conditionAndOr.first;
              String accountFirst = accounts.first;
              double conditionBox = 0;
              bool showAndOr = false;
              return StatefulBuilder(
                builder: (context, setState) {
                  return SingleChildScrollView(
                    child: SizedBox(
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(onPressed: () async {}, icon: Icon(Icons.delete)),
                                Spacer(),
                                IconButton(onPressed: () async {}, icon: Icon(Icons.save)),
                              ],
                            ),
                            Column(
                              children: [
                                Text("Create a rule to simulate!"),

                                TextField(
                                  controller: _name,
                                  decoration: InputDecoration(label: Text("Name")),
                                ),

                                Padding(
                                  padding: EdgeInsets.only(top: 8),
                                  child: Row(
                                    children: [
                                      Text("Tigger:    "),
                                      Text("Funds received in    "),
                                      //Spacer(),
                                      DropdownButton(
                                        value: accountFirst,
                                        items: accounts.map<DropdownMenuItem<String>>((String value) {
                                          return DropdownMenuItem<String>(value: value, child: Text(value));
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            dropdownValue = value!;
                                          });
                                        },
                                      ),
                                      Spacer(),
                                    ],
                                  ),
                                ),

                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text("Conditions:"),
                                      Spacer(),
                                      IconButton(
                                        onPressed: () {
                                          if (items == 1) {
                                            setState(() => conditionBox = 150);
                                          }
                                          if (items == 2) {
                                            setState(() => conditionBox = 340);
                                            setState(() => showAndOr = true);
                                          }
                                        },
                                        icon: Icon(Icons.add),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Container(
                                    height: conditionBox,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.all(Radius.circular(15)),
                                      border: BoxBorder.all(width: 0.5, color: Theme.of(context).colorScheme.onSurface),
                                    ),
                                    alignment: Alignment.topLeft,
                                    child: Padding(
                                      padding: const EdgeInsets.all(5),
                                      child: ListView.builder(
                                        itemCount: items,
                                        itemBuilder: (BuildContext context, index) {
                                          return ListTile(
                                            leading: Text("If"),
                                            title: Column(
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                  children: [
                                                    DropdownButton(
                                                      value: dropdownValue,
                                                      items: conditionItems.map<DropdownMenuItem<String>>((
                                                        String value,
                                                      ) {
                                                        return DropdownMenuItem<String>(
                                                          value: value,
                                                          child: Text(value),
                                                        );
                                                      }).toList(),
                                                      onChanged: (value) {
                                                        setState(() {
                                                          dropdownValue = value!;
                                                        });
                                                      },
                                                    ),
                                                    DropdownButton(
                                                      value: dropdownOpsValue,
                                                      items: conditionOperator.map<DropdownMenuItem<String>>((
                                                        String value,
                                                      ) {
                                                        return DropdownMenuItem<String>(
                                                          value: value,
                                                          child: Text(value),
                                                        );
                                                      }).toList(),
                                                      onChanged: (value) {
                                                        setState(() {
                                                          dropdownOpsValue = value!;
                                                        });
                                                      },
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                  children: [
                                                    DropdownButton(
                                                      value: dropdownValue,
                                                      items: conditionItems.map<DropdownMenuItem<String>>((
                                                        String value,
                                                      ) {
                                                        return DropdownMenuItem<String>(
                                                          value: value,
                                                          child: Text(value),
                                                        );
                                                      }).toList(),
                                                      onChanged: (value) {
                                                        setState(() {
                                                          dropdownValue = value!;
                                                        });
                                                      },
                                                    ),
                                                    DropdownButton(
                                                      value: dropdownOpsValue,
                                                      items: conditionOperator.map<DropdownMenuItem<String>>((
                                                        String value,
                                                      ) {
                                                        return DropdownMenuItem<String>(
                                                          value: value,
                                                          child: Text(value),
                                                        );
                                                      }).toList(),
                                                      onChanged: (value) {
                                                        setState(() {
                                                          dropdownOpsValue = value!;
                                                        });
                                                      },
                                                    ),
                                                  ],
                                                ),
                                                Visibility(
                                                  visible: showAndOr,
                                                  child: DropdownButton(
                                                    value: dropdownandorValue,
                                                    items: conditionAndOr.map<DropdownMenuItem<String>>((String value) {
                                                      return DropdownMenuItem<String>(value: value, child: Text(value));
                                                    }).toList(),
                                                    onChanged: (value) {
                                                      setState(() {
                                                        dropdownandorValue = value!;
                                                      });
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                            trailing: IconButton(onPressed: () {}, icon: Icon(Icons.delete)),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text("Actions:"),
                                      Spacer(),
                                      IconButton(onPressed: () {}, icon: Icon(Icons.add)),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Container(
                                    height: 500,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.all(Radius.circular(15)),
                                      border: BoxBorder.all(width: 0.5, color: Theme.of(context).colorScheme.onSurface),
                                    ),
                                    alignment: Alignment.topLeft,
                                    child: Padding(
                                      padding: const EdgeInsets.all(15),
                                      child: Padding(
                                        padding: const EdgeInsets.all(5),
                                        child: ListView.builder(
                                          itemCount: 2,
                                          itemBuilder: (BuildContext context, index) {
                                            return ListTile(
                                              leading: Text("If"),
                                              title: Column(
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                    children: [
                                                      DropdownButton(
                                                        value: dropdownValue,
                                                        items: conditionItems.map<DropdownMenuItem<String>>((
                                                          String value,
                                                        ) {
                                                          return DropdownMenuItem<String>(
                                                            value: value,
                                                            child: Text(value),
                                                          );
                                                        }).toList(),
                                                        onChanged: (value) {
                                                          setState(() {
                                                            dropdownValue = value!;
                                                          });
                                                        },
                                                      ),
                                                      DropdownButton(
                                                        value: dropdownOpsValue,
                                                        items: conditionOperator.map<DropdownMenuItem<String>>((
                                                          String value,
                                                        ) {
                                                          return DropdownMenuItem<String>(
                                                            value: value,
                                                            child: Text(value),
                                                          );
                                                        }).toList(),
                                                        onChanged: (value) {
                                                          setState(() {
                                                            dropdownOpsValue = value!;
                                                          });
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                    children: [
                                                      DropdownButton(
                                                        value: dropdownValue,
                                                        items: conditionItems.map<DropdownMenuItem<String>>((
                                                          String value,
                                                        ) {
                                                          return DropdownMenuItem<String>(
                                                            value: value,
                                                            child: Text(value),
                                                          );
                                                        }).toList(),
                                                        onChanged: (value) {
                                                          setState(() {
                                                            dropdownValue = value!;
                                                          });
                                                        },
                                                      ),
                                                      DropdownButton(
                                                        value: dropdownOpsValue,
                                                        items: conditionOperator.map<DropdownMenuItem<String>>((
                                                          String value,
                                                        ) {
                                                          return DropdownMenuItem<String>(
                                                            value: value,
                                                            child: Text(value),
                                                          );
                                                        }).toList(),
                                                        onChanged: (value) {
                                                          setState(() {
                                                            dropdownOpsValue = value!;
                                                          });
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              trailing: IconButton(onPressed: () {}, icon: Icon(Icons.delete)),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },

        icon: Icon(Icons.add),
      ),
    );
  }
}
