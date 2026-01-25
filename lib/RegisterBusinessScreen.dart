import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:draft_asgn/HomeScreen.dart';

class RegisterBusinessScreen extends StatefulWidget {
  const RegisterBusinessScreen({super.key});

  @override
  State<RegisterBusinessScreen> createState() => _RegisterBusinessScreenState();
}

class _RegisterBusinessScreenState extends State<RegisterBusinessScreen> {
  static const Color brown = HomeScreen.brown;
  static const Color lightCream = HomeScreen.lightCream;

  final _formKey = GlobalKey<FormState>();

  final businessCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final noteCtrl = TextEditingController();

  bool submitting = false;

  @override
  void dispose() {
    businessCtrl.dispose();
    phoneCtrl.dispose();
    noteCtrl.dispose();
    super.dispose();
  }

  InputDecoration _input(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: brown, fontWeight: FontWeight.w600),
      floatingLabelStyle: const TextStyle(color: brown, fontWeight: FontWeight.w700),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: brown.withOpacity(0.35), width: 1.4),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: brown, width: 2.2),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => submitting = true);

    try {
      // One application per user (overwrite if re-submitted)
      final appRef = FirebaseFirestore.instance
          .collection('providerApplications')
          .doc(user.uid);

      await appRef.set({
        'applicantUid': user.uid,
        'email': user.email ?? '',
        'businessName': businessCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
        'note': noteCtrl.text.trim(),

        // workflow
        'status': 'pending', // pending | approved | rejected
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Mark user as having applied (still NOT provider yet)
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'role': 'user',
        'providerApplied': true,
        'providerAppliedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Application submitted ✅ Await admin approval."),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        centerTitle: true,
        title: const Text(
          "Register Business",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // ===== Top header card =====
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: brown,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Become a Provider",
                      style: TextStyle(
                        color: lightCream,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Submit your business details for admin approval.",
                      style: TextStyle(color: lightCream),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: businessCtrl,
                decoration: _input("Business / Company Name"),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? "Required" : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: phoneCtrl,
                decoration: _input("Contact Phone Number"),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? "Required" : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: noteCtrl,
                maxLines: 4,
                decoration: _input(
                  "Proof of legitimacy (optional)",
                  hint: "e.g. UEN, website, Instagram, licence, years in business",
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brown,
                    foregroundColor: lightCream,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  onPressed: submitting ? null : _submit,
                  child: submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: lightCream,
                          ),
                        )
                      : const Text(
                          "Submit Application",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
