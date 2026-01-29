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
  });

  String _formatDate(DateTime d) {
    return '${d.weekday}, ${d.day}/${d.month}/${d.year}';
  }
  Map<String, dynamic> _bookingData(String uid) {
  return {
    'userId': uid,
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
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBD4),
      body: Column(
        children: [
          /// HEADER
          /// HEADER
Container(
  width: double.infinity, // 
  padding: const EdgeInsets.fromLTRB(20, 70, 20, 36),
  decoration: const BoxDecoration(
    color: Color(0xFF713500),
    borderRadius: BorderRadius.vertical(
      bottom: Radius.circular(32),
    ),
  ),
  child: Column(
    children: const [
      CircleAvatar(
        radius: 40, // slightly bigger icon
        backgroundColor: Color(0xFFFDFBD4),
        child: Icon(
          Icons.check,
          size: 40,
          color: Color(0xFF713500),
        ),
      ),
      SizedBox(height: 18),
      Text(
        'Confirm Your Booking',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: Color(0xFFFDFBD4),
        ),
      ),
    ],
  ),
),


          /// CONTENT
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _card(
                  title: 'Service Details',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _row('Service', serviceName),
                      _row('Location', storeName),
                      Text(storeAddress,
                          style: const TextStyle(color: Colors.grey)),
                      _row('Price', '\$$price'),
                    ],
                  ),
                ),

                _card(
                  title: 'Pet Information',
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundImage: pet['profilePicBase64'] != null
                            ? MemoryImage(
                                base64Decode(pet['profilePicBase64']))
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(pet['name'],
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          Text('${pet['species']} • ${pet['breed'] ?? ''}'),
                        ],
                      ),
                    ],
                  ),
                ),

                _card(
                  title: 'Appointment Time',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _row('Date', _formatDate(date)),
                      _row('Time', time),
                    ],
                  ),
                ),

                if (notes != null && notes!.isNotEmpty)
                  _card(
                    title: 'Additional Notes',
                    child: Text(notes!),
                  ),
              ],
            ),
          ),

          /// CONFIRM BUTTON
          Padding(
  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
  child: SizedBox(
    width: double.infinity,
    height: 58, 
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF713500),
        shape: const StadiumBorder(),
        elevation: 4,
      ),
      onPressed: () async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final bookingId =
      '${storeName}_${date.toIso8601String().split('T')[0]}_$time';

  final firestore = FirebaseFirestore.instance;

  try {
    await firestore.runTransaction((tx) async {
      final slotRef = firestore.collection('bookings').doc(bookingId);

      final slotSnap = await tx.get(slotRef);
      if (slotSnap.exists) {
        throw Exception('Slot already booked');
      }

      // Save global booking (locks the slot)
      tx.set(slotRef, _bookingData(user.uid));

      // Save under user
      tx.set(
        firestore
            .collection('users')
            .doc(user.uid)
            .collection('bookings')
            .doc(),
        _bookingData(user.uid),
      );
    });

    Navigator.popUntil(context, (route) => route.isFirst);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This slot is already booked')),
    );
  }
},

      child: const Text(
        'Confirm Booking',
        style: TextStyle(
          color: Color(0xFFFDFBD4),
          fontSize: 18, // 👈 bigger text
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  ),
),

        ],
      ),
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text('$label: $value',
          style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}
