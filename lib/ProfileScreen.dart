
import 'package:draft_asgn/MyAppointmentsScreen.dart';
import 'package:flutter/material.dart';
import 'package:draft_asgn/HomeScreen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        
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
             Text(
              'Your Name',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge,
            ),

            const SizedBox(height: 4),

            // Email placeholder
             Text(
              'email@example.com',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall,
            ),

            const SizedBox(height: 30),

            // Info cards (UI only)
            _profileItem(context,
              icon: Icons.edit,
              label: 'Edit Profile',
            ),
            _profileItem(context,
              icon: Icons.lock,
              label: 'Change Password',
            ),
            _profileItem(context,
  icon: Icons.calendar_month,
  label: 'My Appointments',
  onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const MyAppointmentsScreen(),
    ),
  );
},

),

            _profileItem(context,
              icon: Icons.settings,
              label: 'Settings',
            ),
            

            const Spacer(),

            // Logout button (UI only)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {}, // no function yet
                
                child: const Text('Logout'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _profileItem(BuildContext context,{
  required IconData icon,
  required String label,
  VoidCallback? onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context)
                  .appBarTheme
                  .backgroundColor,),
          const SizedBox(width: 12),
          Text(
            label,
            style: Theme.of(context)
                  .textTheme
                  .bodyMedium
          ),
          const Spacer(),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    ),
  );
}

}
