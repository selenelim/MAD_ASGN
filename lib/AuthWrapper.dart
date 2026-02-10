import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';            //Used for rememberMe

import 'AuthGate.dart';                                                 //Routes to it when logged in (and it decides the role routing)
import 'WelcomeScreen.dart';                                            //Shown when not logged in

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _ready = false;

  @override
  void initState() {                                                    //Runs once when this widget is inserted into widget tree
    super.initState();
    _applyRememberMeGuard();
  }

  Future<void> _applyRememberMeGuard() async {
    final prefs = await SharedPreferences.getInstance();                //Gets the SharedPreferences instance (takes time hence use await)
    final remember = prefs.getBool('rememberMe') ?? false;              //Reads the boolean stored under key 'rememberMe', if it doesnt exist, it is null so ??false, defaults it to false

    final user = FirebaseAuth.instance.currentUser;                     //Gets the currently cached Firebase User

    // If Firebase restored a session but user didn't choose remember me -> kick out
    if (user != null && !remember) {
      await FirebaseAuth.instance.signOut();
    }

    if (!mounted) return;                                               //Marks the guard as finished
    setState(() => _ready = true);                                      //setState triggers a rebuild so build() will stop showing the loading spinner
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),               //if _ready=false -> It will show loading spinner
      );
    }

    return StreamBuilder<User?>(                                        //StreamBuilder rebuilds whenever the stream emits new values
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {                                        //snap (snapshot) contains latest stream value + connection info
        if (snap.connectionState == ConnectionState.waiting) {          //When stream is still connecting or waiting for first value, show loading spinner
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snap.data;                                         //Reads the current stream output, null means not logged in

        // Not logged in -> show Welcome (not Login directly)
        if (user == null) return const WelcomeScreen();

        // Logged in -> route by role
        return const AuthGate();
      },
    );
  }
}
