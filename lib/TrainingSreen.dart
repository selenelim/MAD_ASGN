import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:draft_asgn/HomeScreen.dart';
import 'package:draft_asgn/MapScreen.dart';
import 'package:draft_asgn/ShopServicesScreen.dart';
import 'package:draft_asgn/models/service.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class TrainingScreen extends StatefulWidget {
  const TrainingScreen({super.key});

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  

  Position? _userPos;

  @override
  void initState() {
    super.initState();
    _loadUserPos();
  }

  Future<void> _loadUserPos() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return;

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;
      setState(() => _userPos = pos);
    } catch (_) {
      // ignore; show "Distance unavailable"
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopsStream = FirebaseFirestore.instance
        .collection('shops')
        .where('category', isEqualTo: 'training')
        .where('isPublished', isEqualTo: true)
        .snapshots();

    return Scaffold(
     
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        centerTitle: true,
        title: Image.asset('assets/img/pawpal_logo.png', height: 65),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _infoCard(),
          const SizedBox(height: 20),
           Text(
            'Training services near you',
             style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: shopsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.only(top: 30),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text('No trainers yet.'),
                );
              }

              final docs = snapshot.data!.docs;

              return Column(
                children: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final shopId = doc.id;

                  final shopName = (data['name'] ?? 'Unnamed Shop').toString();
                  final address = (data['address'] ?? '').toString();

                  final ratingAvg = (data['ratingAvg'] ?? 0) as num;
                  final ratingCount = (data['ratingCount'] ?? 0) as num;

                  GeoPoint? geo;
                  final loc = data['location'];
                  if (loc is GeoPoint) geo = loc;

                  final mapsUrl = (data['mapsUrl'] ?? '').toString().trim();

                  String distanceText = 'Distance unavailable';
                  if (_userPos != null && geo != null) {
                    final km = _distanceKm(
                      _userPos!.latitude,
                      _userPos!.longitude,
                      geo.latitude,
                      geo.longitude,
                    );
                    distanceText = '${km.toStringAsFixed(2)} km away';
                  }

                  void goToServices() {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ShopServicesScreen(
                          shopId: shopId,
                          shopName: shopName,
                          category: ServiceCategory.training,
                        ),
                      ),
                    );
                  }

                  final canOpenMap = mapsUrl.isNotEmpty || geo != null;

                  VoidCallback? onTapDistance = canOpenMap
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MapScreen(
                                placeName: shopName,
                                location: LatLng(
                                  geo?.latitude ?? 1.3521,
                                  geo?.longitude ?? 103.8198,
                                ),
                                mapsUrl: mapsUrl,
                              ),
                            ),
                          );
                        }
                      : null;

                  return _ShopCard(
                    shopId: shopId,
                    name: shopName,
                    ratingText: ratingCount.toInt() == 0
                        ? 'No ratings'
                        : '${ratingAvg.toDouble().toStringAsFixed(1)} (${ratingCount.toInt()})',
                    address: address,
                    distanceText: distanceText,
                    onTapCard: goToServices,
                    onTapViewServices: goToServices,
                    onTapDistance: onTapDistance,
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _infoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).appBarTheme.backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child:  Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Training',
            style: Theme.of(context)
                .textTheme
                .titleLarge?.copyWith(color: Theme.of(context).scaffoldBackgroundColor), 
          ),
          SizedBox(height: 12),
          Text(
            'Training services including obedience, behavior, and socialisation sessions.',
            style: TextStyle(color:Theme.of(context).scaffoldBackgroundColor),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.access_time, color:Theme.of(context).scaffoldBackgroundColor, size: 18),
              SizedBox(width: 6),
              Text('45–120 mins', style: TextStyle(color:Theme.of(context).scaffoldBackgroundColor)),
              SizedBox(width: 16),
              Icon(Icons.attach_money, color:Theme.of(context).scaffoldBackgroundColor, size: 18),
              SizedBox(width: 6),
              Text('60 – 250', style: TextStyle(color:Theme.of(context).scaffoldBackgroundColor)),
            ],
          ),
        ],
      ),
    );
  }

  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double deg) => deg * (pi / 180.0);
}

// ===================== SHOP CARD =====================

class _ShopCard extends StatelessWidget {
  final String shopId;
  final String name;
  final String ratingText;
  final String address;
  final String distanceText;

  final VoidCallback onTapCard;
  final VoidCallback onTapViewServices;
  final VoidCallback? onTapDistance;

  const _ShopCard({
    required this.shopId,
    required this.name,
    required this.ratingText,
    required this.address,
    required this.distanceText,
    required this.onTapCard,
    required this.onTapViewServices,
    required this.onTapDistance,
  });

  static const Color brown = Color.fromRGBO(82, 45, 11, 1);

  double _parsePrice(dynamic raw) {
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw?.toString() ?? '') ?? 0.0;
  }

  Future<double> _getMinActiveServicePrice() async {
    final snap = await FirebaseFirestore.instance
        .collection('shops')
        .doc(shopId)
        .collection('services')
        .where('isActive', isEqualTo: true)
        .get();

    if (snap.docs.isEmpty) return 0.0;

    double minPrice = double.infinity;
    for (final d in snap.docs) {
      final m = d.data();
      final p = _parsePrice(m['price']);
      if (p > 0 && p < minPrice) minPrice = p;
    }
    return minPrice == double.infinity ? 0.0 : minPrice;
  }

  @override
   Widget build(BuildContext context) {
    return Card(
       margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTapCard,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.orange, size: 18),
                  const SizedBox(width: 6),
                  Text(ratingText),
                ],
              ),
              if (address.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
                const SizedBox(height: 8),

                // Clickable distance / directions entry
                Row(
                  children: [
                    const Icon(Icons.directions_walk, size: 18),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: onTapDistance,
                      child: Text(
                        distanceText,
                        style: TextStyle(
                          
                          fontWeight: FontWeight.w700,
                          decoration: onTapDistance == null
                              ? TextDecoration.none
                              : TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // ✅ auto-min price (no more shop.priceFrom)
                    FutureBuilder<double>(
                      future: _getMinActiveServicePrice(),
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return  Text(
                            'Loading price...',
                            style: Theme.of(context)
                .textTheme
                .bodyMedium,
                          );
                        }
                        final priceFrom = snap.data ?? 0.0;
                        return Text(
                          priceFrom > 0
                              ? 'Starting from \$${priceFrom.toStringAsFixed(0)}'
                              : 'Prices vary',
                          style: Theme.of(context)
              .textTheme
              .bodyMedium
                        );
                      },
                    ),

                     ElevatedButton(
      onPressed: onTapViewServices,
      child: const Text(
        'View Services',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
  ],
),
                  ],
                ),
        ),
      ),
            
            );
  
  }
}
