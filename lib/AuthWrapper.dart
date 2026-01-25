import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'AuthGate.dart';
import 'WelcomeScreen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _applyRememberMeGuard();
  }

  Future<void> _applyRememberMeGuard() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool('rememberMe') ?? false;

    final user = FirebaseAuth.instance.currentUser;

    // If Firebase restored a session but user didn't choose remember me -> kick out
    if (user != null && !remember) {
      await FirebaseAuth.instance.signOut();
    }

    if (!mounted) return;
    setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snap.data;

        // Not logged in -> show Welcome (not Login directly)
        if (user == null) return const WelcomeScreen();

        // Logged in -> route by role
        return const AuthGate();
      },
    );
  }
}
