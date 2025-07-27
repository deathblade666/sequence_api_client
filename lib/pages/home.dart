import 'dart:io';

import 'package:Seqeunce_API_Client/pages/accounts.dart';
import 'package:Seqeunce_API_Client/pages/utils/filter_notifier.dart';
import 'package:Seqeunce_API_Client/utils/db/dbhelper.dart';
import 'package:Seqeunce_API_Client/utils/historyprovider.dart';
import 'package:flutter/material.dart';
import 'package:Seqeunce_API_Client/pages/utils/pagecontroller.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  HomePage({super.key});
  PageController homepageController = PageController();

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<AccountPageState> accountPageKey =
      GlobalKey<AccountPageState>();
  String pageName = "Accounts";
  Icon filterIcon = Icon(Icons.filter_alt);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      drawer: SafeArea(
        child: Drawer(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Spacer(flex: 1),
                  const Text("Rule History"),
                  Spacer(flex: 1),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      Provider.of<HistoryProvider>(
                        context,
                        listen: false,
                      ).clearHistory();
                    },
                  ),
                ],
              ),
              Expanded(
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
                            DateFormat(
                              'yyyy-MM-dd hh:mm a',
                            ).format(DateTime.parse(item.timestamp)),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        title: Text(pageName),
        leading: DrawerButton(),
        actions: [
          if (Platform.isWindows || Platform.isLinux || Platform.isMacOS)
            IconButton(
              onPressed: () async {
                accountPageKey.currentState?.refreshAccounts();
              },
              icon: Icon(Icons.refresh),
            ),
          if ((Platform.isAndroid || Platform.isIOS) && pageName != "Rules")
            IconButton(
              onPressed: () async {
                final _accounts = await DatabaseHelper().getAccounts();
                final accountTags = _accounts
                    .map((account) => account.tags)
                    .where((tags) => tags != null && tags.isNotEmpty)
                    .toSet()
                    .toList();
                final selectedTag = await showMenu<String?>(
                  context: context,
                  position: RelativeRect.fromLTRB(100, 100, 0, 0),
                  items: [
                    PopupMenuItem<String?>(value: null, child: Text('None')),
                    ...accountTags.map(
                      (tag) =>
                          PopupMenuItem<String?>(value: tag, child: Text(tag!)),
                    ),
                  ],
                );
                if (selectedTag != selectedTagNotifier.value) {
                  selectedTagNotifier.value = selectedTag;
                }
              },
              icon: filterIcon,
            ),
        ],
      ),
      body: SafeArea(
        child: Views(widget.homepageController, accountPageKey: accountPageKey),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          children: [
            Spacer(flex: 1),
            TextButton(
              onPressed: () {
                setState(() {
                  widget.homepageController.hasClients
                      ? widget.homepageController.jumpToPage(0)
                      : widget.homepageController.initialPage;
                  pageName = "Accounts";
                });
              },
              child: Text("Accounts"),
            ),
            Spacer(),
            TextButton(
              onPressed: () {
                setState(() {
                  widget.homepageController.hasClients
                      ? widget.homepageController.jumpToPage(1)
                      : widget.homepageController.initialPage;
                  pageName = "Rules";
                });
              },
              child: Text("Rules"),
            ),
            Spacer(),
          ],
        ),
      ),
    );
  }
}
