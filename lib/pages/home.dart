import 'dart:io';

import 'package:Seqeunce_API_Client/pages/accounts.dart';
import 'package:Seqeunce_API_Client/utils/dbhelper.dart';
import 'package:Seqeunce_API_Client/utils/history.dart';
import 'package:Seqeunce_API_Client/utils/historyprovider.dart';
import 'package:flutter/material.dart';
import 'package:Seqeunce_API_Client/pages/utils/pagecontroller.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class HomePage extends StatefulWidget {
  HomePage(this.prefs,{super.key});
  SharedPreferences prefs;
  PageController homepageController = PageController();



  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<AccountPageState> accountPageKey = GlobalKey<AccountPageState>();
  


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        drawer: Drawer(
          child: ExpansionTile(
            title: const Text("History"),
            children: [
              SizedBox(
                height: 750,
                child: Consumer<HistoryProvider>(
                  builder: (context, historyProvider, _) {
                    final history = historyProvider.items;
                    if (history.isEmpty) {
                      return const Center(child: Text("No history yet"));
                    }

                    return ListView.builder(
                      itemCount: history.length,
                      itemBuilder: (context, index) {
                        final item = history[index];
                        return ListTile(
                          title: Text(item.name),
                          subtitle: Text(
                            DateFormat('yyyy-MM-dd hh:mm a')
                            .format(DateTime.parse(item.timestamp)),
                          ),
                        );
                      }
                    );
                  },
                ),
              ),
            ]
          )
        ),
        appBar: AppBar(
          title: const Text("Sequence API Client"),
          leading: DrawerButton(),
          actions: [
            if (Platform.isWindows || Platform.isLinux || Platform.isMacOS)
              IconButton(
                onPressed: () async {
                 accountPageKey.currentState?.refreshAccounts();
                },
                icon: Icon(Icons.refresh),
              ),
            ],
        ),
        body: Views(widget.prefs,widget.homepageController, accountPageKey: accountPageKey,),
        bottomNavigationBar: BottomAppBar(
          child: Row(
            children: [
              Spacer(flex: 1,),
              TextButton(
                onPressed: () {
                  setState(() {
                    widget.homepageController.hasClients ? widget.homepageController.jumpToPage(0) : widget.homepageController.initialPage;
                  });
                },
                child: Text("Home"),
              ),
              Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    widget.homepageController.hasClients ? widget.homepageController.jumpToPage(1) : widget.homepageController.initialPage;
                  });
                },
                child: Text("Rules"),
              ),
              Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    widget.homepageController.hasClients ? widget.homepageController.jumpToPage(2) : widget.homepageController.initialPage;
                  });
                  //TODO: Create List widget and prompt to define custom rules to run without needing to login to sequence
                },
                child: Text("Custom"),
               ),
              Spacer()
            ],
          ),
        ),
      )
    );
  }
}