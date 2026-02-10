import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:draft_asgn/AdminDashboardScreen.dart';
import 'package:draft_asgn/HomeScreen.dart';
import 'package:draft_asgn/ProviderHomeScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<void> _ensureUserDoc(User user) async {                                  //Guarantees that every logged-in user has a Firestore document
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);     //Points to: users/{uid}
    final snap = await ref.get();                                                 //Fetches the document

    if (!snap.exists) {                                 //if user document does not exist
      await ref.set({                                   //creates it
        'role': 'user', // default                      //Sets default role='user'
        'createdAt': FieldValue.serverTimestamp(),      //Adds a timestamp
      }, SetOptions(merge: true));
      return;
    }
    


    // If document exists but role is missing
    final data = snap.data() as Map<String, dynamic>? ?? {};
    if (!data.containsKey('role')) {
      await ref.set({'role': 'user'}, SetOptions(merge: true)); //Sets role='user', Only edits the 'role' since SetOptions(merge:true) is used
    }
  }

  Future<bool> _isAdmin(String uid) async {                                       //Checks if user is an admin
    final adminDoc =
        await FirebaseFirestore.instance.collection('admins').doc(uid).get();     //If document exists -> Admin
    return adminDoc.exists;
  }

  Future<String> _getMode(User user) async {
    await _ensureUserDoc(user);                                                 //Ensures user doc exists -> Prevents missing Firestore data issues

    final isAdmin = await _isAdmin(user.uid);                                   //Checks Admin first
    if (isAdmin) return 'admin';

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();                                                                //Get role from users collection
    final data = userDoc.data() as Map<String, dynamic>? ?? {};
    final role = (data['role'] ?? 'user').toString();                          // 'user' | 'provider'
    return role;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    //Safety
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Not logged in")),
      );
    }

    return FutureBuilder<String>(                                       //Rebuilds UI when data (String type) is ready
      future: _getMode(user),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {         //Prevents blank screen
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),           //Shows spinner while async work runs
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text("Error: ${snapshot.error}")),      //if error occurs
          );
        }

        final mode = snapshot.data ?? 'user';                           //snapshot.data = the value returned by _getMode, A ?? B -> If A is not null, use A else use B

        if (mode == 'admin') return const AdminDashboardScreen();       //if snapshot.data=="admin", route to Admin Dashboard

        // ✅ multi-shop provider dashboard (no shopId param)
        if (mode == 'provider') return const ProviderHomeScreen();      //if snapshot.data=="provider", route to Provider HomeScreen

        return const HomeScreen();                                      //Default user

      },
    );
  }
}
