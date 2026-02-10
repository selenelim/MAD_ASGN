import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RegisterBusinessScreen extends StatefulWidget {
  const RegisterBusinessScreen({super.key});

  @override
  State<RegisterBusinessScreen> createState() => _RegisterBusinessScreenState();
}

class _RegisterBusinessScreenState extends State<RegisterBusinessScreen> {
  final _formKey = GlobalKey<FormState>();                                      //A key that lets you control the Form (like calling validate())

  final businessCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final noteCtrl = TextEditingController();

  bool submitting = false;

  @override
  void dispose() {
    //free the controllers from memory
    businessCtrl.dispose();
    phoneCtrl.dispose();
    noteCtrl.dispose();
    super.dispose();
  }

  //helper function to avoid repeating decoration code
  InputDecoration _input(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;   //Runs all validator: functions in the form fields      If anything returns error -> validation fails -> stop (return)

    final user = FirebaseAuth.instance.currentUser;   //gets logged in user
    if (user == null) return;                         //If no user is logged in, dont submit anything

    setState(() => submitting = true);                //Update states sp UI rebuilds: button is disabled and spinner appears -> same as _isLoading in other files

    try {
      final appRef = FirebaseFirestore.instance       //points to providerApplications/{user.uid}  ->  Each user has 1 application doc
          .collection('providerApplications')
          .doc(user.uid);

      await appRef.set({                              //Saves application details
        'applicantUid': user.uid,
        'email': user.email ?? '',
        'businessName': businessCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
        'note': noteCtrl.text.trim(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));                    //Wont overwrite the entire doc, it updates/merges fields

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({        //writes to users/{uid} -> Ensures role stays 'user' or now
        'role': 'user',
        'providerApplied': true,
        'providerAppliedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;                                                           //Checks the widget is still on screen -> Prevents error if user left mid submission
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Application submitted ✅ Await admin approval."),            //Shows popup message
        ),
      );
      Navigator.pop(context);                                                         //Closes this screen and returns to previous screen
    } catch (e) {                                                                     //If Firestore throws an error, show it
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {                                                                       //Runs whether success or error
      if (mounted) setState(() => submitting = false);                                //Resets submitting so button become clickable again
    }
  }
  //UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        title: Image.asset(
          'assets/img/pawpal_logo.png',
          height: 65,
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(                                                                  //Wraps inputs in a Form so validation works
          key: _formKey,
          child: ListView(                                                            //Makes it scrollable
            children: [
              // ===== HEADER CARD  =====
              Container(                                                              //Big rounded container
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).appBarTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Become a Provider",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).scaffoldBackgroundColor, 
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Submit your business details for admin approval.",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).scaffoldBackgroundColor, 
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: businessCtrl,
                decoration: _input("Business / Company Name"),
                validator: (v) =>                                             //if empty -> show 'required'   if ok -> null means no error
                    (v == null || v.trim().isEmpty) ? "Required" : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: phoneCtrl,
                decoration: _input("Contact Phone Number"),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? "Required" : null,       //if empty -> show 'required'   if ok -> null means no error
              ),
              const SizedBox(height: 12),

              TextFormField(                                                   //No validator since it is optional, Multiline text box
                controller: noteCtrl,
                maxLines: 4,
                decoration: _input(
                  "Proof of legitimacy (optional)",
                  hint:
                      "e.g. UEN, website, Instagram, licence, years in business",
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: submitting ? null : _submit,       //submitting=true ->onPressed: null else it runs _submit-> sets submitting to true
                  child: submitting                             //If submitting = true, show spinner
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(                             //Else show "Submit Application"
                          "Submit Application",
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
