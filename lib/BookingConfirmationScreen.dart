import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingConfirmationScreen extends StatelessWidget {
  final String serviceName;
  final String storeName;
  final String storeAddress;
  final int price;
  final Map<String, dynamic> pet;
  final DateTime date;
  final String time;
  final String? notes;
  final String shopId;

  const BookingConfirmationScreen({
    super.key,
    required this.serviceName,
    required this.storeName,
    required this.storeAddress,
    required this.price,
    required this.pet,
    required this.date,
    required this.time,
    this.notes,
    required this.shopId,
  });

  String _formatDate(DateTime d) {
    return '${d.weekday}, ${d.day}/${d.month}/${d.year}';
  }

  Map<String, dynamic> _bookingData(String uid) {
    return {
      'userId': uid,
      'shopId': shopId,
      'serviceName': serviceName,
      'storeName': storeName,
      'storeAddress': storeAddress,
      'price': price,
      'pet': pet,
      'date': Timestamp.fromDate(date),
      'time': time,
      'notes': notes,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'upcoming',
    };
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final cream = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: cream,
      body: Column(
        children: [
          // ================= HEADER =================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 70, 20, 36),
            decoration: BoxDecoration(
              color: primary,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(32),
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: cream,
                  child: Icon(
                    Icons.check,
                    size: 40,
                    color: primary,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Confirm Your Booking',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: cream,
                        fontWeight: FontWeight.w800,
                        fontSize: 24,
                      ),
                ),
              ],
            ),
          ),

          // ================= CONTENT =================
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _card(
                  context,
                  title: 'Service Details',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _row(context, 'Service', serviceName),
                      _row(context, 'Location', storeName),
                      Text(
                        storeAddress,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      _row(context, 'Price', '\$$price'),
                    ],
                  ),
                ),

                _card(
                  context,
                  title: 'Pet Information',
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundImage: pet['profilePicBase64'] != null
                            ? MemoryImage(
                                base64Decode(pet['profilePicBase64']),
                              )
                            : null,
                        child: pet['profilePicBase64'] == null
                            ? const Icon(Icons.pets)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pet['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text('${pet['species']} • ${pet['breed'] ?? ''}'),
                        ],
                      ),
                    ],
                  ),
                ),

                _card(
                  context,
                  title: 'Appointment Time',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _row(context, 'Date', _formatDate(date)),
                      _row(context, 'Time', time),
                    ],
                  ),
                ),

                if (notes != null && notes!.isNotEmpty)
                  _card(
                    context,
                    title: 'Additional Notes',
                    child: Text(notes!),
                  ),
              ],
            ),
          ),

          // ================= CONFIRM BUTTON =================
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: () async {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) return;

                  final bookingId =
                      '${storeName}_${date.toIso8601String().split('T')[0]}_$time';

                  final firestore = FirebaseFirestore.instance;

                  try {
                    await firestore.runTransaction((tx) async {
                      final slotRef =
                          firestore.collection('bookings').doc(bookingId);

                      if ((await tx.get(slotRef)).exists) {
                        throw Exception('Slot already booked');
                      }

                      tx.set(slotRef, _bookingData(user.uid));

                      tx.set(
                        firestore
                            .collection('users')
                            .doc(user.uid)
                            .collection('bookings')
                            .doc(bookingId),
                        _bookingData(user.uid),
                      );

                      tx.set(
                        firestore
                            .collection('shops')
                            .doc(shopId)
                            .collection('appointments')
                            .doc(bookingId),
                        _bookingData(user.uid),
                      );
                    });

                    Navigator.popUntil(context, (route) => route.isFirst);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('This slot is already booked'),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  shape: const StadiumBorder(),
                  elevation: 4,
                ),
                child: const Text(
                  'Confirm Booking',
                 
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= HELPERS =================

  Widget _card(BuildContext context,
      {required String title, required Widget child}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

