import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool loading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  void _loadCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _nameController.text =
        user.displayName ?? user.email?.split('@').first ?? '';
    _emailController.text = user.email ?? '';
  }

  Future<bool> _reauthenticate(User user) async {
    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text.trim(),
      );
      await user.reauthenticateWithCredential(credential);
      return true;
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Current password is incorrect')),
      );
      return false;
    }
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    FocusScope.of(context).unfocus(); // 🔥 CLOSE KEYBOARD
    setState(() => loading = true);

    final newName = _nameController.text.trim();
    final newEmail = _emailController.text.trim();
    final newPassword = _newPasswordController.text.trim();

    try {
      if (newName.isNotEmpty && newName != user.displayName) {
        await user.updateDisplayName(newName);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(
          {'displayName': newName},
          SetOptions(merge: true),
        );
      }

      if ((newEmail != user.email && newEmail.isNotEmpty) ||
          newPassword.isNotEmpty) {
        final ok = await _reauthenticate(user);
        if (!ok) {
          setState(() => loading = false);
          return;
        }

        if (newEmail != user.email && newEmail.isNotEmpty) {
          await user.updateEmail(newEmail);
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set(
            {'email': newEmail},
            SetOptions(merge: true),
          );
        }

        if (newPassword.isNotEmpty) {
          await user.updatePassword(newPassword);
        }
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // ✅ KEY FIX
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Display Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                 

                  TextField(
                    controller: _currentPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Current Password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _newPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'New Password (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: loading ? null : _saveProfile,
                      child: const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            ),

            if (loading)
              Container(
                color: Colors.black.withOpacity(0.25),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

