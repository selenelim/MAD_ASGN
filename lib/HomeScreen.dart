import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:draft_asgn/AddPetScreen.dart';
import 'package:draft_asgn/BoardingScreen.dart';
import 'package:draft_asgn/GroomingScreen.dart';
import 'package:draft_asgn/LogInScreen.dart';
import 'package:draft_asgn/PetProfileScreen.dart';
import 'package:draft_asgn/ProfileScreen.dart';
import 'package:draft_asgn/RegisterBusinessScreen.dart';
import 'package:draft_asgn/TrainingSreen.dart';
import 'package:draft_asgn/VetScreen.dart';
import 'package:draft_asgn/ProviderHomeScreen.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = '';
  String userRole = 'user';

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadUserRole();
  }

  Future<void> _loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      userName = user?.displayName ??
          user?.email?.split('@').first ??
          'there';
    });
  }

  Future<void> _loadUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data() ?? {};

    if (!mounted) return;
    setState(() => userRole = (data['role'] ?? 'user').toString());
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rememberMe', false);
    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _handleMenuSelection(String value) async {
    if (value == 'profile') {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()));
    } else if (value == 'register_business') {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const RegisterBusinessScreen()));
    } else if (value == 'manage_shop') {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const ProviderHomeScreen()));
    } else if (value == 'logout') {
      await _logout(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(theme),
              const SizedBox(height: 24),
              _buildPetsSection(theme),
              const SizedBox(height: 24),
              _buildServicesSection(theme),
            ],
          ),
        ),
      ),
    );
  }

  // ================= HEADER =================
  Widget _buildHeader(ThemeData theme) {
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
                  child: Icon(Icons.person,
                      color: theme.colorScheme.primary),
                ),
                onSelected: _handleMenuSelection,
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'profile',
                    child: Text('My Profile'),
                  ),
                  if (userRole == 'user')
                    const PopupMenuItem(
                      value: 'register_business',
                      child: Text('Register Business'),
                    ),
                  if (userRole == 'provider')
                    const PopupMenuItem(
                      value: 'manage_shop',
                      child: Text('Manage My Shops'),
                    ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Text('Logout'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Hello $userName 👋',
            style: theme.textTheme.titleLarge
                ?.copyWith(color: theme.colorScheme.onPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Welcome back to PawPal',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onPrimary),
          ),
        ],
      ),
    );
  }

  // ================= PETS =================
  Widget _buildPetsSection(ThemeData theme) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$userName's Pets",
          style: theme.textTheme.titleLarge,
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
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final pets = snapshot.data!.docs;

            if (pets.isEmpty) {
              return Text(
                'No pets yet. Add your first pet!',
                style: theme.textTheme.bodyMedium,
              );
            }

            return Column(
              children: [
                ...pets.map((pet) {
                  final petData = pet.data() as Map<String, dynamic>;
                  ImageProvider? img;

                  if (petData['profilePicBase64'] != null) {
                    try {
                      img = MemoryImage(
                          base64Decode(petData['profilePicBase64']));
                    } catch (_) {}
                  }

                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: img,
                        child: img == null ? const Icon(Icons.pets) : null,
                      ),
                      title: Text(petData['name'] ?? 'Unnamed'),
                      subtitle:
                          Text(petData['species'] ?? 'Unknown species'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PetProfileScreen(
                              userId: user.uid,
                              petId: pet.id,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AddPetScreen()),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Pet'),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  // ================= SERVICES =================
  Widget _buildServicesSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Services', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _ServiceCard(icon: Icons.cut, label: 'Grooming', onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const GroomingScreen()));
            }),
            _ServiceCard(icon: Icons.medical_services, label: 'Vet', onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const VetScreen()));
            }),
            _ServiceCard(icon: Icons.home, label: 'Boarding', onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const BoardingScreen()));
            }),
            _ServiceCard(icon: Icons.school, label: 'Training', onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const TrainingScreen()));
            }),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
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
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: theme.colorScheme.onPrimary),
              ),
              const SizedBox(height: 8),
              Text(label, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
