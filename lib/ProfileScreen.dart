import 'package:flutter/material.dart';
import 'package:draft_asgn/HomeScreen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomeScreen.lightCream,
      appBar: AppBar(
        backgroundColor: HomeScreen.brown,
        elevation: 0,
        title: const Text('My Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Profile picture placeholder
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[300],
              child: const Icon(
                Icons.person,
                size: 50,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 16),

            // Username placeholder
            const Text(
              'Your Name',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            // Email placeholder
            const Text(
              'email@example.com',
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 30),

            // Info cards (UI only)
            _profileItem(
              icon: Icons.edit,
              label: 'Edit Profile',
            ),
            _profileItem(
              icon: Icons.lock,
              label: 'Change Password',
            ),
            _profileItem(
              icon: Icons.settings,
              label: 'Settings',
            ),

            const Spacer(),

            // Logout button (UI only)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {}, // no function yet
                style: ElevatedButton.styleFrom(
                  backgroundColor: HomeScreen.brown,
                  foregroundColor: HomeScreen.lightCream,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('Logout'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _profileItem({
    required IconData icon,
    required String label,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: HomeScreen.brown),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }
}
