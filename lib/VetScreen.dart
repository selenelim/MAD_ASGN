// ===================== lib/VetScreen.dart =====================

import 'package:draft_asgn/HomeScreen.dart';
import 'package:draft_asgn/ShopServicesScreen.dart';
import 'package:draft_asgn/models/service.dart';
import 'package:flutter/material.dart';

class VetScreen extends StatelessWidget {
  const VetScreen({super.key});

  static const Color brown = Color.fromRGBO(75, 40, 17, 1);
  static const Color lightCream = Color.fromRGBO(253, 251, 215, 1);

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
          category: ServiceCategory.vet,
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
            'Vet services near you',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          _PlaceCard(
            name: 'Downtown Animal Clinic',
            rating: 4.8,
            reviews: 410,
            distance: '0.9 km',
            priceFrom: 40,
            onTap: () => _openShopServices(
              context: context,
              shopName: 'Downtown Animal Clinic',
            ),
          ),
          _PlaceCard(
            name: 'Happy Paws Vet Centre',
            rating: 4.7,
            reviews: 305,
            distance: '1.6 km',
            priceFrom: 35,
            onTap: () => _openShopServices(
              context: context,
              shopName: 'Happy Paws Vet Centre',
            ),
          ),
          _PlaceCard(
            name: 'CarePlus Veterinary',
            rating: 4.9,
            reviews: 620,
            distance: '2.1 km',
            priceFrom: 50,
            onTap: () => _openShopServices(
              context: context,
              shopName: 'CarePlus Veterinary',
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
            'Vet',
            style: TextStyle(
              color: HomeScreen.lightCream,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Book consultations, vaccinations, and check-ups for your pet.',
            style: TextStyle(color: HomeScreen.lightCream),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.access_time, color: HomeScreen.lightCream, size: 18),
              SizedBox(width: 6),
              Text('30–60 mins', style: TextStyle(color: HomeScreen.lightCream)),
              SizedBox(width: 16),
              Icon(Icons.attach_money, color: HomeScreen.lightCream, size: 18),
              SizedBox(width: 6),
              Text('35 – 200', style: TextStyle(color: HomeScreen.lightCream)),
            ],
          ),
        ],
      ),
    );
  }
}

// Reusable card (same style)
class _PlaceCard extends StatelessWidget {
  final String name;
  final double rating;
  final int reviews;
  final String distance;
  final int priceFrom;
  final VoidCallback onTap;

  const _PlaceCard({
    required this.name,
    required this.rating,
    required this.reviews,
    required this.distance,
    required this.priceFrom,
    required this.onTap,
  });

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
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
