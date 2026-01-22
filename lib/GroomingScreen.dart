import 'package:draft_asgn/HomeScreen.dart';
import 'package:draft_asgn/ShopServicesScreen.dart';
import 'package:draft_asgn/models/service.dart';
import 'package:draft_asgn/models/place.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'MapScreen.dart';
import 'widgets/place_card.dart';
import 'utils/location_helper.dart';

class GroomingScreen extends StatefulWidget {
  const GroomingScreen({super.key});

  @override
  State<GroomingScreen> createState() => _GroomingScreenState();
}

class _GroomingScreenState extends State<GroomingScreen> {
  static const Color brown = Color.fromRGBO(75, 40, 17, 1);
  static const Color lightCream = Color.fromRGBO(253, 251, 215, 1);

  LatLng? _userLocation;

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
  }

  Future<void> _loadUserLocation() async {
    final pos = await LocationHelper.getCurrentLocation();
    if (!mounted) return;

    if (pos != null) {
      setState(() {
        _userLocation = LatLng(pos.latitude, pos.longitude);
      });
    } else {
      // optional: show a small message if permission denied / location off
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text("Location not available. Distances hidden.")),
      // );
    }
  }

  String formatDistance(LatLng user, LatLng place) {
    final meters = const Distance().as(LengthUnit.Meter, user, place);

    if (meters < 1000) {
      return '${meters.round()} m';   // e.g. 320 m
    }

    final km = meters / 1000.0;       // IMPORTANT: 1000.0 (double)
    return '${km.toStringAsFixed(1)} km'; // e.g. 1.2 km
  }


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

  List<Place> _groomingPlaces() {
    return const [
      Place(
        name: 'BIG PAWS SMALL PAWS ',
        rating: 5.0,
        reviews: 186,
        distance: '',
        priceFrom: 35,
        location: LatLng(1.3148, 103.8523),
      ),
      Place(
        name: 'Bob And Lou Grooming',
        rating: 5.0,
        reviews: 31,
        distance: '',
        priceFrom: 45,
        location: LatLng(1.3850353, 103.7664437),
      ),
      Place(
        name: 'Pawpy Kisses',
        rating: 4.9,
        reviews: 681,
        distance: '',
        priceFrom: 30,
        location: LatLng(1.3215917, 103.8533154),
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

          // optional: small status text
          if (_userLocation == null)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Turn on location to see distance.',
                style: TextStyle(color: Colors.black54),
              ),
            ),

          ...places.map((p) {
            final distanceText = (_userLocation == null)
                ? '—'
                : formatDistance(_userLocation!, p.location);

            return PlaceCard(
              name: p.name,
              rating: p.rating,
              reviews: p.reviews,
              distance: distanceText,
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
