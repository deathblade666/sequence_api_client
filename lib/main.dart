// ignore_for_file: camel_case_types

import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:Seqeunce_API_Client/pages/home.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  runApp(Seqeunce_API_Client(prefs));
  
}

final _defaultDarkColorScheme = ColorScheme.fromSwatch(
  primarySwatch: Colors.indigo, brightness: Brightness.dark);
final _defaultLightColorScheme = ColorScheme.fromSwatch(
  primarySwatch: Colors.indigo);

class Seqeunce_API_Client extends StatelessWidget {
  Seqeunce_API_Client(this.prefs, {super.key});
  SharedPreferences prefs;


  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(builder: (lightColorScheme, darkColorScheme, ) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: HomePage(prefs),
        theme: ThemeData(
          colorScheme: lightColorScheme ?? _defaultLightColorScheme,
          useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: darkColorScheme ?? _defaultDarkColorScheme,
            useMaterial3: true,
          ),
        themeMode: ThemeMode.system,
        );
    });
  }
}