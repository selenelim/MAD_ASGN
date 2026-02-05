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
        content: Text(msg),
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
    final shortName =
        userEmail.contains('@') ? userEmail.split('@').first : userEmail;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Image.asset('assets/img/pawpal_logo.png', height: 65),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: brown),
            onPressed: () async {
              final ok = await _confirm(
                context,
                "Logout",
                "Sign out and return to login?",
              );
              if (ok) {
                await _logout(context);
              }
            },
          ),
        ],
      ),
      backgroundColor: lightCream,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ===== HEADER =====
            Container(
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
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Hello $shortName 👋",
                    style: const TextStyle(
                      color: lightCream,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Your shops",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // ===== SHOPS LIST =====
            StreamBuilder<QuerySnapshot>(
              stream: myShopsStream,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Text("No shops yet.");
                }

                return Column(
                  children: docs.map((d) {
                    final shopId = d.id;
                    final data = d.data() as Map<String, dynamic>;
                    final name = data['name'] ?? 'Unnamed';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ===== SHOP CARD =====
                        Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.black12),
                          ),
                          child: ListTile(
                            title: Text(
                              name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(data['category'] ?? ''),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ManageServicesScreen(shopId: shopId),
                                ),
                              );
                            },
                            trailing: PopupMenuButton<String>(
                              onSelected: (v) async {
                                if (v == "edit") {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ProviderEditShopScreen(
                                              shopId: shopId),
                                    ),
                                  );
                                } else if (v == "delete") {
                                  final ok = await _confirm(
                                    context,
                                    "Delete Shop",
                                    "Delete this shop?",
                                  );
                                  if (ok) {
                                    await FirebaseFirestore.instance
                                        .collection('shops')
                                        .doc(shopId)
                                        .delete();
                                  }
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                    value: "edit", child: Text("Edit Shop")),
                                PopupMenuItem(
                                    value: "delete",
                                    child: Text("Delete Shop")),
                              ],
                            ),
                          ),
                        ),

                        // ===== UPCOMING APPOINTMENTS =====
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('shops')
                              .doc(shopId)
                              .collection('appointments')
                              .where('status', isEqualTo: 'upcoming')
                              .snapshots(), // 🔥 ORDER BY REMOVED
                          builder: (context, snap) {
                            if (!snap.hasData ||
                                snap.data!.docs.isEmpty) {
                              return const SizedBox();
                            }

                            return Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(24, 6, 0, 16),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  const Padding(
                                    padding:
                                        EdgeInsets.only(left: 4, bottom: 8),
                                    child: Text(
                                      "Upcoming Appointments",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),

                                  ...snap.data!.docs.map((doc) {
                                    final a =
                                        doc.data() as Map<String, dynamic>;

                                    return Container(
                                      margin:
                                          const EdgeInsets.only(bottom: 10),
                                      padding:
                                          const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(16),
                                        border: Border.all(
                                            color: Colors.black12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            a['serviceName'],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "Pet: ${a['pet']['name']}",
                                            style: const TextStyle(
                                                color: Colors.black54),
                                          ),
                                          Text(
                                            "Time: ${a['time']}",
                                            style: const TextStyle(
                                                color: Colors.black54),
                                          ),
                                          const SizedBox(height: 8),

                                          Align(
                                            alignment:
                                                Alignment.centerRight,
                                            child: TextButton(
                                              onPressed: () async {
                                                final ok = await _confirm(
                                                  context,
                                                  "Cancel Appointment",
                                                  "Cancel this appointment for the customer?",
                                                );
                                                if (!ok) return;

                                                final clientUid =
                                                    a['userId'];
                                                final bookingId = doc.id;

                                                final firestore =
                                                    FirebaseFirestore.instance;

                                                await firestore
                                                    .collection('shops')
                                                    .doc(shopId)
                                                    .collection(
                                                        'appointments')
                                                    .doc(bookingId)
                                                    .update({
                                                  'status': 'cancelled'
                                                });

                                                await firestore
                                                    .collection('users')
                                                    .doc(clientUid)
                                                    .collection('bookings')
                                                    .doc(bookingId)
                                                    .update({
                                                  'status': 'cancelled'
                                                });

                                                await firestore
                                                    .collection('bookings')
                                                    .doc(bookingId)
                                                    .delete();
                                              },
                                              child: const Text(
                                                "Cancel",
                                                style: TextStyle(
                                                    color: Colors.red),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: brown,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ProviderAddShopScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
