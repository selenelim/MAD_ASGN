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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
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
            if (!shopSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final shopData =
                (shopSnap.data!.data() as Map<String, dynamic>?) ?? {};

            final ownerUid =
                (shopData['ownerUid'] ?? shopData['ownerId'] ?? '').toString();

            final storeAddress = (shopData['address'] ?? '').toString();
            final ratingAvg = (shopData['ratingAvg'] ?? 0) as num;
            final ratingCount = (shopData['ratingCount'] ?? 0) as num;

            final user = FirebaseAuth.instance.currentUser;
            final isOwner = user != null && user.uid == ownerUid;

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

                if (isOwner)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ManageServicesScreen(shopId: shopId),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Manage Services (Owner)'),
                    ),
                  ),

                const SizedBox(height: 18),
                Text(_categoryTitle,
                    style: Theme.of(context).textTheme.titleLarge),

                const SizedBox(height: 12),

                // ================= SERVICES =================
                StreamBuilder<QuerySnapshot>(
                  stream: servicesStream,
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const CircularProgressIndicator();
                    }

                    final docs = snap.data!.docs;
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
                          description:
                              (m['description'] ?? '').toString(),
                          durationText:
                              (m['durationText'] ?? '').toString(),
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
                    Text('Reviews',
                        style: Theme.of(context).textTheme.titleLarge),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                AddReviewScreen(shopId: shopId),
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
                    if (!snap.hasData || snap.data!.docs.isEmpty) {
                      return const Text('No reviews yet.');
                    }

                    return Column(
                      children: snap.data!.docs.map((d) {
                        final m = d.data() as Map<String, dynamic>;
                        final rating = (m['rating'] ?? 0) as int;
                        final comment =
                            (m['comment'] ?? '').toString();

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: const Icon(Icons.person),
                            title: Row(
                              children: [
                                Text(
                                  "$rating/5",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ...List.generate(
                                  5,
                                  (i) => Icon(
                                    i < rating
                                        ? Icons.star
                                        : Icons.star_border,
                                    size: 18,
                                    color: Colors.orange, // ✅ FIX
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Text(
                              comment.isEmpty
                                  ? 'No comment'
                                  : comment,
                            ),
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

// ================= HEADER CARD =================
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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).appBarTheme.backgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              shopName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color:
                        Theme.of(context).scaffoldBackgroundColor,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              address,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color:
                        Theme.of(context).scaffoldBackgroundColor,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.star,
                    color: Colors.orange, size: 18),
                const SizedBox(width: 6),
                Text(
                  ratingCount == 0
                      ? 'No ratings'
                      : '${ratingAvg.toStringAsFixed(1)} ($ratingCount)',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(
                        color: Theme.of(context)
                            .scaffoldBackgroundColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ================= SERVICE CARD =================
class _ServiceCard extends StatelessWidget {
  final Service service;
  final VoidCallback onBook;

  const _ServiceCard({required this.service, required this.onBook});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(service.name,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 6),
            Text(service.description),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.schedule, size: 18),
                const SizedBox(width: 6),
                Text(service.durationText),
                const Spacer(),
                Text(
                  "\$${service.price.toStringAsFixed(0)}",
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: onBook,
                child: const Text("Book Now"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
