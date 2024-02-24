import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_signin/screens/signin_screen.dart';
import 'package:flutter/material.dart';
import 'package:smarbin/screens/signin_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
Platform.isAndroid?
await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBuCphfP-O8u2kzGnPLDA02ZKlU4kzI2j4", 
      appId: "1:509825197285:android:43df4f1732cb70c425a00c", 
      messagingSenderId: "509825197285", 
      projectId: "smarbin-7443d",
    ),
  )
  :await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: const SignInScreen(),
    );
  }
}