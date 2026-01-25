import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:draft_asgn/HomeScreen.dart';

class ManageServicesScreen extends StatelessWidget {
  final String shopId;
  const ManageServicesScreen({super.key, required this.shopId});

  static const Color brown = HomeScreen.brown;
  static const Color lightCream = HomeScreen.lightCream;

  @override
  Widget build(BuildContext context) {
    final servicesRef = FirebaseFirestore.instance
        .collection('shops')
        .doc(shopId)
        .collection('services');

    final stream = servicesRef.orderBy('createdAt', descending: true).snapshots();

    return Scaffold(
      backgroundColor: lightCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        centerTitle: true,
        title: Image.asset('assets/img/pawpal_logo.png', height: 65),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: brown,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddEditServiceScreen(shopId: shopId),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text("Error: ${snap.error}"),
            );
          }

          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "No services yet.\nTap + to add your first service.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Top header card (same vibe)
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
                      "Add Services",
                      style: TextStyle(
                        color: lightCream,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Add, edit, activate or delete your services.",
                      style: TextStyle(color: lightCream),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              ...docs.map((d) {
                final serviceId = d.id;
                final m = d.data() as Map<String, dynamic>;

                final name = (m['name'] ?? '').toString();
                final price = (m['price'] ?? 0);
                final isActive = (m['isActive'] ?? true) == true;

                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.black12),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "Price: $price • ${isActive ? "Active" : "Inactive"}",
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == "edit") {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddEditServiceScreen(
                                shopId: shopId,
                                serviceId: serviceId,
                              ),
                            ),
                          );
                        } else if (v == "toggle") {
                          await servicesRef.doc(serviceId).update({
                            'isActive': !isActive,
                            'updatedAt': FieldValue.serverTimestamp(),
                          });
                        } else if (v == "delete") {
                          await servicesRef.doc(serviceId).delete();
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: "edit", child: Text("Edit")),
                        PopupMenuItem(
                          value: "toggle",
                          child: Text(isActive ? "Set Inactive" : "Set Active"),
                        ),
                        const PopupMenuItem(value: "delete", child: Text("Delete")),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class AddEditServiceScreen extends StatefulWidget {
  final String shopId;
  final String? serviceId;

  const AddEditServiceScreen({
    super.key,
    required this.shopId,
    this.serviceId,
  });

  @override
  State<AddEditServiceScreen> createState() => _AddEditServiceScreenState();
}

class _AddEditServiceScreenState extends State<AddEditServiceScreen> {
  static const Color brown = HomeScreen.brown;
  static const Color lightCream = HomeScreen.lightCream;

  final _formKey = GlobalKey<FormState>();

  final nameCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final durationCtrl = TextEditingController();
  final priceCtrl = TextEditingController();

  bool isActive = true;
  bool loading = false;

  @override
  void dispose() {
    nameCtrl.dispose();
    descCtrl.dispose();
    durationCtrl.dispose();
    priceCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.serviceId != null) {
      _load();
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

  Future<void> _load() async {
    setState(() => loading = true);

    final doc = await FirebaseFirestore.instance
        .collection('shops')
        .doc(widget.shopId)
        .collection('services')
        .doc(widget.serviceId)
        .get();

    final d = doc.data() ?? {};
    nameCtrl.text = (d['name'] ?? '').toString();
    descCtrl.text = (d['description'] ?? '').toString();
    durationCtrl.text = (d['durationText'] ?? '').toString();
    priceCtrl.text = (d['price'] ?? '').toString();
    isActive = (d['isActive'] ?? true) == true;

    setState(() => loading = false);
  }

  double _parsePrice(String s) => double.tryParse(s.trim()) ?? 0;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final data = <String, dynamic>{
      'name': nameCtrl.text.trim(),
      'description': descCtrl.text.trim(),
      'durationText': durationCtrl.text.trim(),
      'price': _parsePrice(priceCtrl.text),
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final servicesRef = FirebaseFirestore.instance
        .collection('shops')
        .doc(widget.shopId)
        .collection('services');

    if (widget.serviceId == null) {
      await servicesRef.add({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      await servicesRef.doc(widget.serviceId).update(data);
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.serviceId != null;

    return Scaffold(
      backgroundColor: lightCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        centerTitle: true,
        title: Text(
          isEdit ? "Edit Service" : "Add Service",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: brown,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEdit ? "Update Service" : "New Service",
                            style: const TextStyle(
                              color: lightCream,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isEdit
                                ? "Edit the fields and save changes."
                                : "Fill in the details to add a service.",
                            style: const TextStyle(color: lightCream),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: nameCtrl,
                      decoration: _input("Service name"),
                      validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: descCtrl,
                      decoration: _input("Description (optional)"),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: durationCtrl,
                      decoration: _input("Duration (e.g. 45 mins)"),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: priceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: _input("Price"),
                      validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
                    ),
                    const SizedBox(height: 12),

                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        "Active",
                        style: TextStyle(fontWeight: FontWeight.bold, color: brown),
                      ),
                      value: isActive,
                      activeColor: brown,
                      onChanged: (v) => setState(() => isActive = v),
                    ),

                    const SizedBox(height: 16),
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
