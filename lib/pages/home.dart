import 'package:flutter/material.dart';
import 'package:Seqeunce_API_Client/pages/utils/pagecontroller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  HomePage(this.prefs,{super.key});
  SharedPreferences prefs;
  PageController homepageController = PageController();

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

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
                child: ListView.builder(                //TODO: Add items to list
                  itemCount: 3,                         //TODO: Save List
                  itemBuilder: (context, index){        //TODO: Restore List
                    return ListTile(                    //TODO: Implement DB for storing History
                      title: Text('${index +1}'),
                    );
                  }
                ),
              )
            ],
          )
        ),
        appBar: AppBar(
          title: const Text("Sequence API Client"),
          leading: DrawerButton()
        ),
        body: Views(widget.prefs,widget.homepageController),
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