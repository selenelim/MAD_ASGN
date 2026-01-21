// ===================== lib/ShopServicesScreen.dart =====================
// Shows the "Services Offered" list (like your screenshot) after user selects a shop,
// then navigates to BookAppointmentScreen (in BookingScreen.dart) when user taps "Book Now".

import 'package:draft_asgn/BookingScreen.dart'; // contains BookAppointmentScreen
import 'package:flutter/material.dart';
import 'package:draft_asgn/models/service.dart'; // Service + ServiceCategory

class ShopServicesScreen extends StatelessWidget {
  final String shopId;
  final String shopName;
  final ServiceCategory category;

  const ShopServicesScreen({
    super.key,
    required this.shopId,
    required this.shopName,
    required this.category,
  });

  static const Color brown = Color.fromRGBO(82, 45, 11, 1);
  static const Color lightCream = Color.fromRGBO(253, 251, 215, 1);

  // TEMP: Replace with Firestore later (per shop)
  List<Service> get _allServices => const [
        // Grooming
        Service(
          id: "basic_groom",
          category: ServiceCategory.grooming,
          name: "Basic Grooming",
          description: "Bath, brush, nail trim, and ear cleaning",
          durationText: "1–1.5 hours",
          price: 35,
        ),
        Service(
          id: "full_groom",
          category: ServiceCategory.grooming,
          name: "Full Grooming",
          description: "Complete grooming package with haircut and styling",
          durationText: "2–2.5 hours",
          price: 65,
        ),
        Service(
          id: "spa_groom",
          category: ServiceCategory.grooming,
          name: "Spa Package",
          description: "Premium grooming with massage and aromatherapy",
          durationText: "3 hours",
          price: 95,
        ),

        // Vet
        Service(
          id: "vet_consult",
          category: ServiceCategory.vet,
          name: "Vet Consultation",
          description: "General health check and consultation",
          durationText: "30–45 mins",
          price: 40,
        ),
        Service(
          id: "vaccination",
          category: ServiceCategory.vet,
          name: "Vaccination",
          description: "Routine vaccination session",
          durationText: "20–30 mins",
          price: 60,
        ),

        // Training
        Service(
          id: "basic_training",
          category: ServiceCategory.training,
          name: "Basic Obedience Training",
          description: "Sit, stay, recall foundations",
          durationText: "1 hour",
          price: 50,
        ),
        Service(
          id: "behaviour_training",
          category: ServiceCategory.training,
          name: "Behaviour Training",
          description: "Address barking, reactivity, and leash pulling",
          durationText: "1 hour",
          price: 70,
        ),

        // Boarding
        Service(
          id: "day_boarding",
          category: ServiceCategory.boarding,
          name: "Day Boarding",
          description: "Supervised stay + feeding",
          durationText: "8 hours",
          price: 45,
        ),
        Service(
          id: "overnight_boarding",
          category: ServiceCategory.boarding,
          name: "Overnight Boarding",
          description: "Overnight stay with care and feeding",
          durationText: "24 hours",
          price: 90,
        ),
      ];

  String get _categoryTitle {
    switch (category) {
      case ServiceCategory.grooming:
        return "Grooming Services";
      case ServiceCategory.vet:
        return "Vet Services";
      case ServiceCategory.training:
        return "Training Services";
      case ServiceCategory.boarding:
        return "Boarding Services";
    }
  }

  // TEMP: You can pass real address from Firestore later
  String get _storeAddress => "123 Main Street, Downtown";

  @override
  Widget build(BuildContext context) {
    final services = _allServices.where((s) => s.category == category).toList();

    return Scaffold(
      backgroundColor: lightCream,
      appBar: AppBar(
        backgroundColor: brown,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(shopName),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ShopHeaderCard(shopName: shopName, shopId: shopId),
            const SizedBox(height: 18),
            Text(
              _categoryTitle,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...services.map(
              (s) => _ServiceCard(
                service: s,
                onBook: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookAppointmentScreen(
                        serviceName: s.name,
                        price: s.price.toInt(),
                        storeName: shopName,
                        storeAddress: _storeAddress,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopHeaderCard extends StatelessWidget {
  final String shopName;
  final String shopId;

  const _ShopHeaderCard({required this.shopName, required this.shopId});

  static const Color brown = Color.fromRGBO(82, 45, 11, 1);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: brown.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.store, color: brown),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              shopName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final Service service;
  final VoidCallback onBook;

  const _ServiceCard({required this.service, required this.onBook});

  static const Color brown = Color.fromRGBO(82, 45, 11, 1);

  @override
  Widget build(BuildContext context) {
    return Container(
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
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            service.name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(service.description, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.schedule, size: 18, color: Colors.black54),
              const SizedBox(width: 6),
              Text(service.durationText, style: const TextStyle(color: Colors.black54)),
              const Spacer(),
              Text(
                "\$${service.price.toStringAsFixed(0)}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: brown,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onBook,
              style: ElevatedButton.styleFrom(
                backgroundColor: brown,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
              child: const Text(
                "Book Now",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
