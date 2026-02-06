import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:draft_asgn/HomeScreen.dart';

class ManageServicesScreen extends StatelessWidget {
  final String shopId;
  const ManageServicesScreen({super.key, required this.shopId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final servicesRef = FirebaseFirestore.instance
        .collection('shops')
        .doc(shopId)
        .collection('services');

    final stream = servicesRef.orderBy('createdAt', descending: true).snapshots();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Image.asset('assets/img/pawpal_logo.png', height: 65),
        iconTheme: IconThemeData(
          color: theme.colorScheme.primary,
          size: 26
        ),
      ),
      floatingActionButton: FloatingActionButton(
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
            return Center(
              child: Text(
                "No services yet.\nTap + to add your first service.",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ===== HEADER CARD (FIXED WIDTH) =====
              SizedBox(
                width: double.infinity,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Manage Services",
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Add, edit, activate or delete your services.",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
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
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: ListTile(
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

// ================================================================

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
  final _formKey = GlobalKey<FormState>();

  final nameCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final durationCtrl = TextEditingController();
  final priceCtrl = TextEditingController();

  bool isActive = true;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.serviceId != null) {
      _load();
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    descCtrl.dispose();
    durationCtrl.dispose();
    priceCtrl.dispose();
    super.dispose();
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
    final theme = Theme.of(context);
    final isEdit = widget.serviceId != null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Image.asset('assets/img/pawpal_logo.png', height: 65),
        iconTheme: IconThemeData(
          color: theme.colorScheme.primary,
          size: 26
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
                    // ===== HEADER CARD =====
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEdit ? "Update Service" : "New Service",
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isEdit
                                  ? "Edit the fields and save changes."
                                  : "Fill in the details to add a service.",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: "Service name"),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? "Required" : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: descCtrl,
                      decoration:
                          const InputDecoration(labelText: "Description (optional)"),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: durationCtrl,
                      decoration:
                          const InputDecoration(labelText: "Duration (e.g. 45 mins)"),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: priceCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: "Price"),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? "Required" : null,
                    ),
                    const SizedBox(height: 12),

                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Active"),
                      value: isActive,
                      onChanged: (v) => setState(() => isActive = v),
                    ),

                    const SizedBox(height: 16),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _save,
                        child: const Text(
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