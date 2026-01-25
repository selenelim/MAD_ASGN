import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddEditShopScreen extends StatefulWidget {
  final String? shopId; // null = add, not null = edit
  const AddEditShopScreen({super.key, this.shopId});

  @override
  State<AddEditShopScreen> createState() => _AddEditShopScreenState();
}

class _AddEditShopScreenState extends State<AddEditShopScreen> {
  static const Color brown = Color.fromRGBO(82, 45, 11, 1);
  static const Color lightCream = Color.fromRGBO(253, 251, 215, 1);

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _address = TextEditingController();
  String _category = 'grooming';
  bool _isPublished = true;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.shopId != null) {
      _loadShop();
    }
  }

  Future<void> _loadShop() async {
    setState(() => _loading = true);
    final doc = await FirebaseFirestore.instance.collection('shops').doc(widget.shopId).get();
    final data = doc.data() ?? {};
    _name.text = (data['name'] ?? '').toString();
    _address.text = (data['address'] ?? '').toString();
    _category = (data['category'] ?? 'grooming').toString();
    _isPublished = (data['isPublished'] ?? true) == true;
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _loading = true);

    final payload = <String, dynamic>{
      'name': _name.text.trim(),
      'address': _address.text.trim(),
      'category': _category,
      'isPublished': _isPublished,
      'ownerId': user.uid,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final shops = FirebaseFirestore.instance.collection('shops');

    if (widget.shopId == null) {
      payload['createdAt'] = FieldValue.serverTimestamp();
      await shops.add(payload);
    } else {
      await shops.doc(widget.shopId).update(payload);
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightCream,
      appBar: AppBar(
        backgroundColor: brown,
        foregroundColor: Colors.white,
        title: Text(widget.shopId == null ? "Add Shop" : "Edit Shop"),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(labelText: "Shop name"),
                      validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _address,
                      decoration: const InputDecoration(labelText: "Address"),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _category,
                      items: const [
                        DropdownMenuItem(value: 'grooming', child: Text("Grooming")),
                        DropdownMenuItem(value: 'vet', child: Text("Vet")),
                        DropdownMenuItem(value: 'training', child: Text("Training")),
                        DropdownMenuItem(value: 'boarding', child: Text("Boarding")),
                      ],
                      onChanged: (v) => setState(() => _category = v ?? 'grooming'),
                      decoration: const InputDecoration(labelText: "Category"),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      value: _isPublished,
                      onChanged: (v) => setState(() => _isPublished = v),
                      title: const Text("Published (visible to users)"),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: brown),
                        onPressed: _save,
                        child: Text(_loading ? "Saving..." : "Save"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
