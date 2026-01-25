// ===================== LogInScreen.dart =====================
import 'package:draft_asgn/AuthGate.dart';
import 'package:draft_asgn/SignUpScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool rememberMe = false;
  bool passwordVisible = false;
  bool loading = false;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRememberMe();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ✅ If rememberMe was saved AND Firebase already has a user session,
  // route through AuthGate (so admin/provider/user is correct).
  Future<void> _loadRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool('rememberMe') ?? false;

    if (!mounted) return;
    setState(() => rememberMe = saved);
  }


  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final resetEmailController =
            TextEditingController(text: emailController.text);

        return AlertDialog(
          title: const Text(
            'Reset Password',
            style: TextStyle(
              color: Color.fromRGBO(82, 45, 11, 1),
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: const Color.fromRGBO(253, 251, 215, 1),
          content: TextField(
            controller: resetEmailController,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color.fromRGBO(176, 115, 68, 1)),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = resetEmailController.text.trim();
                if (email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter your email')),
                  );
                  return;
                }

                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(
                    email: email,
                  );
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password reset email sent. Check your inbox 📧'),
                    ),
                  );
                } on FirebaseAuthException catch (e) {
                  String message = 'Failed to send reset email';
                  if (e.code == 'user-not-found') {
                    message = 'No user found with this email';
                  } else if (e.code == 'invalid-email') {
                    message = 'Invalid email address';
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(message)),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(82, 45, 11, 1),
                foregroundColor: const Color.fromRGBO(253, 251, 215, 1),
              ),
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
  }

  Future<void> signIn() async {
    setState(() => loading = true);

    try {
      final email = emailController.text.trim();
      final password = passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter email and password')),
        );
        return;
      }

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // ✅ save rememberMe after successful login
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('rememberMe', rememberMe);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login successful 🐾')),
      );

      // ✅ route to AuthGate so roles work
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed';
      if (e.code == 'user-not-found') {
        message = 'No user found';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(253, 251, 215, 1),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Image.asset('assets/img/pawpal_logo.png', height: 65),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Welcome Back!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color.fromRGBO(82, 45, 11, 1),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sign in to continue caring for your pets',
                  style: TextStyle(color: Color.fromRGBO(82, 45, 11, 1)),
                ),
                const SizedBox(height: 24),

                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: passwordController,
                  obscureText: !passwordVisible,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        passwordVisible ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () => setState(() {
                        passwordVisible = !passwordVisible;
                      }),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: rememberMe,
                      activeColor: const Color.fromRGBO(176, 115, 68, 1),
                      onChanged: (value) {
                        setState(() => rememberMe = value ?? false);
                      },
                    ),
                    const Text(
                      'Remember me',
                      style: TextStyle(
                        color: Color.fromRGBO(82, 45, 11, 1),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _showForgotPasswordDialog,
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(color: Color.fromRGBO(176, 115, 68, 1)),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loading ? null : signIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(82, 45, 11, 1),
                      foregroundColor: const Color.fromRGBO(253, 251, 215, 1),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: loading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Color.fromRGBO(253, 251, 215, 1),
                            ),
                          )
                        : const Text('Sign In'),
                  ),
                ),

                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? "),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SignUpScreen()),
                        );
                      },
                      child: const Text(
                        'Sign up',
                        style: TextStyle(
                          color: Color.fromRGBO(176, 115, 68, 1),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
