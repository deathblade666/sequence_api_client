import 'package:Seqeunce_API_Client/pages/customrules.dart';
import 'package:flutter/material.dart';
import 'package:Seqeunce_API_Client/pages/accounts.dart';
import 'package:Seqeunce_API_Client/pages/rules.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Views extends StatefulWidget {
  Views(this.prefs,this.homepageController,{super.key});
  PageController homepageController;
  SharedPreferences prefs;

  @override
  State<Views> createState() => _ViewsState();
}

class _ViewsState extends State<Views> {

  void initState(){
    super.initState();
    widget.homepageController.hasClients ? widget.homepageController.jumpToPage(1) : widget.homepageController.initialPage;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: 1020,
        child: PageView(
          controller: widget.homepageController,
          physics: NeverScrollableScrollPhysics(),
          children: [
            AccountPage(widget.prefs),
            TransferRules(widget.prefs),
            CustomRules(widget.prefs)
          ],
        ),
      ),
    );
  }
}