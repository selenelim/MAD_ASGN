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
        title: Text(title, style: Theme.of(context).textTheme.titleLarge),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
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
    final theme = Theme.of(context);
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
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ===== HEADER CARD (UPDATED) =====
            _providerHeader(
              context: context,
              theme: theme,
              shortName: shortName,
              onLogout: () async {
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

            const SizedBox(height: 20),

            Text("Your shops", style: theme.textTheme.titleLarge),
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
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: ListTile(
                            title: Text(
                              name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(data['category'] ?? ''),
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
                                if (v == "edit") {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ProviderEditShopScreen(shopId: shopId),
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
                                PopupMenuItem(value: "edit", child: Text("Edit Shop")),
                                PopupMenuItem(value: "delete", child: Text("Delete Shop")),
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
                              .snapshots(),
                          builder: (context, snap) {
                            if (!snap.hasData || snap.data!.docs.isEmpty) {
                              return const SizedBox();
                            }

                            return Padding(
                              padding: const EdgeInsets.fromLTRB(24, 6, 0, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                                    child: Text(
                                      "Upcoming Appointments",
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ),
                                  ...snap.data!.docs.map((doc) {
                                    final a = doc.data() as Map<String, dynamic>;

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surface,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            a['serviceName'] ?? '',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
  "Pet: ${(a['pet']?['name'] ?? '')}",
  style: const TextStyle(color: Colors.black54),
),
Text(
  "Date: ${(a['date'] as Timestamp).toDate().day}/"
  "${(a['date'] as Timestamp).toDate().month}/"
  "${(a['date'] as Timestamp).toDate().year}",
  style: const TextStyle(color: Colors.black54),
),

Text(
  "Time: ${a['time'] ?? ''}",
  style: const TextStyle(color: Colors.black54),
),

                                          const SizedBox(height: 8),

                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: TextButton(
                                              onPressed: () async {
                                                final ok = await _confirm(
                                                  context,
                                                  "Cancel Appointment",
                                                  "Cancel this appointment for the customer?",
                                                );
                                                if (!ok) return;

                                                final clientUid = a['userId'];
                                                final bookingId = doc.id;
                                                final firestore = FirebaseFirestore.instance;

                                                await firestore
                                                    .collection('shops')
                                                    .doc(shopId)
                                                    .collection('appointments')
                                                    .doc(bookingId)
                                                    .update({'status': 'cancelled'});

                                                await firestore
                                                    .collection('users')
                                                    .doc(clientUid)
                                                    .collection('bookings')
                                                    .doc(bookingId)
                                                    .update({'status': 'cancelled'});

                                                await firestore
                                                    .collection('bookings')
                                                    .doc(bookingId)
                                                    .delete();
                                              },
                                              child: const Text(
                                                "Cancel",
                                                style: TextStyle(color: Colors.red),
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
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.scaffoldBackgroundColor,
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

  // ===== HEADER WIDGET (NEW) =====
  Widget _providerHeader({
    required BuildContext context,
    required ThemeData theme,
    required String shortName,
    required VoidCallback onLogout,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset(
                'assets/img/pawpal_logo_cream.png',
                height: 45,
              ),

              PopupMenuButton<String>(
                icon: CircleAvatar(
                  backgroundColor: theme.colorScheme.surface,
                  child: Icon(Icons.person, color: theme.colorScheme.primary),
                ),
                onSelected: (v) async {
                  if (v == 'logout') onLogout();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'logout',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.logout,
                        color: Colors.black
                      ),
                      title: const Text('Logout'),
                    )
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            "Provider Home",
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Hello $shortName 👋",
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
