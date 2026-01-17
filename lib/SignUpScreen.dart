import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool passwordVisible = false;
  bool confirmPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Image.asset(
          'assets/img/pawpal_logo.png',
          height: 250,
        ),
      ),
      backgroundColor: Color.fromRGBO(253, 251, 215, 1),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'PawPal',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 8),
                Text(
                  'Create your account',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                SizedBox(height: 24),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: !passwordVisible,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(passwordVisible
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          passwordVisible = !passwordVisible;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: !confirmPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(confirmPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          confirmPasswordVisible = !confirmPasswordVisible;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final email = emailController.text.trim();
                      final password = passwordController.text.trim();
                      final confirmPassword = confirmPasswordController.text.trim();

                      if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Please fill all fields')),
                        );
                        return;
                      }

                      if (password != confirmPassword) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Passwords do not match')),
                        );
                        return;
                      }

                      try {
                        await FirebaseAuth.instance.createUserWithEmailAndPassword(
                          email: email,
                          password: password,
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Account created!')),
                        );

                        // Navigate back to Login screen
                        Navigator.pop(context);
                      } on FirebaseAuthException catch (e) {
                        String message = 'Sign up failed';
                        if (e.code == 'email-already-in-use') {
                          message = 'Email already in use';
                        } else if (e.code == 'weak-password') {
                          message = 'Password is too weak';
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(message)),
                        );
                      }
                    },
                    child: Text('Sign Up'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromRGBO(82, 45, 11, 1),
                      foregroundColor: Color.fromRGBO(253, 251, 215, 1),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Already have an account? "),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Text(
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
