import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:draft_asgn/HomeScreen.dart';

class ProviderEditShopScreen extends StatefulWidget {
  final String shopId;
  const ProviderEditShopScreen({super.key, required this.shopId});

  @override
  State<ProviderEditShopScreen> createState() => _ProviderEditShopScreenState();
}

class _ProviderEditShopScreenState extends State<ProviderEditShopScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final latCtrl = TextEditingController();
  final lngCtrl = TextEditingController();
  final mapsUrlCtrl = TextEditingController();

  bool isPublished = true;
  bool loading = true;

  static const Color brown = HomeScreen.brown;
  static const Color lightCream = HomeScreen.lightCream;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    addressCtrl.dispose();
    latCtrl.dispose();
    lngCtrl.dispose();
    mapsUrlCtrl.dispose();
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

  Future<void> _load() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('shops')
          .doc(widget.shopId)
          .get();

      if (!doc.exists) {
        if (mounted) setState(() => loading = false);
        return;
      }

      final d = doc.data() as Map<String, dynamic>;

      nameCtrl.text = (d['name'] ?? '').toString();
      phoneCtrl.text = (d['phone'] ?? '').toString();
      addressCtrl.text = (d['address'] ?? '').toString();
      isPublished = (d['isPublished'] ?? true) == true;

      mapsUrlCtrl.text = (d['mapsUrl'] ?? '').toString();

      final loc = d['location'];
      if (loc is GeoPoint) {
        latCtrl.text = loc.latitude.toString();
        lngCtrl.text = loc.longitude.toString();
      }

      if (mounted) setState(() => loading = false);
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final lat = double.tryParse(latCtrl.text.trim());
    final lng = double.tryParse(lngCtrl.text.trim());
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lat/Lng must be numbers")),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('shops').doc(widget.shopId).update({
        'name': nameCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
        'address': addressCtrl.text.trim(),
        'location': GeoPoint(lat, lng),
        'mapsUrl': mapsUrlCtrl.text.trim(),
        'isPublished': isPublished,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Saved ✅")),
      );
      Navigator.pop(context); // optional: go back after save
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
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
        title: Image.asset('assets/img/pawpal_logo.png', height: 65),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
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
                            "Edit Shop Details",
                            style: TextStyle(
                              color: lightCream,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Update your shop info and save changes.",
                            style: TextStyle(color: lightCream),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: nameCtrl,
                      decoration: _input("Shop name"),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? "Required" : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: phoneCtrl,
                      decoration: _input("Phone"),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? "Required" : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: addressCtrl,
                      decoration: _input("Address"),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? "Required" : null,
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
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: _input("Latitude"),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? "Required" : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: lngCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: _input("Longitude"),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? "Required" : null,
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
                        onPressed: _save,
                        child: const Text(
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
