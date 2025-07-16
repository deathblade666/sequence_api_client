import 'package:flutter/material.dart';
import 'package:Seqeunce_API_Client/pages/utils/pagecontroller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  HomePage(this.prefs,{super.key});
  SharedPreferences prefs;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  @override
  Widget build(BuildContext context) {
    PageController homepageController = PageController();
    return Scaffold(
      //TODO: Add Drawer
      appBar: AppBar(
        title: const Text("Sequence API Client"),
        leading: DrawerButton(
          onPressed: (){
            //TODO: Open Drawer, hide drawer if history is disabled.
            print("Test");
          },
        )
      ),
      body: Views(homepageController: homepageController, widget.prefs),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          children: [
            //TODO: Make Button Move to Different Screens

            Spacer(flex: 1,),
            TextButton(
              onPressed: () {
                setState(() {
                  homepageController.hasClients ? homepageController.jumpToPage(1) : homepageController.initialPage;
                });
              },
              child: Text("Home"),
            ),
            Spacer(),
            TextButton(
              onPressed: () {
                setState(() {
                  homepageController.hasClients ? homepageController.jumpToPage(2) : homepageController.initialPage;
                });
              },
              child: Text("Rules"),
            ),
            Spacer(),
            TextButton(
              onPressed: () {
                //TODO: Create List widget and prompt to define custom rules to run without needing to login to sequence
              },
              child: Text("Custom"),
            ),
            Spacer()
          ],
        ),
      ),
    );
  }
}