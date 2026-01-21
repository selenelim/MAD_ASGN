// ===================== lib/BoardingScreen.dart =====================

import 'package:draft_asgn/HomeScreen.dart';
import 'package:draft_asgn/ShopServicesScreen.dart';
import 'package:draft_asgn/models/service.dart';
import 'package:flutter/material.dart';

class BoardingScreen extends StatelessWidget {
  const BoardingScreen({super.key});

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
          category: ServiceCategory.boarding,
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
            'Boarding services near you',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          _PlaceCard(
            name: 'Cozy Paws Boarding House',
            rating: 4.8,
            reviews: 330,
            distance: '1.1 km',
            priceFrom: 45,
            onTap: () => _openShopServices(
              context: context,
              shopName: 'Cozy Paws Boarding House',
            ),
          ),
          _PlaceCard(
            name: 'Happy Stay Pet Hotel',
            rating: 4.7,
            reviews: 270,
            distance: '2.0 km',
            priceFrom: 60,
            onTap: () => _openShopServices(
              context: context,
              shopName: 'Happy Stay Pet Hotel',
            ),
          ),
          _PlaceCard(
            name: 'PawPal Overnight Care',
            rating: 4.9,
            reviews: 510,
            distance: '2.8 km',
            priceFrom: 90,
            onTap: () => _openShopServices(
              context: context,
              shopName: 'PawPal Overnight Care',
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
            'Boarding',
            style: TextStyle(
              color: HomeScreen.lightCream,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Book day care or overnight stays with trusted providers.',
            style: TextStyle(color: HomeScreen.lightCream),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.access_time, color: HomeScreen.lightCream, size: 18),
              SizedBox(width: 6),
              Text('8–24 hours', style: TextStyle(color: HomeScreen.lightCream)),
              SizedBox(width: 16),
              Icon(Icons.attach_money, color: HomeScreen.lightCream, size: 18),
              SizedBox(width: 6),
              Text('45 – 300', style: TextStyle(color: HomeScreen.lightCream)),
            ],
          ),
        ],
      ),
    );
  }
}

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
