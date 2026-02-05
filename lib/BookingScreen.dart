// ===================== lib/BookingScreen.dart =====================
// Your booking page, updated to accept service + store details from ShopServicesScreen,
// and pass those into BookingConfirmationScreen instead of hardcoding.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:draft_asgn/AddPetScreen.dart';
import 'package:draft_asgn/BookingConfirmationScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

Set<String> bookedSlots = {};

class BookAppointmentScreen extends StatefulWidget {
  final String serviceName;
  final int price;
  final String storeName;
  final String storeAddress;
  final String shopId;


  const BookAppointmentScreen({
    super.key,
    required this.serviceName,
    required this.price,
    required this.storeName,
    required this.storeAddress,
    required this.shopId,
  });

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}


class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  String? selectedPetId;
  String? selectedTime;
  DateTime? selectedDate;
  final notesController = TextEditingController();

  List<QueryDocumentSnapshot> pets = [];

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  Future<void> _loadPets() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('pets')
        .get();

    if (!mounted) return;
    setState(() => pets = snapshot.docs);
  }
  Future<void> _loadBookedSlots() async {
  if (selectedDate == null) return;

  final dateKey = selectedDate!.toIso8601String().split('T')[0];

  final snapshot = await FirebaseFirestore.instance
      .collection('bookings')
      .where('storeName', isEqualTo: widget.storeName)
      .get();

  setState(() {
    bookedSlots = snapshot.docs
        .where((d) =>
            (d['date'] as Timestamp)
                .toDate()
                .toIso8601String()
                .startsWith(dateKey))
        .map((d) => d['time'] as String)
        .toSet();
  });
}


  Map<String, dynamic> get selectedPetData {
    final petDoc = pets.firstWhere((p) => p.id == selectedPetId);
    return petDoc.data() as Map<String, dynamic>;
  }

  void _goAddPet() async {
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AddPetScreen()),
    );
    _loadPets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBD4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF713500),
        title: const Text(
          'Book Appointment',
          style: TextStyle(color: Color(0xFFFDFBD4)),
        ),
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Optional: show what they are booking
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.serviceName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(widget.storeName, style: const TextStyle(color: Colors.black54)),
                  Text(widget.storeAddress, style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 8),
                  Text(
                    "\$${widget.price}",
                    style: const TextStyle(
                      color: Color(0xFF713500),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // PET SELECTION
            const Text(
              'Which pet is this booking for?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (pets.isEmpty)
              _emptyPetState()
            else
              Column(
                children: [
                  ...pets.map((pet) => _petCard(pet)),
                  const SizedBox(height: 8),
                  _addPetButton(),
                ],
              ),

            if (selectedPetId != null) ...[
              const SizedBox(height: 24),
              _datePicker(),
              const SizedBox(height: 24),
              _timeSlots(),
              const SizedBox(height: 24),
              _notesField(),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),

      // BOTTOM BUTTON
      bottomNavigationBar: _canProceed()
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookingConfirmationScreen(
                        serviceName: widget.serviceName,
                        storeName: widget.storeName,
                        storeAddress: widget.storeAddress,
                        price: widget.price,
                        pet: selectedPetData,
                        date: selectedDate!,
                        time: selectedTime!,
                        notes: notesController.text,
                        shopId: widget.shopId,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF713500),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: const StadiumBorder(),
                ),
                child: const Text(
                  'Continue to Confirmation',
                  style: TextStyle(color: Color(0xFFFDFBD4)),
                ),
              ),
            )
          : null,
    );
  }

  // ---------------- Widgets ----------------

  Widget _emptyPetState() {
    return Column(
      children: [
        const SizedBox(height: 20),
        _addPetButton(),
      ],
    );
  }

  Widget _addPetButton() {
    return OutlinedButton.icon(
      onPressed: _goAddPet,
      icon: const Icon(Icons.add, color: Color(0xFF713500)),
      label: const Text(
        'Add New Pet',
        style: TextStyle(
          color: Color(0xFF713500),
          fontWeight: FontWeight.bold,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFF713500), width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _petCard(QueryDocumentSnapshot pet) {
    final data = pet.data() as Map<String, dynamic>;
    final isSelected = pet.id == selectedPetId;

    ImageProvider? img;
    if (data['profilePicBase64'] != null) {
      try {
        img = MemoryImage(const Base64Decoder().convert(data['profilePicBase64']));
      } catch (_) {
        img = null;
      }
    }

    return GestureDetector(
      onTap: () => setState(() => selectedPetId = pet.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF713500) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage: img,
              backgroundColor: Colors.grey[300],
              child: img == null ? const Icon(Icons.pets, color: Colors.white) : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['name'] ?? 'Unnamed',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('${data['species'] ?? ''} • ${data['breed'] ?? ''}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _datePicker() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        selectedDate == null
            ? 'Select Date'
            : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
      ),
      trailing: const Icon(Icons.calendar_today),
      onTap: () async {
  final picked = await showDatePicker(
    context: context,
    firstDate: DateTime.now(),
    lastDate: DateTime.now().add(const Duration(days: 365)),
    initialDate: selectedDate ?? DateTime.now(),
  );

  if (picked != null) {
    setState(() => selectedDate = picked);
    await _loadBookedSlots();
  }
},

    );
  }

  Widget _timeSlots() {
  final slots = [
    '9:00 AM',
    '10:00 AM',
    '11:00 AM',
    '12:00 PM',
    '1:00 PM',
    '2:00 PM',
    '3:00 PM',
    '4:00 PM',
    '5:00 PM'
  ];

  return Wrap(
    spacing: 8,
    runSpacing: 8,
    children: slots.map((slot) {
      final selected = slot == selectedTime; // 👈 THIS LINE
      final isBooked = bookedSlots.contains(slot);

      return ChoiceChip(
        label: Text(slot),
        selected: selected,
        onSelected: isBooked
            ? null
            : (_) => setState(() => selectedTime = slot),
        selectedColor: const Color(0xFF713500),
        disabledColor: Colors.grey[300],
        labelStyle: TextStyle(
          color: isBooked
              ? Colors.grey
              : selected
                  ? Colors.white
                  : Colors.black,
        ),
      );
    }).toList(),
  );
}


  Widget _notesField() {
    return TextField(
      controller: notesController,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: 'Additional notes (optional)',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  bool _canProceed() =>
      selectedPetId != null && selectedDate != null && selectedTime != null;
}
