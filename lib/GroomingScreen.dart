import 'package:draft_asgn/HomeScreen.dart';
import 'package:draft_asgn/ShopServicesScreen.dart';
import 'package:draft_asgn/models/service.dart'; // contains ServiceCategory enum + Service model
import 'package:flutter/material.dart';

class GroomingScreen extends StatelessWidget {
  const GroomingScreen({super.key});

  static const Color brown = Color.fromRGBO(75, 40, 17, 1);
  static const Color lightCream = Color.fromRGBO(253, 251, 215, 1);

  // Simple helper to create a stable "id" from the shop name (until you use Firestore IDs)
  String _makeShopId(String name) {
    return name
        .toLowerCase()
        .replaceAll('&', 'and')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  void _openShopServices({
    required BuildContext context,
    required String shopName,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShopServicesScreen(
          shopId: _makeShopId(shopName),
          shopName: shopName,
          category: ServiceCategory.grooming,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        centerTitle: true,
        title: Image.asset(
          'assets/img/pawpal_logo.png',
          height: 65,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _infoCard(),
          const SizedBox(height: 20),
          const Text(
            'Grooming services near you',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          GroomingPlaceCard(
            name: 'Paws & Claws Grooming',
            rating: 4.8,
            reviews: 342,
            distance: '0.8 km',
            priceFrom: 35,
            onTap: () => _openShopServices(
              context: context,
              shopName: 'Paws & Claws Grooming',
            ),
          ),

          GroomingPlaceCard(
            name: 'The Pampered Pup',
            rating: 4.9,
            reviews: 528,
            distance: '1.2 km',
            priceFrom: 45,
            onTap: () => _openShopServices(
              context: context,
              shopName: 'The Pampered Pup',
            ),
          ),

          GroomingPlaceCard(
            name: 'Happy Tails Grooming',
            rating: 4.7,
            reviews: 210,
            distance: '2.0 km',
            priceFrom: 30,
            onTap: () => _openShopServices(
              context: context,
              shopName: 'Happy Tails Grooming',
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: brown,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Grooming',
            style: TextStyle(
              color: HomeScreen.lightCream,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Professional grooming services including bathing, haircuts, nail trimming and more.',
            style: TextStyle(color: HomeScreen.lightCream),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.access_time, color: HomeScreen.lightCream, size: 18),
              SizedBox(width: 6),
              Text('1–3 hours', style: TextStyle(color: HomeScreen.lightCream)),
              SizedBox(width: 16),
              Icon(Icons.attach_money, color: HomeScreen.lightCream, size: 18),
              SizedBox(width: 6),
              Text('30 – 150', style: TextStyle(color: HomeScreen.lightCream)),
            ],
          ),
        ],
      ),
    );
  }
}

// ===================== LOCATION CARD =====================

class GroomingPlaceCard extends StatelessWidget {
  final String name;
  final double rating;
  final int reviews;
  final String distance;
  final int priceFrom;
  final VoidCallback onTap;

  const GroomingPlaceCard({
    super.key,
    required this.name,
    required this.rating,
    required this.reviews,
    required this.distance,
    required this.priceFrom,
    required this.onTap,
  });

  static const Color brown = Color.fromRGBO(82, 45, 11, 1);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.orange, size: 18),
                    Text('$rating ($reviews)'),
                    const SizedBox(width: 12),
                    const Icon(Icons.location_on, size: 18),
                    Text(distance),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'From \$$priceFrom',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
