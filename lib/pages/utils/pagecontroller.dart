import 'package:flutter/material.dart';
import 'package:Seqeunce_API_Client/pages/accounts.dart';
import 'package:Seqeunce_API_Client/pages/rules.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Views extends StatefulWidget {
  Views(this.prefs,{super.key, required homepageController});
  final homepageController = PageController();
  SharedPreferences prefs;

  @override
  State<Views> createState() => _ViewsState();
}

class _ViewsState extends State<Views> {
  final homepageController = PageController();

  void initState(){
    super.initState();
    homepageController.hasClients ? homepageController.jumpToPage(1) : homepageController.initialPage;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: 1020,
        child: PageView(  //TODO: disabled scroll once bottom nuttons switch screens
          controller: homepageController,
          children: [
            AccountPage(widget.prefs),
            TransferRules(widget.prefs)
          ],
        ),
      ),
    );
  }
}