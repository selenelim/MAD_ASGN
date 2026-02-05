// ===================== lib/BookingScreen.dart =====================

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      // ===== APP BAR =====
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        centerTitle: true,
        title: const Text('Book Appointment'),
        leading: const BackButton(),
      ),

      // ===== BODY =====
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== SERVICE SUMMARY CARD =====
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.serviceName,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(widget.storeName),
                    Text(widget.storeAddress),
                    const SizedBox(height: 8),
                    Text(
                      "\$${widget.price}",
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                            color:
                                Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 22),

            // ===== PET SELECTION =====
            Text(
              'Which pet is this booking for?',
              style: Theme.of(context).textTheme.titleLarge,
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

      // ===== BOTTOM BUTTON =====
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
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Continue to Confirmation'),
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
      icon: const Icon(Icons.add),
      label: const Text('Add New Pet'),
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
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: img,
                child: img == null
                    ? const Icon(Icons.pets)
                    : null,
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
        final selected = slot == selectedTime;
        final isBooked = bookedSlots.contains(slot);

        return ChoiceChip(
          label: Text(slot),
          selected: selected,
          onSelected: isBooked
              ? null
              : (_) => setState(() => selectedTime = slot),
        );
      }).toList(),
    );
  }

  Widget _notesField() {
    return TextField(
      controller: notesController,
      maxLines: 3,
      decoration: const InputDecoration(
        hintText: 'Additional notes (optional)',
      ),
    );
  }

  bool _canProceed() =>
      selectedPetId != null && selectedDate != null && selectedTime != null;
}

