import 'package:draft_asgn/AddPetScreen.dart';
import 'package:draft_asgn/BookingScreen.dart';
import 'package:draft_asgn/HomeScreen.dart';
import 'package:draft_asgn/LogInScreen.dart';
import 'package:draft_asgn/WelcomeScreen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PawPal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color.fromRGBO(82, 45, 11, 1),
        scaffoldBackgroundColor: Color.fromRGBO(253, 251, 215, 1),
      ),
      home: const WelcomeScreen(),
);
  }
}
