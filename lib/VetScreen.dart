import 'package:draft_asgn/HomeScreen.dart';
import 'package:draft_asgn/ShopServicesScreen.dart';
import 'package:draft_asgn/models/service.dart';
import 'package:draft_asgn/models/place.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'MapScreen.dart';
import 'widgets/place_card.dart';

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

  // Data list (easy to reuse for other screens too)
  List<Place> _vetPlaces() {
    return const [
      Place(
        name: 'Downtown Animal Clinic',
        rating: 4.8,
        reviews: 410,
        distance: '0.9 km',
        priceFrom: 40,
        location: LatLng(1.3000, 103.8000),
      ),
      Place(
        name: 'Happy Paws Vet Centre',
        rating: 4.7,
        reviews: 305,
        distance: '1.6 km',
        priceFrom: 35,
        location: LatLng(1.3080, 103.8270),
      ),
      Place(
        name: 'CarePlus Veterinary',
        rating: 4.9,
        reviews: 620,
        distance: '2.1 km',
        priceFrom: 50,
        location: LatLng(1.3200, 103.8500),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final places = _vetPlaces();

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

          // Render reusable cards from data
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
