import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:draft_asgn/AdminDashboardScreen.dart';
import 'package:draft_asgn/HomeScreen.dart';
import 'package:draft_asgn/ProviderHomeScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<void> _ensureUserDoc(User user) async {
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final snap = await ref.get();

    if (!snap.exists) {
      await ref.set({
        'role': 'user', // default
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return;
    }

    // Ensure role exists
    final data = snap.data() as Map<String, dynamic>? ?? {};
    if (!data.containsKey('role')) {
      await ref.set({'role': 'user'}, SetOptions(merge: true));
    }
  }

  Future<bool> _isAdmin(String uid) async {
    final adminDoc =
        await FirebaseFirestore.instance.collection('admins').doc(uid).get();
    return adminDoc.exists;
  }

  Future<String> _getMode(User user) async {
    await _ensureUserDoc(user);

    final isAdmin = await _isAdmin(user.uid);
    if (isAdmin) return 'admin';

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = userDoc.data() as Map<String, dynamic>? ?? {};
    final role = (data['role'] ?? 'user').toString(); // 'user' | 'provider'
    return role;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Not logged in")),
      );
    }

    return FutureBuilder<String>(
      future: _getMode(user),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text("Error: ${snapshot.error}")),
          );
        }

        final mode = snapshot.data ?? 'user';

        if (mode == 'admin') return const AdminDashboardScreen();

        // ✅ multi-shop provider dashboard (no shopId param)
        if (mode == 'provider') return const ProviderHomeScreen();

        return const HomeScreen();
      },
    );
  }
}
