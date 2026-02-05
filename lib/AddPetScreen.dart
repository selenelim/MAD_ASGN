import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:draft_asgn/HomeScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddPetScreen extends StatefulWidget {
  final String? petId;
  final Map<String, dynamic>? existingPetData;

  const AddPetScreen({
    super.key,
    this.petId,
    this.existingPetData,
  });

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

  final ImagePicker _picker = ImagePicker();
  File? petImage;
  String? existingBase64;

  bool get isEditMode => widget.petId != null;

  @override
  void initState() {
    super.initState();

    final data = widget.existingPetData;
    if (data != null) {
      nameController.text = (data['name'] ?? '').toString();
      breedController.text = (data['breed'] ?? '').toString();
      ageController.text = (data['age'] ?? '').toString();
      notesController.text = (data['notes'] ?? '').toString();
      species = data['species'];
      size = data['size'];

      final pic = data['profilePicBase64'];
      if (pic is String && pic.isNotEmpty) {
        existingBase64 = pic;
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    breedController.dispose();
    ageController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => petImage = File(image.path));
    }
  }

  void _removePhoto() {
    setState(() {
      petImage = null;
      existingBase64 = null;
    });
  }

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

    String? imageBase64ToSave;
    if (petImage != null) {
      final bytes = await petImage!.readAsBytes();
      imageBase64ToSave = base64Encode(bytes);
    } else {
      imageBase64ToSave = existingBase64;
    }

    final petsCol = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('pets');

    final payload = <String, dynamic>{
      'name': nameController.text.trim(),
      'species': species!,
      'breed': breedController.text.trim(),
      'size': size!,
      'age': ageController.text.trim(),
      'notes': notesController.text.trim(),
      'profilePicBase64': imageBase64ToSave,
    };

    try {
      if (isEditMode) {
        await petsCol.doc(widget.petId!).update(payload);
      } else {
        await petsCol.add({...payload, 'createdAt': Timestamp.now()});
      }

      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to save pet: $e')));
      }
    } finally {
      if (context.mounted) setState(() => isLoading = false);
    }
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
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(text,
          style: const TextStyle(fontWeight: FontWeight.bold)),
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
          ? (value) => value == null || value.trim().isEmpty ? 'Required' : null
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

  @override
  Widget build(BuildContext context) {
    ImageProvider? previewImage;

    if (petImage != null) {
      previewImage = FileImage(petImage!);
    } else if (existingBase64 != null) {
      try {
        previewImage = MemoryImage(base64Decode(existingBase64!));
      } catch (_) {}
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        centerTitle: true,
        title: Image.asset('assets/img/pawpal_logo.png', height: 65),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditMode ? 'Edit your pet 🐾' : 'Tell us about your pet 🐾',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              isEditMode
                  ? 'Update your pet details anytime'
                  : 'Help us provide the best care for your furry friend',
              style: const TextStyle(fontSize: 17),
            ),
            const SizedBox(height: 20),

            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔒 EVERYTHING BELOW UNCHANGED STRUCTURALLY
                  // (buttons, fields, layout all intact)

                  // Photo section
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.grey[300],
                              image: previewImage != null
                                  ? DecorationImage(
                                      image: previewImage,
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: previewImage == null
                                ? const Icon(Icons.add_a_photo,
                                    size: 40, color: Colors.white)
                                : null,
                          ),
                        ),
                        const SizedBox(height: 10),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _pickImage,
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Choose Photo'),
                            ),
                            const SizedBox(width: 10),
                            if (previewImage != null)
                              OutlinedButton.icon(
                                onPressed: _removePhoto,
                                icon: const Icon(Icons.delete_outline),
                                label: const Text('Remove'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

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
                  _textField(breedController,
                      'e.g. Golden Retriever, British Shorthair'),

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
                  _textField(notesController,
                      'Any allergies or temperament...', maxLines: 3),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _savePet,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : Text(isEditMode ? 'Update Pet' : 'Save Pet'),
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
}

