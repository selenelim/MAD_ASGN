import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final cream = theme.scaffoldBackgroundColor;

    return Scaffold(
      
      appBar: AppBar(
  backgroundColor: Colors.transparent, // 🔹 same as Edit Shop
  elevation: 0,
  centerTitle: true,
  title: Image.asset(
    'assets/img/pawpal_logo.png',
    height: 65,
  ),
),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              /// ===== HEADER CARD (theme-based) =====
              Container(
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
        "New Shop",
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Theme.of(context).scaffoldBackgroundColor, 
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        "Fill in the details below to add your shop.",
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).scaffoldBackgroundColor, 
        ),
      ),
    ],
  ),
),



              const SizedBox(height: 16),

              TextFormField(
                controller: nameCtrl,
                decoration:
                    const InputDecoration(labelText: "Shop name"),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? "Required" : null,
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: phoneCtrl,
                decoration:
                    const InputDecoration(labelText: "Phone"),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? "Required" : null,
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: addressCtrl,
                decoration:
                    const InputDecoration(labelText: "Address"),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? "Required" : null,
              ),

              const SizedBox(height: 18),

              Text(
                "Google Maps Link (for Directions)",
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              TextFormField(
                controller: mapsUrlCtrl,
                decoration: const InputDecoration(
                  labelText: "Paste Google Maps link",
                  hintText: "https://maps.app.goo.gl/xxxxx",
                ),
              ),

              const SizedBox(height: 18),

              Text(
                "Location (for distance calculation)",
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              TextFormField(
                controller: latCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration:
                    const InputDecoration(labelText: "Latitude"),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? "Required" : null,
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: lngCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration:
                    const InputDecoration(labelText: "Longitude"),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? "Required" : null,
              ),

              const SizedBox(height: 18),

              DropdownButtonFormField<String>(
                value: category,
                decoration:
                    const InputDecoration(labelText: "Category"),
                items: const [
                  DropdownMenuItem(
                      value: 'grooming', child: Text('Grooming')),
                  DropdownMenuItem(value: 'vet', child: Text('Vet')),
                  DropdownMenuItem(
                      value: 'training', child: Text('Training')),
                  DropdownMenuItem(
                      value: 'boarding', child: Text('Boarding')),
                ],
                onChanged: (v) => setState(() => category = v ?? 'grooming'),
              ),

              const SizedBox(height: 12),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  "Published",
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                value: isPublished,
                onChanged: (v) => setState(() => isPublished = v),
              ),

              const SizedBox(height: 16),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: loading ? null : _save,
                  child: loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Text(
                          "Save",
                          style: TextStyle(fontWeight: FontWeight.bold),
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

