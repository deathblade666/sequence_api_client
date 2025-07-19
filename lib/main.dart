import 'dart:io';

import 'package:Seqeunce_API_Client/utils/historyprovider.dart';
import 'package:Seqeunce_API_Client/utils/secretservice.dart';
import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:Seqeunce_API_Client/pages/home.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  final rootPath = Directory.current.path;
  final envPath = '$rootPath/.env';
  await dotenv.load(fileName: envPath);
  await SecretService.init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HistoryProvider()..loadHistory()),
      ],
      child:Seqeunce_API_Client()
    )
  );
}
  //await dotenv.load(fileName: envPath);
  //await SecretService.init();
 
  

final _defaultDarkColorScheme = ColorScheme.fromSwatch(
  primarySwatch: Colors.indigo, brightness: Brightness.dark);
final _defaultLightColorScheme = ColorScheme.fromSwatch(
  primarySwatch: Colors.indigo);

class Seqeunce_API_Client extends StatelessWidget {
  Seqeunce_API_Client({super.key});


  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(builder: (lightColorScheme, darkColorScheme, ) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: HomePage(),
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