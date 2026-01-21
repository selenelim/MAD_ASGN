// ===================== lib/BoardingScreen.dart =====================

import 'package:draft_asgn/HomeScreen.dart';
import 'package:draft_asgn/ShopServicesScreen.dart';
import 'package:draft_asgn/models/service.dart';
import 'package:draft_asgn/models/place.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'MapScreen.dart';
import 'widgets/place_card.dart';

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
  List<Place> _boardingPlaces() {
    return const [
      Place(
        name: 'Cozy Paws Boarding House',
        rating: 4.8,
        reviews: 330,
        distance: '1.1 km',
        priceFrom: 45,
        location: LatLng(1.3055, 103.8200),
      ),
      Place(
        name: 'Happy Stay Pet Hotel',
        rating: 4.7,
        reviews: 270,
        distance: '2.0 km',
        priceFrom: 60,
        location: LatLng(1.3150, 103.8400),
      ),
      Place(
        name: 'PawPal Overnight Care',
        rating: 4.9,
        reviews: 510,
        distance: '2.8 km',
        priceFrom: 90,
        location: LatLng(1.3250, 103.8600),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final places = _boardingPlaces();

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
