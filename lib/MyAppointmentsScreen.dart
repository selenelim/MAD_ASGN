import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'HomeScreen.dart';

class MyAppointmentsScreen extends StatelessWidget {
  const MyAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      
      appBar: AppBar(
        title: const Text('My Appointments'),
      ),
      body: user == null
          ? Center(
              child: Text(
                'Please log in',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('bookings')
                  .orderBy('date', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No appointments yet 🐾',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ,
                    ),
                  );
                }

                final upcoming = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['status'] == 'upcoming';
                }).toList();

                final cancelled = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['status'] == 'cancelled';
                }).toList();

                final past = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['status'] == 'completed';
                }).toList();

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (upcoming.isNotEmpty) ...[
                      _sectionTitle(context, 'Upcoming Appointments'),
                      ...upcoming.map(
                        (doc) =>
                            _appointmentCard(context, doc, showCancel: true),
                      ),
                    ],
                    if (cancelled.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _sectionTitle(context, 'Cancelled Appointments'),
                      ...cancelled.map(
                        (doc) =>
                            _appointmentCard(context, doc, showCancel: false),
                      ),
                    ],
                    if (past.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _sectionTitle(context, 'Past Appointments'),
                      ...past.map(
                        (doc) =>
                            _appointmentCard(context, doc, showCancel: false),
                      ),
                    ],
                  ],
                );
              },
            ),
    );
  }

  // ---------------- UI HELPERS ----------------

  static Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }

  static Widget _appointmentCard(
    BuildContext context,
    QueryDocumentSnapshot doc, {
    required bool showCancel,
  }) {
    final data = doc.data() as Map<String, dynamic>;
    final date = (data['date'] as Timestamp).toDate();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius:
            (Theme.of(context).cardTheme.shape as RoundedRectangleBorder?)
                    ?.borderRadius ??
                BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data['serviceName'] ?? '',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            data['storeName'] ?? '',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: Theme.of(context).iconTheme.color,
              ),
              const SizedBox(width: 6),
              Text(
                '${date.day}/${date.month}/${date.year}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.access_time,
                size: 16,
                color: Theme.of(context).iconTheme.color,
              ),
              const SizedBox(width: 6),
              Text(
                data['time'] ?? '',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          if (showCancel) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _cancelAppointment(context, doc),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------- CANCEL LOGIC ----------------

  static Future<void> _cancelAppointment(
    BuildContext context,
    QueryDocumentSnapshot doc,
  ) async {
    final data = doc.data() as Map<String, dynamic>;
    final firestore = FirebaseFirestore.instance;

    final bookingId =
        '${data['storeName']}_${(data['date'] as Timestamp).toDate().toIso8601String().split('T')[0]}_${data['time']}';

    try {
      await doc.reference.update({'status': 'cancelled'});
      await firestore.collection('bookings').doc(bookingId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment cancelled')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to cancel appointment')),
      );
    }
  }
}

