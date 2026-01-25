import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:draft_asgn/HomeScreen.dart';

class ProviderAddShopScreen extends StatefulWidget {
  const ProviderAddShopScreen({super.key});

  @override
  State<ProviderAddShopScreen> createState() => _ProviderAddShopScreenState();
}

class _ProviderAddShopScreenState extends State<ProviderAddShopScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final addressCtrl = TextEditingController();

  final mapsUrlCtrl = TextEditingController();

  final latCtrl = TextEditingController();
  final lngCtrl = TextEditingController();

  String category = 'grooming';
  bool isPublished = true;
  bool loading = false;

  static const Color brown = HomeScreen.brown;
  static const Color lightCream = HomeScreen.lightCream;

  @override
  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    addressCtrl.dispose();
    mapsUrlCtrl.dispose();
    latCtrl.dispose();
    lngCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final lat = double.tryParse(latCtrl.text.trim());
    final lng = double.tryParse(lngCtrl.text.trim());
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lat/Lng must be numbers")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      await FirebaseFirestore.instance.collection('shops').add({
        'ownerId': user.uid,
        'ownerUid': user.uid,
        'name': nameCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
        'address': addressCtrl.text.trim(),
        'category': category,
        'location': GeoPoint(lat, lng),
        'mapsUrl': mapsUrlCtrl.text.trim(),
        'isPublished': isPublished,
        'ratingAvg': 0,
        'ratingCount': 0,
        'priceFrom': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Shop added ✅")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        centerTitle: true,
        title: Image.asset('assets/img/pawpal_logo.png', height: 65),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // ===== Top info card (same vibe) =====
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
                      "New Shop",
                      style: TextStyle(
                        color: lightCream,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Fill in the details below to add your shop.",
                      style: TextStyle(color: lightCream),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: nameCtrl,
                decoration: _input("Shop name"),
                validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: phoneCtrl,
                decoration: _input("Phone"),
                validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: addressCtrl,
                decoration: _input("Address"),
                validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
              ),

              const SizedBox(height: 18),
              const Text(
                "Google Maps Link (for Directions)",
                style: TextStyle(fontWeight: FontWeight.bold, color: brown),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: mapsUrlCtrl,
                decoration: _input(
                  "Paste Google Maps link",
                  hint: "https://maps.app.goo.gl/xxxxx",
                ),
              ),

              const SizedBox(height: 18),
              const Text(
                "Location (for distance calculation)",
                style: TextStyle(fontWeight: FontWeight.bold, color: brown),
              ),
              const SizedBox(height: 8),

              TextFormField(
                controller: latCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _input("Latitude"),
                validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: lngCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _input("Longitude"),
                validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
              ),

              const SizedBox(height: 18),
              DropdownButtonFormField<String>(
                value: category,
                decoration: _input("Category"),
                dropdownColor: Colors.white,
                items: const [
                  DropdownMenuItem(value: 'grooming', child: Text('Grooming')),
                  DropdownMenuItem(value: 'vet', child: Text('Vet')),
                  DropdownMenuItem(value: 'training', child: Text('Training')),
                  DropdownMenuItem(value: 'boarding', child: Text('Boarding')),
                ],
                onChanged: (v) => setState(() => category = v ?? 'grooming'),
              ),

              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  "Published",
                  style: TextStyle(fontWeight: FontWeight.bold, color: brown),
                ),
                value: isPublished,
                activeColor: brown,
                onChanged: (v) => setState(() => isPublished = v),
              ),

              const SizedBox(height: 16),
              SizedBox(
                height: 52,
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brown,
                    foregroundColor: lightCream,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  onPressed: loading ? null : _save,
                  child: loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: lightCream,
                          ),
                        )
                      : const Text(
                          "Save",
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
