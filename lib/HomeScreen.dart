import 'dart:convert';                                            //Used for base64Decode -> For pet profile picture
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
import 'package:firebase_auth/firebase_auth.dart';                //Accessed currently logged-in user
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';      //Used fpr Remmeber Me logout handling

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = '';                                   //shown in greeting
  String userRole = 'user';                               //controls menu options

  @override
  void initState() {                                      //Runs once when screen opens, Loads: Display name and role from Firestore
    super.initState();
    _loadUserName();
    _loadUserRole();
  }
  //Load Username
  Future<void> _loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;       //gets logged-in user
    setState(() {                                         //priority: Display Name -> Email prefix -> Fallback:"there"
      userName = user?.displayName ??
          user?.email?.split('@').first ??
          'there';
    });
  }

  Future<void> _loadUserRole() async {                                              //Fetch role from Firestore
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;                                                       //safety check

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();   //Reads /users/{uid}
    final data = doc.data() ?? {};                                                  //prevents null crash

    if (!mounted) return;                                                           //ensures widget still exists
    setState(() => userRole = (data['role'] ?? 'user').toString());                 //default role = user
  }
  //Log Out Logic
  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rememberMe', false);                         //Clears remember-me flag
    await FirebaseAuth.instance.signOut();                            //logs out of firebase

    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(                                     //clears navigation stack -> user cannot press back
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }
  //Menu Selection Handler
  Future<void> _handleMenuSelection(String value) async {                       //Handles popupmenu clicks
    if (value == 'profile') {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()));            //go to profile
    } else if (value == 'register_business') {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const RegisterBusinessScreen()));   //only for normal users
    } else if (value == 'manage_shop') {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const ProviderHomeScreen()));       //only for providers -> but shouldnt need since we use AuthGate to route them
    } else if (value == 'logout') {
      await _logout(context);
    }
  }
  //UI
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(                                       //Avoids notch/status bar
        child: SingleChildScrollView(                       //allows scrolling if content overflows
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
                onSelected: _handleMenuSelection,           //calls this function using the values here
                itemBuilder: (_) => [
                  const PopupMenuItem(                      //Dropdown menu
                    value: 'profile',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.person),
                      title: Text('My Profile'),
                    )
                  ),
                  if (userRole == 'user')
                    const PopupMenuItem(
                      value: 'register_business',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.store),
                        title: Text('Register Business'),
                      )
                    ),
                  if (userRole == 'provider')
                    const PopupMenuItem(
                      value: 'manage_shop',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.store),
                        title: Text('Manage Shop'),
                      )
                    ),
                  
                  const PopupMenuItem(
                    value: 'logout',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.logout),
                      title: Text('Logout'),
                    )
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
        StreamBuilder<QuerySnapshot>(                                     //Listens to Firestore live -> Real-time pets list
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
            //PET CARD
            return Column(
              children: [
                ...pets.map((pet) {
                  final petData = pet.data() as Map<String, dynamic>;
                  ImageProvider? img;

                  if (petData['profilePicBase64'] != null) {
                    try {
                      img = MemoryImage(
                          base64Decode(petData['profilePicBase64']));           //Converts Base64 -> Image
                    } catch (_) {}
                  }

                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: img,                                   //Image if it exists
                        child: img == null ? const Icon(Icons.pets) : null,     //Else icon
                      ),
                      title: Text(petData['name'] ?? 'Unnamed'),
                      subtitle:
                          Text(petData['species'] ?? 'Unknown species'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PetProfileScreen(                   //Opens pet profile
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
                //Add Pet Button
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
          crossAxisCount: 2,                                                            //2 column grid
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),                                //Prevents nested scrolling -> basically telling the widget it is NOT allowed to scroll
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          //Grooming/Vet/Boarding/Training CARDS
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

// ================= SERVICE CARD =================       -> Reusable UI component
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
      child: InkWell(                                               //Ripple effect + Click Handler
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(                                            //Icon background
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
