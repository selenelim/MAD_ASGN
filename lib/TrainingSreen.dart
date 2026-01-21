// ===================== lib/TrainingScreen.dart =====================

import 'package:draft_asgn/HomeScreen.dart';
import 'package:draft_asgn/ShopServicesScreen.dart';
import 'package:draft_asgn/models/service.dart';
import 'package:draft_asgn/models/place.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'MapScreen.dart';
import 'widgets/place_card.dart';

class TrainingScreen extends StatelessWidget {
  const TrainingScreen({super.key});

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
          category: ServiceCategory.training,
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

  // ✅ Data list
  List<Place> _trainingPlaces() {
    return const [
      Place(
        name: 'Pawfect Obedience School',
        rating: 4.8,
        reviews: 280,
        distance: '1.0 km',
        priceFrom: 50,
        location: LatLng(1.3060, 103.8250),
      ),
      Place(
        name: 'Good Dog Training Hub',
        rating: 4.7,
        reviews: 190,
        distance: '1.8 km',
        priceFrom: 60,
        location: LatLng(1.3150, 103.8450),
      ),
      Place(
        name: 'Calm Tails Training',
        rating: 4.9,
        reviews: 420,
        distance: '2.6 km',
        priceFrom: 70,
        location: LatLng(1.3280, 103.8600),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final places = _trainingPlaces();

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
            'Training services near you',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // ✅ Reuse PlaceCard
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
            'Training',
            style: TextStyle(
              color: HomeScreen.lightCream,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Book obedience classes and behaviour training sessions.',
            style: TextStyle(color: HomeScreen.lightCream),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.access_time, color: HomeScreen.lightCream, size: 18),
              SizedBox(width: 6),
              Text('1 hour', style: TextStyle(color: HomeScreen.lightCream)),
              SizedBox(width: 16),
              Icon(Icons.attach_money, color: HomeScreen.lightCream, size: 18),
              SizedBox(width: 6),
              Text('50 – 200', style: TextStyle(color: HomeScreen.lightCream)),
            ],
          ),
        ],
      ),
    );
  }
}
