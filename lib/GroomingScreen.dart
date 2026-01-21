import 'package:draft_asgn/HomeScreen.dart';
import 'package:draft_asgn/ShopServicesScreen.dart';
import 'package:draft_asgn/models/service.dart';
import 'package:draft_asgn/models/place.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'MapScreen.dart';
import 'widgets/place_card.dart';

class GroomingScreen extends StatelessWidget {
  const GroomingScreen({super.key});

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
          category: ServiceCategory.grooming,
        ),
      ),
    );
  }

  void _openMap({
    required BuildContext context,
    required String placeName,
    required LatLng location,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapScreen(
          placeName: placeName,
          location: location,
        ),
      ),
    );
  }

  // ✅ Data list (easy to edit later or load from Firestore)
  List<Place> _groomingPlaces() {
    return const [
      Place(
        name: 'Paws & Claws Grooming',
        rating: 4.8,
        reviews: 342,
        distance: '0.8 km',
        priceFrom: 35,
        location: LatLng(1.3050, 103.8310),
      ),
      Place(
        name: 'The Pampered Pup',
        rating: 4.9,
        reviews: 528,
        distance: '1.2 km',
        priceFrom: 45,
        location: LatLng(1.3120, 103.8450),
      ),
      Place(
        name: 'Happy Tails Grooming',
        rating: 4.7,
        reviews: 210,
        distance: '2.0 km',
        priceFrom: 30,
        location: LatLng(1.3200, 103.8550),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final places = _groomingPlaces();

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

          // ✅ Reuse the same card UI everywhere
          ...places.map((p) {
            return PlaceCard(
              name: p.name,
              rating: p.rating,
              reviews: p.reviews,
              distance: p.distance,
              priceFrom: p.priceFrom,
              onTap: () => _openShopServices(
                context: context,
                shopName: p.name,
              ),
              onTapLocation: () => _openMap(
                context: context,
                placeName: p.name,
                location: p.location,
              ),
            );
          }).toList(),
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
