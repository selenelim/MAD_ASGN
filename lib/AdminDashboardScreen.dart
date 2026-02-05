import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:draft_asgn/AuthWrapper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String _status = 'pending'; // pending | approved | rejected

  // ================= LOGIC (UNCHANGED) =================

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
    final theme = Theme.of(context);

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          "Reject application",
          style: theme.textTheme.titleMedium,
        ),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: "Reason (optional)",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
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

  Stream<QuerySnapshot> _streamByStatus() {
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

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? 'admin';

    return Scaffold(
      
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Stack(
              children: [
                _adminHeader(context, userEmail),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () => _logout(context),
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
              style: theme.textTheme.titleMedium,
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

                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      "No applications.",
                      style: theme.textTheme.bodyMedium,
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: docs.map((doc) {
                    final d = (doc.data() as Map<String, dynamic>?) ?? {};
                    return _ApplicationCard(
                      data: d,
                      status: _status,
                      onApprove:
                          _status == 'pending' ? () => _approve(doc, context) : null,
                      onReject: _status == 'pending'
                          ? () => _promptReject(context, doc.reference)
                          : null,
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 18),
            _statusTabs(context),
          ],
        ),
      ),
    );
  }

  Widget _adminHeader(BuildContext context, String email) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Admin Dashboard",
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Hello ${email.split('@').first} 👋",
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Review provider applications",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusTabs(BuildContext context) {
    final theme = Theme.of(context);

    Widget pill(String label, String value) {
      final active = _status == value;
      return Expanded(
        child: InkWell(
          onTap: () => setState(() => _status = value),
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: active
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.25),
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: active
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.primary,
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

// ================= CARD =================

class _ApplicationCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String status;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const _ApplicationCard({
    required this.data,
    required this.status,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data['businessName'] ?? 'Unnamed',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 6),

          Text("Category: ${data['category'] ?? ''}"),
          Text("Phone: ${data['phone'] ?? ''}"),

          if (status == 'rejected' && (data['rejectionReason'] ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                "Reason: ${data['rejectionReason']}",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          if (status == 'pending') ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check),
                    label: const Text("Approve"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
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
}
