import 'package:draft_asgn/LogInScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    _loadUserName(); // load name from FirebaseAuth only
  }

  Future<void> _loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      setState(() {
        // Use displayName if available, otherwise fallback to email prefix
        userName = user.displayName ?? user.email?.split('@')[0] ?? 'there';
      });
    } else {
      setState(() {
        userName = 'there';
      });
    }
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
          // Top row: logo + profile + logout
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Image.asset(
                    'assets/img/pawpal_logo_cream.png',
                    height: 45,
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: HomeScreen.brown),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();

                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('rememberMe', false);

                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => LoginScreen()),
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Greeting
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
  // Example list of pets
  final pets = [
    {'name': 'Max', 'type': 'Cat', 'image': 'assets/img/cat.jpeg'},
    {'name': 'Buddy', 'type': 'Dog', 'image': 'assets/img/dog.jpeg'},
    {'name': 'Luna', 'type': 'Cat', 'image': 'assets/img/cat2.jpeg'},
    {'name': 'Luna', 'type': 'Cat', 'image': 'assets/img/cat2.jpeg'},
  ];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        "$userName's Pets",
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 12),
      
      // Grid with 1 pet per row
      GridView.builder(
        itemCount: pets.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1, // 1 pet per row
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 5, // adjust height
        ),
        itemBuilder: (context, index) {
          final pet = pets[index];
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: AssetImage(pet['image']!),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      pet['name']!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${pet['type']} · ${pet['type']}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                const Spacer(),
                const Icon(Icons.pets, color: HomeScreen.brown),
              ],
            ),
          );
        },
      ),

      const SizedBox(height: 12),

      // Add Pet button on its own row
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () {
            // TODO: Navigate to Add Pet screen
          },
          icon: const Icon(Icons.add, color: HomeScreen.brown),
          label: const Text(
            'Add Pet',
            style: TextStyle(color: HomeScreen.brown),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: HomeScreen.brown),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
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
          children: const [
            _ServiceCard(icon: Icons.cut, label: 'Grooming'),
            _ServiceCard(icon: Icons.medical_services, label: 'Vet'),
            _ServiceCard(icon: Icons.home, label: 'Boarding'),
            _ServiceCard(icon: Icons.school, label: 'Training'),
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

  const _ServiceCard({
    required this.icon,
    required this.label,
  });

  static const Color brown = Color(0xFF522D0B);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
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
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
