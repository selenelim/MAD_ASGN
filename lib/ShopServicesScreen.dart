// ShopServicesScreen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:draft_asgn/AddReviewScreen.dart';
import 'package:draft_asgn/BookingScreen.dart';
import 'package:draft_asgn/HomeScreen.dart';
import 'package:draft_asgn/ManageServicesScreen.dart';
import 'package:draft_asgn/models/service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

  ServiceCategory _categoryFromString(String s) {
    switch (s) {
      case 'grooming':
        return ServiceCategory.grooming;
      case 'vet':
        return ServiceCategory.vet;
      case 'training':
        return ServiceCategory.training;
      case 'boarding':
        return ServiceCategory.boarding;
      default:
        return ServiceCategory.grooming;
    }
  }

  /// ✅ SAFE price parsing (int/double/string)
  double _parsePrice(dynamic raw) {
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw?.toString() ?? '') ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final shopRef = FirebaseFirestore.instance.collection('shops').doc(shopId);

    final servicesStream = shopRef
        .collection('services')
        .where('isActive', isEqualTo: true)
        .snapshots();

    final reviewsStream = shopRef
        .collection('reviews')
        .limit(5)
        .snapshots();

    return Scaffold(
      backgroundColor: lightCream,
      appBar: AppBar(
        backgroundColor: lightCream,
        foregroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.black),
        title: Image.asset('assets/img/pawpal_logo.png', height: 65),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<DocumentSnapshot>(
          stream: shopRef.snapshots(),
          builder: (context, shopSnap) {
            if (shopSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (shopSnap.hasError) {
              return Text('Error: ${shopSnap.error}');
            }

            final shopData = (shopSnap.data?.data() as Map<String, dynamic>?) ?? {};

            // ✅ FIX owner field mismatch: support ownerUid OR ownerId
            final ownerUid =
                (shopData['ownerUid'] ?? shopData['ownerId'] ?? '').toString();

            final storeAddress = (shopData['address'] ?? '').toString();
            final ratingAvg = (shopData['ratingAvg'] ?? 0) as num;
            final ratingCount = (shopData['ratingCount'] ?? 0) as num;

            final user = FirebaseAuth.instance.currentUser;
            final isOwner = user != null && user.uid == ownerUid;

            // category from shop doc (optional), otherwise use passed in
            final shopCategoryStr = (shopData['category'] ?? '').toString();
            final effectiveCategory = shopCategoryStr.isEmpty
                ? category
                : _categoryFromString(shopCategoryStr);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShopHeaderCard(
                  shopName: shopName,
                  address: storeAddress,
                  ratingAvg: ratingAvg.toDouble(),
                  ratingCount: ratingCount.toInt(),
                ),
                const SizedBox(height: 12),

                // ✅ Owner button
                if (isOwner)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ManageServicesScreen(shopId: shopId),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Manage Services (Owner)'),
                    ),
                  ),

                const SizedBox(height: 18),
                Text(
                  _categoryTitle,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // ================= SERVICES LIST =================
                StreamBuilder<QuerySnapshot>(
                  stream: servicesStream,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return Text('Error: ${snap.error}');
                    }
                    final docs = snap.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return const Text('No services yet.');
                    }

                    return Column(
                      children: docs.map((doc) {
                        final m = doc.data() as Map<String, dynamic>;

                        final service = Service(
                          id: doc.id,
                          category: effectiveCategory,
                          name: (m['name'] ?? '').toString(),
                          description: (m['description'] ?? '').toString(),
                          durationText: (m['durationText'] ?? '').toString(),
                          price: _parsePrice(m['price']),
                        );

                        return _ServiceCard(
                          service: service,
                          onBook: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BookAppointmentScreen(
                                  serviceName: service.name,
                                  price: service.price.toInt(),
                                  storeName: shopName,
                                  storeAddress: storeAddress,
                                  shopId: shopId,
                                ),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    );
                  },
                ),

                const SizedBox(height: 22),

                // ================= REVIEWS HEADER =================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Reviews',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: HomeScreen.brown
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddReviewScreen(shopId: shopId),
                          ),
                        );
                      },
                      icon: const Icon(Icons.rate_review),
                      label: const Text('Add'),
                    ),
                  ],
                ),

                // ================= REVIEWS LIST =================
                StreamBuilder<QuerySnapshot>(
                  stream: reviewsStream,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const SizedBox.shrink();
                    }
                    if (snap.hasError) {
                      return Text('Error: ${snap.error}');
                    }
                    final docs = snap.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return const Text('No reviews yet.');
                    }

                    return Column(
                      children: docs.map((d) {
                        final m = d.data() as Map<String, dynamic>;
                        final r = (m['rating'] ?? 0) as num;
                        final c = (m['comment'] ?? '').toString();

                        return Card(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.person),
                            title: Row(
                              children: [
                                Text('${r.toInt()}/5'),
                                const SizedBox(width: 6),
                                ...List.generate(
                                  5,
                                  (i) => Icon(
                                    i < r.toInt() ? Icons.star : Icons.star_border,
                                    size: 16,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Text(c.isEmpty ? 'No comment' : c),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ShopHeaderCard extends StatelessWidget {
  final String shopName;
  final String address;
  final double ratingAvg;
  final int ratingCount;

  const _ShopHeaderCard({
    required this.shopName,
    required this.address,
    required this.ratingAvg,
    required this.ratingCount,
  });

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shopName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (address.isNotEmpty)
                  Text(address, style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 6),
                Text(
                  ratingCount == 0
                      ? 'No ratings yet'
                      : '⭐ ${ratingAvg.toStringAsFixed(1)} ($ratingCount)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
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
          ),
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
