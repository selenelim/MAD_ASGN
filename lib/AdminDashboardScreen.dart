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
  String _status = 'pending'; // pending | approved | rejected  Default is 'pending'
  //So when we open the page, we see Pending Applications

  //Approve Logic

  Future<void> _approve(DocumentSnapshot appDoc, BuildContext context) async {
    final data = (appDoc.data() as Map<String, dynamic>?) ?? {};                    //Reads its data map
    final uid = (data['applicantUid'] ?? '').toString();                            //Extracts applicantUid

    if (uid.isEmpty) {                                                              //If application doc doesnt contain UID, stops and shows error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Missing applicantUid ❌")),
      );
      return;
    }

    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);      //Points to /users/<uid>
    final appRef = appDoc.reference;                                              //Points to this application document
    final batch = FirebaseFirestore.instance.batch();                             //Allows multiple writes to commit together
    //Batch 1: Set user role as provider
    batch.set(
      userRef,                                                                    //Updates user document so user becomes a Provider
      {
        'role': 'provider',
        'providerApproved': true,
        'providerApprovedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),                                                    //Wont overwrite entire user document - only merges these fields in
    );
    //Batch 2: Mark Application as approved
    batch.update(appRef, {                                                        //Updates application record/s status + timestamps
      'status': 'approved',
      'approvedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();                                                         //Applies both batch 1 & 2 updates together

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Approved ✅ Provider can now add shops.")),
      );
    }
  }
  //Reject Logic
  Future<void> _reject(
    DocumentReference appRef,
    BuildContext context,
    String reason,
  ) async {
    await appRef.update({                                              //Updates only the application document -> Adds rejection reason + timestamps
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
    final ctrl = TextEditingController();                     //ctrl stores what admin types as reason
    final theme = Theme.of(context);

    final ok = await showDialog<bool>(                        //returns ok=true if reject is pressed, ok=false if cancel
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

    if (ok == true) {                                             //Reject button pressed
      await _reject(appRef, context, ctrl.text.trim());           //Calls _reject() -> Reject Logic
    }
  }

  Stream<QuerySnapshot> _streamByStatus() {       //Since it is .snapshots(), the UI updates live when Firestore changes
    return FirebaseFirestore.instance             //If _status='approved' -> stream shows only approved docs
        .collection('providerApplications')       //If _status='rejected' -> stream shows only rejected docs
        .where('status', isEqualTo: _status)      //If _status='pending' -> stream shows only pending docs
        .snapshots();
  }

  Future<void> _logout(BuildContext context) async {            //LogOut -> Signs User ouy
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(                               //Clears navigation stack (so admin cant press back to return)
      context,
      MaterialPageRoute(builder: (_) => const AuthWrapper()),   //Sends back to AuthWrapper
      (_) => false,
    );
  }

  // UI

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? 'admin';

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _adminHeader(context, userEmail),

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
            //List
            StreamBuilder<QuerySnapshot>(
              stream: _streamByStatus(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {    //While loading -> Shows Spinner
                  return const Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {                                       //No docs -> Shows "No Applications"
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      "No applications.",
                      style: theme.textTheme.bodyMedium,
                    ),
                  );
                }
                //Else
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: docs.map((doc) {
                    final d = (doc.data() as Map<String, dynamic>?) ?? {};
                    return _ApplicationCard(                                    //Converts each Firestore doc into _ApplicationCard()
                      data: d,
                      status: _status,
                      onApprove: _status == 'pending'
                          ? () => _approve(doc, context)                      //Approve/Reject buttons only exist when status is pending
                          : null,
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

  // Header -> Admin Email from FirebaseAuth
  //Displays Logo Image, LogOut icon Button, "Admin Dashboard", "Hello <name> 👋", "Review provider appplications"

  Widget _adminHeader(BuildContext context, String email) {
    final theme = Theme.of(context);
    final name = email.contains('@') ? email.split('@').first : email;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset(
                'assets/img/pawpal_logo_cream.png',
                height: 45,
              ),

              CircleAvatar(
                backgroundColor: theme.colorScheme.surface,
                child: IconButton(
                  icon: Icon(Icons.logout, color: theme.colorScheme.primary),
                  onPressed: () => _logout(context),
                  tooltip: "Logout",
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Text(
            "Admin Dashboard",
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),

          Text(
            "Hello $name 👋",
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),

          Text(
            "Review provider applications",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimary.withOpacity(0.95),
            ),
          ),
        ],
      ),
    );
  }

  //Tabs -> Pill Buttons x3 -> Pending, Approved, Rejected

  Widget _statusTabs(BuildContext context) {
    final theme = Theme.of(context);

    Widget pill(String label, String value) {
      final active = _status == value;
      return Expanded(
        child: InkWell(
          onTap: () => setState(() => _status = value),                               //Switches it between Pending/Approced/Rejected -> Tap a pill -> _status changes and widget rebuilds
          borderRadius: BorderRadius.circular(22),                                    //List updates automatically
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: active ? theme.colorScheme.primary : theme.colorScheme.surface,
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

//Application Card
//Dsiplays Business Name, Category, Phone
//Approved/Rejected Cards Display only
//Pending has Approve + Reject buttons
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
                  child: ElevatedButton.icon(           //Approve Button
                    onPressed: onApprove,
                    icon: const Icon(Icons.check),
                    label: const Text("Approve"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(           //Reject Button
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
