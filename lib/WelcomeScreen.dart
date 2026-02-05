import 'package:flutter/material.dart';
import 'package:draft_asgn/LogInScreen.dart';
import 'package:draft_asgn/HomeScreen.dart'; // for your colors (brown/lightCream)

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Top: logo + title
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/img/pawpal_logo.png',
                      height: 70,
                    )
                  ],
                ),
                const SizedBox(height: 6),
                 Text(
                  'Professional Pet Care',
                  style: Theme.of(context).textTheme.bodySmall,
                ),

                const SizedBox(height: 22),

                // Middle image (rounded card)
                Container(
                  width: 260,
                  height: 220,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    color: Colors.white,
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 6),
                      ),
                    ],
                    image: const DecorationImage(
                      fit: BoxFit.cover,
                      // Put your image in /assets/img/ and update path
                      image: AssetImage('assets/img/welcome_dog.png'),
                    ),
                  ),
                ),

                const SizedBox(height: 26),

                // Text
                Text(
                  'Welcome to PawPal',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Your trusted partner for pet grooming, vaccinations,\nand wellness appointments',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 26),

                // Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Use pushReplacement so user can’t go back to welcome
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => LoginScreen()),
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Get Started',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}