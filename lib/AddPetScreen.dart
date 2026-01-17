import 'package:draft_asgn/HomeScreen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddPetScreen extends StatefulWidget {
  const AddPetScreen({super.key});

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController breedController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  String? species;
  String? size;

  bool isLoading = false;

  Future<void> _savePet() async {
    if (!_formKey.currentState!.validate()) return;

    if (species == null || size == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select species and size')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => isLoading = true);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('pets')
        .add({
      'name': nameController.text.trim(),
      'species': species!, // safe after null check
      'breed': breedController.text.trim(),
      'size': size!,       // safe after null check
      'age': ageController.text.trim(),
      'notes': notesController.text.trim(),
      'createdAt': Timestamp.now(),
    });

    Navigator.pop(context);
  }

  Widget _selectButton({
    required String label,
    required String value,
    required String? groupValue,
    required ValueChanged<String> onSelected,
  }) {
    final isSelected = value == groupValue;

    return Expanded(
      child: GestureDetector(
        onTap: () => onSelected(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF522D0B) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        centerTitle: true,
        title: Image.asset(
          'assets/img/pawpal_logo.png',
          height: 250,
        ),
      ),
      backgroundColor: const Color(0xFFFDFBD7),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text above form
            const Text(
              'Tell us about your pet 🐾',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: HomeScreen.brown,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Help us provide the best care for your furry friend',
              style: TextStyle(fontSize: 17),
            ),
            const SizedBox(height: 20),

            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Pet Name *'),
                  _textField(nameController, 'e.g. Max, Bella', required: true),

                  _label('Species *'),
                  Row(
                    children: [
                      _selectButton(
                        label: '🐶 Dog',
                        value: 'Dog',
                        groupValue: species,
                        onSelected: (v) => setState(() => species = v),
                      ),
                      const SizedBox(width: 12),
                      _selectButton(
                        label: '🐱 Cat',
                        value: 'Cat',
                        groupValue: species,
                        onSelected: (v) => setState(() => species = v),
                      ),
                    ],
                  ),

                  _label('Breed (optional)'),
                  _textField(breedController, 'e.g. Golden Retriever, British Shorthair'),

                  _label('Size *'),
                  Row(
                    children: [
                      _selectButton(
                        label: 'Small',
                        value: 'Small',
                        groupValue: size,
                        onSelected: (v) => setState(() => size = v),
                      ),
                      const SizedBox(width: 8),
                      _selectButton(
                        label: 'Medium',
                        value: 'Medium',
                        groupValue: size,
                        onSelected: (v) => setState(() => size = v),
                      ),
                      const SizedBox(width: 8),
                      _selectButton(
                        label: 'Large',
                        value: 'Large',
                        groupValue: size,
                        onSelected: (v) => setState(() => size = v),
                      ),
                    ],
                  ),

                  _label('Age *'),
                  _textField(ageController, 'e.g. 2 years', required: true),

                  _label('Notes (optional)'),
                  _textField(notesController, 'Any allergies or temperament...', maxLines: 3),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _savePet,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF522D0B),
                        foregroundColor: HomeScreen.lightCream,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text('Save Pet'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _textField(
    TextEditingController controller,
    String hint, {
    bool required = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: required
          ? (value) => value == null || value.isEmpty ? 'Required' : null
          : null,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
