import 'dart:convert'; // base64Decode

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:draft_asgn/AddPetScreen.dart';
import 'package:draft_asgn/BoardingScreen.dart';
import 'package:draft_asgn/GroomingScreen.dart';
import 'package:draft_asgn/LogInScreen.dart';
import 'package:draft_asgn/PetProfileScreen.dart';
import 'package:draft_asgn/TrainingSreen.dart';
import 'package:draft_asgn/VetScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:draft_asgn/ProfileScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const Color brown = Color.fromRGBO(82, 45, 11, 1);
  static const Color lightCream = Color.fromRGBO(253, 251, 215, 1);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = '';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      setState(() {
        userName = user.displayName ?? user.email?.split('@')[0] ?? 'there';
      });
    } else {
      setState(() {
        userName = 'there';
      });
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomeScreen.lightCream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              _buildPetsSection(),
              const SizedBox(height: 24),
              _buildServicesSection(),
            ],
          ),
        ),
      ),
    );
  }

  // ================= HEADER =================
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HomeScreen.brown,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: logo + profile menu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset(
                'assets/img/pawpal_logo_cream.png',
                height: 45,
              ),

              PopupMenuButton<String>(
                icon: const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, color: HomeScreen.brown),
                ),
                offset: const Offset(0, 50),
                color: HomeScreen.lightCream,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: const [
                        Icon(Icons.account_circle, color: HomeScreen.brown),
                        SizedBox(width: 8),
                        Text(
                          'My Profile',
                          style: TextStyle(color: HomeScreen.brown),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: const [
                        Icon(Icons.logout, color: HomeScreen.brown),
                        SizedBox(width: 8),
                        Text(
                          'Logout',
                          style: TextStyle(color: HomeScreen.brown),
                        ),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) async {
                  if (value == 'profile') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                    return;
                  }

                  if (value == 'logout') {
                    await _logout(context);
                    return;
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          Text(
            'Hello $userName 👋',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Welcome back to PawPal',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  // ================= PETS =================
  Widget _buildPetsSection() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Text('Not logged in');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$userName's Pets",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('pets')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final petWidgets = <Widget>[];

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              petWidgets.add(
                const Text('No pets yet. Add your first pet!'),
              );
            } else {
              final pets = snapshot.data!.docs;

              petWidgets.addAll(
                pets.map((pet) {
                  final petData = pet.data() as Map<String, dynamic>;
                  final petId = pet.id;

                  ImageProvider? petImageProvider;
                  final b64 = petData['profilePicBase64'];
                  if (b64 is String && b64.isNotEmpty) {
                    try {
                      petImageProvider = MemoryImage(base64Decode(b64));
                    } catch (_) {
                      petImageProvider = null;
                    }
                  }

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PetProfileScreen(
                            userId: user.uid,
                            petId: petId,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.grey[300],
                              image: petImageProvider != null
                                  ? DecorationImage(
                                      image: petImageProvider,
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: petImageProvider == null
                                ? const Icon(Icons.pets, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (petData['name'] ?? 'Unnamed Pet').toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                (petData['species'] ?? 'Unknown Species')
                                    .toString(),
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              );
            }

            petWidgets.add(const SizedBox(height: 16));
            petWidgets.add(
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddPetScreen()),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Pet'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HomeScreen.brown,
                    foregroundColor: HomeScreen.lightCream,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: petWidgets,
            );
          },
        ),
      ],
    );
  }

  // ================= SERVICES =================
  Widget _buildServicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Services',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _ServiceCard(
              icon: Icons.cut,
              label: 'Grooming',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GroomingScreen()),
                );
              },
            ),
            _ServiceCard(
              icon: Icons.medical_services,
              label: 'Vet',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VetScreen()),
                );
              },
            ),
            _ServiceCard(
              icon: Icons.home,
              label: 'Boarding',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BoardingScreen()),
                );
              },
            ),
            _ServiceCard(
              icon: Icons.school,
              label: 'Training',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TrainingScreen()),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

// ================= SERVICE CARD =================
class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  static const Color brown = Color(0xFF522D0B);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: brown,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

