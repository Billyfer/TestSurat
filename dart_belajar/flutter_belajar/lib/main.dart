import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:KP_Program/Screen_Dashboard/Screen_Login/Login.dart';
import 'package:KP_Program/Screen_Dashboard/dashboard.dart';
import 'firebase_options.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
      );

  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pengarsipan Surat Kapal',
      theme: ThemeData(
        primaryColor: Colors.blue,
        colorScheme: ColorScheme.fromSwatch().copyWith(secondary: Colors.blue),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginPage(),
        '/dashboard': (context) => DashboardPage(),
      },
    );
  }
}
