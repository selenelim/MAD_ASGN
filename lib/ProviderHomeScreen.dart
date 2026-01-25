import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:draft_asgn/LogInScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ManageServicesScreen.dart';
import 'ProviderAddShopScreen.dart';
import 'ProviderEditShopScreen.dart';

class ProviderHomeScreen extends StatelessWidget {
  const ProviderHomeScreen({super.key});

  static const Color brown = Color.fromRGBO(82, 45, 11, 1);
  static const Color lightCream = Color.fromRGBO(253, 251, 215, 1);

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rememberMe', false);

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
      (route) => false,
    );
  }

  Future<bool> _confirm(BuildContext context, String title, String msg) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: lightCream,
        title: Text(title, style: const TextStyle(color: brown)),
        content: Text(msg, style: const TextStyle(color: Colors.black87)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: brown)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: brown,
              foregroundColor: lightCream,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("OK"),
          ),
        ],
      ),
    );
    return res == true;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text("Please log in.")));
    }

    final myShopsStream = FirebaseFirestore.instance
        .collection('shops')
        .where('ownerId', isEqualTo: user.uid)
        .snapshots();

    final userEmail = user.email ?? 'provider';
    final shortName = userEmail.contains('@') ? userEmail.split('@').first : userEmail;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Image.asset('assets/img/pawpal_logo.png', height: 65),
      ),
      backgroundColor: lightCream,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ======= Header card (same style as admin) =======
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: brown,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Provider Home",
                        style: TextStyle(
                          color: lightCream,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Hello $shortName 👋",
                        style: const TextStyle(
                          color: lightCream,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Manage your shops and services",
                        style: TextStyle(color: lightCream),
                      ),
                    ],
                  ),
                ),

                // ======= Logout (top right, no circle, cream icon) =======
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: const Icon(Icons.logout, color: lightCream),
                    tooltip: "Logout",
                    onPressed: () async {
                      final ok = await _confirm(
                        context,
                        "Logout",
                        "Are you sure you want to log out?",
                      );
                      if (ok) {
                        await _logout(context);
                      }
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            const Text(
              "Your shops",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // ======= Shops list =======
            StreamBuilder<QuerySnapshot>(
              stream: myShopsStream,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snap.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text("Error: ${snap.error}"),
                  );
                }

                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text(
                      "No shops yet.\nTap + to add your first shop.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: docs.map((d) {
                    final shopId = d.id;
                    final data = d.data() as Map<String, dynamic>;

                    final name = (data['name'] ?? 'Unnamed').toString();
                    final category = (data['category'] ?? '').toString();
                    final isPublished = (data['isPublished'] ?? true) == true;

                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.black12),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "Category: $category • ${isPublished ? "Published" : "Hidden"}",
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ManageServicesScreen(shopId: shopId),
                            ),
                          );
                        },
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) async {
                            if (v == "services") {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ManageServicesScreen(shopId: shopId),
                                ),
                              );
                            } else if (v == "edit") {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ProviderEditShopScreen(shopId: shopId),
                                ),
                              );
                            } else if (v == "toggle") {
                              await FirebaseFirestore.instance
                                  .collection('shops')
                                  .doc(shopId)
                                  .update({
                                'isPublished': !isPublished,
                                'updatedAt': FieldValue.serverTimestamp(),
                              });
                            } else if (v == "delete") {
                              final ok = await _confirm(
                                context,
                                "Delete Shop",
                                "Delete shop '$name'? This cannot be undone.",
                              );
                              if (!ok) return;

                              await FirebaseFirestore.instance
                                  .collection('shops')
                                  .doc(shopId)
                                  .delete();
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: "services",
                              child: Text("Manage Services"),
                            ),
                            const PopupMenuItem(
                              value: "edit",
                              child: Text("Edit Shop"),
                            ),
                            PopupMenuItem(
                              value: "toggle",
                              child: Text(isPublished ? "Unpublish" : "Publish"),
                            ),
                            const PopupMenuItem(
                              value: "delete",
                              child: Text("Delete Shop"),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),

      // ======= Floating + (same as your screenshot) =======
      floatingActionButton: FloatingActionButton(
        backgroundColor: brown,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProviderAddShopScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
