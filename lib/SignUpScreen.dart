//Sign Up Page
//Routed here by: LogInScreen

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';            //Lets us create accounts/sign in users using Firebase Authentication
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  //Controllers read what the user types into each TextField
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();

  bool passwordVisible = false;             //Controls if password is hidden or shown
  bool confirmPasswordVisible = false;      //Same but for Confirm Password Field
  bool isLoading = false;                   //When true -> Disables button and shows spinner

  @override
  void dispose() {
    //Frees resources used by the controllers
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    usernameController.dispose();
    //Always call parent dispose
    super.dispose();
  }

  Future<void> _signUp() async {
    //Gets the email, password, confirmPassword and username text respectively and removes spaces using .trim()
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();
    final username = usernameController.text.trim();
    //Validates empty fields
    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty || username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),                                //If ANY field is empty -> Show error
      );
      return;                                                                                   //No Sign Up Attempt
    }
    //Validate password match
    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),                                //If doesnt match, show errors and exits
      );
      return;
    }

    setState(() => isLoading = true);                                                           //Updates UI: button become disabled and spinner shows up

    try {
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(                           //Creates Firebase Auth account with email+password   await -> Pauses here until Firebase returns results
        email: email,
        password: password,
      );

      final user = userCredential.user;                                                         //Extracts the User Object

      // Save username in FirebaseAuth profile
      if (user != null) {                                                                       //Only runs if user exists
        await user.updateDisplayName(username);                                                 //Sets the Firebase Auth "profile displayName" to this username

        //Create user document in Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({                //Writes to Firestore: collection: users, document id: user.uid
          'role': 'user', // default role                                                       //Data being saved: default role: 'user', username, email, createdAt (server time)
          'username': username,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));                                                            //if doc alr exists, it only updates/adds these fields
      }

      if (!mounted) return;                                         //checks if this screen is still on screen, if it is not, dont show SnackBars or navigate

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created!')),          //Shows "Account created!"
      );

      // Goes back to previous screen (LogIn Screen)
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {                          //Catches known Firebase Auth errors
      String message = 'Sign up failed';                            //Default Message
      //Changes message based on error type
      if (e.code == 'email-already-in-use') {
        message = 'Email already in use';
      } else if (e.code == 'weak-password') {
        message = 'Password is too weak';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email';
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),                         //If still on screen, show the message from the error
      );
    } catch (e) {                                                 //Catch non-Firebase errors
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {                                                   //finally runs whether success/failure
      if (mounted) setState(() => isLoading = false);             //Turns off isLoading -> Button returns to normal
    }
  }


  //UI

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //AppBar
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Image.asset(
          'assets/img/pawpal_logo.png',
          height: 65,
        ),
      ),
      
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(                                                //White rounded card with shadow
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                 Text(
                  'PawPal',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your account',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 24),

                TextField(
                  controller: usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    prefixIcon: const Icon(Icons.account_circle_outlined),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: const Icon(Icons.email_outlined),
                    
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: passwordController,
                  obscureText: !passwordVisible,                                          //passwordVisible = false -> Hide text
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(                                               //Clickable
                      icon: Icon(
                        passwordVisible ? Icons.visibility : Icons.visibility_off,        //pV=false -> visi_off      pV=true -> visi
                      ),
                      onPressed: () {
                        setState(() => passwordVisible = !passwordVisible);               //Toggles passwordVisible, triggers rebuild so field updates
                      },
                    ),
                   
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: confirmPasswordController,
                  obscureText: !confirmPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        confirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() => confirmPasswordVisible = !confirmPasswordVisible);
                      },
                    ),
                   
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _signUp,
                    child: isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Sign Up'),
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account? "),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),              //Routes back to LogInScreen
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          color: Color.fromRGBO(176, 115, 68, 1),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
