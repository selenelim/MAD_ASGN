import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:draft_asgn/AddPetScreen.dart';
import 'package:draft_asgn/BookingConfirmationScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:convert';


class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

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
  Map<String, dynamic> get selectedPetData {
  final petDoc = pets.firstWhere((p) => p.id == selectedPetId);
  return petDoc.data() as Map<String, dynamic>;
}


  void _goAddPet() async {
    await Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => const AddPetScreen(),
    ),
  );
  _loadPets();
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBD4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF713500),
        title: const Text('Book Appointment',style: TextStyle(
    color: Color(0xFFFDFBD4)),),
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// PET SELECTION
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
            ],
          ],
        ),
      ),

      /// BOTTOM BUTTON
      bottomNavigationBar: _canProceed()
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () { Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => BookingConfirmationScreen(
        serviceName: 'Basic Grooming',
        storeName: 'Paws & Claws Grooming Salon',
        storeAddress: '123 Main Street, Downtown',
        price: 35,
        pet: selectedPetData,
        date: selectedDate!,
        time: selectedTime!,
        notes: notesController.text,
      ),
    ),
  );
},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF713500),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: const StadiumBorder(),
                ),
                child: const Text('Continue to Confirmation',style: TextStyle(color: Color(0xFFFDFBD4)),),
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
    icon: const Icon(
      Icons.add,
      color: Color(0xFF713500), // icon color
    ),
    label: const Text(
      'Add New Pet',
      style: TextStyle(
        color: Color(0xFF713500), // text color
        fontWeight: FontWeight.bold,
      ),
    ),
    style: OutlinedButton.styleFrom(
      side: const BorderSide(
        color: Color(0xFF713500), // border color
        width: 2,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
}


  Widget _petCard(QueryDocumentSnapshot pet) {
    final data = pet.data() as Map<String, dynamic>;
    final isSelected = pet.id == selectedPetId;

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
              backgroundImage: data['profilePicBase64'] != null
                  ? MemoryImage(
                      const Base64Decoder().convert(data['profilePicBase64']))
                  : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('${data['species']} • ${data['breed'] ?? ''}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _datePicker() {
    return ListTile(
      title: Text(selectedDate == null
          ? 'Select Date'
          : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'),
      trailing: const Icon(Icons.calendar_today),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          initialDate: DateTime.now(),
        );
        if (picked != null) setState(() => selectedDate = picked);
      },
    );
  }

  Widget _timeSlots() {
    final slots = [
      '9:00 AM','10:00 AM','11:00 AM','12:00 PM',
      '1:00 PM','2:00 PM','3:00 PM','4:00 PM','5:00 PM'
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: slots.map((slot) {
        final selected = slot == selectedTime;
        return ChoiceChip(
          label: Text(slot),
          selected: selected,
          onSelected: (_) => setState(() => selectedTime = slot),
          selectedColor: const Color(0xFF713500),
          labelStyle: TextStyle(color: selected ? Colors.white : Colors.black),
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
