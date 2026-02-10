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
  bool rememberMe = false;                                                        //Checkbox value
  bool passwordVisible = false;                                                   //show/hide password
  bool loading = false;                                                           //true -> disable button + show spinner

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void initState() {        //runs once when screen loads
    super.initState();
    _loadRememberMe();      //loads saved rememberMe value from phone storage
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ✅ If rememberMe was saved AND Firebase already has a user session,
  // route through AuthGate (so admin/provider/user is correct).
  Future<void> _loadRememberMe() async {                                      //async as SharedPreferences is async
    final prefs = await SharedPreferences.getInstance();                      //get local storage instance
    final saved = prefs.getBool('rememberMe') ?? false;                       //Reads saved value, default to false if not found

    if (!mounted) return;
    setState(() => rememberMe = saved);                                       //Updates checkbox UI
  }

  //Forgot Password Dialog
  void _showForgotPasswordDialog() {                                //Opens popup dialog
    showDialog(
      context: context,
      builder: (context) {                                          //builds dialog UI
        final resetEmailController =
            TextEditingController(text: emailController.text);      //pre-fills email fiels with wtv user typed earlier

        return AlertDialog(
           title: Text(
            'Reset Password',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          
          content: TextField(
            controller: resetEmailController,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),                            //Cancel button -> Closes dialog
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color.fromRGBO(176, 115, 68, 1)),
              ),
            ),
            ElevatedButton(
              onPressed: () async {                                               //Aync because firebase call
                final email = resetEmailController.text.trim();                   //clean input
                if (email.isEmpty) {                                              //validation
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter your email')),     //sends error msg
                  );
                  return;
                }

                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(             //Firebase sends reset email
                    email: email,
                  );
                  if (!context.mounted) return;                                   //safety check
                  Navigator.pop(context);                                         //close dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password reset email sent. Check your inbox 📧'),    //success msg
                    ),
                  );
                } on FirebaseAuthException catch (e) {
                  String message = 'Failed to send reset email';
                  if (e.code == 'user-not-found') {                                 //email not registered
                    message = 'No user found with this email';
                  } else if (e.code == 'invalid-email') {                           //bad email format
                    message = 'Invalid email address';
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(message)),                               //displays the msg
                  );
                }
              },
             
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
  }
  //Sign In
  Future<void> signIn() async {
    setState(() => loading = true);                                               //Disable button + show spinner

    try {
      final email = emailController.text.trim();
      final password = passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {                                    //validation
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter email and password')),       //Display msg
        );
        return;
      }

      await FirebaseAuth.instance.signInWithEmailAndPassword(                     //Firebase login
        email: email,
        password: password,
      );

      // ✅ save rememberMe after successful login
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('rememberMe', rememberMe);

      if (!mounted) return;
      //Success
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login successful 🐾')),
      );

      //Clears login screen from stack and Routes user to AuthGate for role-based routing
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {                  //Error Handling
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
    } finally {                                            //Always stop loading spinner
      if (mounted) setState(() => loading = false);
    }
  }
  //UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
  backgroundColor: Colors.transparent, // override theme
  elevation: 0,
  centerTitle: true,
  title: Image.asset(
    'assets/img/pawpal_logo.png',
    height: 65,
  ),
),
      body: Center(
        child: SingleChildScrollView(                                                     //Prevents overflow when keyboard appears
          child: Container(                                                               //White rounded card with shadow
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
               Text(
                  'Welcome Back!',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue caring for your pets',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 24),

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
                  obscureText: !passwordVisible,                                        //Hides password unless toggled
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(                                             //Password Visibility Toggle
                      icon: Icon(
                        passwordVisible ? Icons.visibility : Icons.visibility_off,      //True=Visible    False=Not Visible  ->Default is false
                      ),
                      onPressed: () => setState(() {
                        passwordVisible = !passwordVisible;                             //Toggles passwordVisible
                      }),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                //Remember Me + Forgot Password
                Row(
                  children: [
                    Checkbox(
                      value: rememberMe,
                      activeColor: const Color.fromRGBO(176, 115, 68, 1),
                      onChanged: (value) {
                        setState(() => rememberMe = value ?? false);
                      },
                    ),
                     const Text('Remember me'),
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
                //Sign In Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loading ? null : signIn,                   //Disable Button when loading is true, leading=false ->Press ->run signIn
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
                          MaterialPageRoute(builder: (_) => const SignUpScreen()),        //Sign Up Link
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
