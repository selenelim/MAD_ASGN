import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:draft_asgn/AuthWrapper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:draft_asgn/HomeScreen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  static const Color brown = Color.fromRGBO(82, 45, 11, 1);
  static const Color lightCream = Color.fromRGBO(253, 251, 215, 1);

  String _status = 'pending'; // pending | approved | rejected

  // ---------- YOUR EXISTING LOGIC (kept) ----------
  Future<void> _approve(DocumentSnapshot appDoc, BuildContext context) async {
    final data = (appDoc.data() as Map<String, dynamic>?) ?? {};
    final uid = (data['applicantUid'] ?? '').toString();

    if (uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Missing applicantUid ❌")),
      );
      return;
    }

    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final appRef = appDoc.reference;

    final batch = FirebaseFirestore.instance.batch();

    batch.set(
      userRef,
      {
        'role': 'provider',
        'providerApproved': true,
        'providerApprovedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    batch.update(appRef, {
      'status': 'approved',
      'approvedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Approved ✅ Provider can now add shops.")),
      );
    }
  }

  Future<void> _reject(
    DocumentReference appRef,
    BuildContext context,
    String reason,
  ) async {
    await appRef.update({
      'status': 'rejected',
      'rejectionReason': reason,
      'rejectedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Rejected ❌")),
      );
    }
  }

  Future<void> _promptReject(BuildContext context, DocumentReference appRef) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: lightCream,
        title: const Text(
          "Reject application",
          style: TextStyle(color: brown, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: "Reason (optional)"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: brown)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: brown,
              foregroundColor: lightCream,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Reject"),
          ),
        ],
      ),
    );

    if (ok == true) {
      await _reject(appRef, context, ctrl.text.trim());
    }
  }
  // ---------- END YOUR LOGIC ----------

  Stream<QuerySnapshot> _streamByStatus() {
    // If Firestore asks for index, remove orderBy or create index.
    return FirebaseFirestore.instance
        .collection('providerApplications')
        .where('status', isEqualTo: _status)
        .snapshots();
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthWrapper()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? 'admin';

    return Scaffold(
      backgroundColor: lightCream,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ===== Header + logout top right (cream icon, no circle) =====
            Stack(
              children: [
                _adminHeader(userEmail),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: const Icon(Icons.logout, color: lightCream),
                    onPressed: () => _logout(context),
                    tooltip: "Logout",
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            Text(
              _status == 'pending'
                  ? 'Pending applications'
                  : _status == 'approved'
                      ? 'Approved applications'
                      : 'Rejected applications',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            StreamBuilder<QuerySnapshot>(
              stream: _streamByStatus(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snap.hasError) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text("Error: ${snap.error}"),
                  );
                }

                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _status == 'pending'
                          ? "No pending applications."
                          : _status == 'approved'
                              ? "No approved applications."
                              : "No rejected applications.",
                      style: const TextStyle(color: Colors.black54),
                    ),
                  );
                }

                // ✅ Make cards span full width
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: docs.map((doc) {
                    final d = (doc.data() as Map<String, dynamic>?) ?? {};
                    final business = (d['businessName'] ?? '').toString();
                    final category = (d['category'] ?? '').toString();
                    final phone = (d['phone'] ?? '').toString();
                    final note = (d['note'] ?? '').toString();
                    final rejectionReason = (d['rejectionReason'] ?? '').toString();

                    return _ApplicationCard(
                      business: business.isEmpty ? "Unnamed" : business,
                      category: category,
                      phone: phone,
                      note: note,
                      status: _status,
                      rejectionReason: rejectionReason,
                      onApprove: _status == 'pending' ? () => _approve(doc, context) : null,
                      onReject: _status == 'pending'
                          ? () => _promptReject(context, doc.reference)
                          : null,
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 18),
            _statusTabs(),
          ],
        ),
      ),
    );
  }

  Widget _adminHeader(String userEmail) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: brown,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Admin Dashboard",
            style: TextStyle(
              color: HomeScreen.lightCream,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Hello ${_shortName(userEmail)} 👋",
            style: const TextStyle(
              color: HomeScreen.lightCream,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Review provider applications",
            style: TextStyle(color: HomeScreen.lightCream),
          ),
        ],
      ),
    );
  }

  static String _shortName(String emailOrName) {
    if (!emailOrName.contains('@')) return emailOrName;
    return emailOrName.split('@').first;
  }

  Widget _statusTabs() {
    Widget pill(String label, String value) {
      final isOn = _status == value;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => setState(() => _status = value),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isOn ? brown : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: brown.withOpacity(0.25)),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isOn ? lightCream : brown,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        pill("Pending", "pending"),
        const SizedBox(width: 10),
        pill("Approved", "approved"),
        const SizedBox(width: 10),
        pill("Rejected", "rejected"),
      ],
    );
  }
}

// ======================= APPLICATION CARD UI =======================

class _ApplicationCard extends StatelessWidget {
  final String business;
  final String category;
  final String phone;
  final String note;

  final String status;
  final String rejectionReason;

  final VoidCallback? onApprove; // only for pending
  final VoidCallback? onReject;  // only for pending

  const _ApplicationCard({
    required this.business,
    required this.category,
    required this.phone,
    required this.note,
    required this.status,
    required this.rejectionReason,
    required this.onApprove,
    required this.onReject,
  });

  static const Color brown = Color.fromRGBO(82, 45, 11, 1);
  static const Color lightCream = Color.fromRGBO(253, 251, 215, 1);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, // ✅ full width
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            business,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),

          _row("Category", category),
          _row("Phone", phone),
          if (note.trim().isNotEmpty) _row("Note", note),

          if (status == 'rejected' && rejectionReason.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              "Reason: $rejectionReason",
              style: const TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],

          if (status == 'pending') ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brown,
                      foregroundColor: lightCream,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: onApprove,
                    icon: const Icon(Icons.check),
                    label: const Text("Approve"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: brown,
                      side: const BorderSide(color: brown, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: onReject,
                    icon: const Icon(Icons.close),
                    label: const Text("Reject"),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        "$k: $v",
        style: const TextStyle(color: Colors.black87),
      ),
    );
  }
}
