import 'package:draft_asgn/HomeScreen.dart';
import 'package:draft_asgn/ShopServicesScreen.dart';
import 'package:draft_asgn/models/service.dart';
import 'package:draft_asgn/models/place.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'MapScreen.dart';
import 'widgets/place_card.dart';
import 'utils/location_helper.dart';

class TrainingScreen extends StatefulWidget {
  const TrainingScreen({super.key});

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
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

  List<Place> _trainingPlaces() {
    return const [
      Place(
        name: 'Happy-Dog Training',
        rating: 4.0,
        reviews: 39,
        distance: '',
        priceFrom: 50,
        location: LatLng(1.3267031, 103.8458437),
      ),
      Place(
        name: 'PUPS Dog Training',
        rating: 5.0,
        reviews: 126,
        distance: '',
        priceFrom: 60,
        location: LatLng(1.4403361, 103.8306340),
      ),
      Place(
        name: 'Smartdoggy Academy',
        rating: 4.8,
        reviews: 20,
        distance: '',
        priceFrom: 70,
        location: LatLng(1.3525353, 103.7069918),
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
              onTap: () => _openShopServices(context: context, shopName: p.name),
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
