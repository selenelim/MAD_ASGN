import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:draft_asgn/MapScreen.dart';
import 'package:draft_asgn/ShopServicesScreen.dart';
import 'package:draft_asgn/models/service.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';              //For getting user location + permission handling
import 'package:latlong2/latlong.dart';

class VetScreen extends StatefulWidget {
  const VetScreen({super.key});

  @override
  State<VetScreen> createState() => _VetScreenState();
}

class _VetScreenState extends State<VetScreen> {
  

  Position? _userPos;

  @override
  void initState() {        ///Runs once when screen is created
    super.initState();
    _loadUserPos();         //Call it so distance can be calculated
  }
  //Get Permission + Location
  Future<void> _loadUserPos() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();    //Checks if user has location services turned on
      if (!enabled) return;                                           //If off, exit early -> distance stays unavailable

      var perm = await Geolocator.checkPermission();                  //Checks app permission
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();                  //If denied, requests permission
      }
      if (perm == LocationPermission.denied ||                        //If still denied or permanently denied, exit early
          perm == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(                //Fetches current GPS coordinates
        desiredAccuracy: LocationAccuracy.high,                       //High accuracy usually uses GPS (may take longer/more battery)
      );

      if (!mounted) return;
      setState(() => _userPos = pos);                                 //setState saves lcoation and triggers UI rebuild (distance update)
    } catch (_) {
      // ignore; show "Distance unavailable"                          //If anything fails, ignore and keep distance text as default
    }
  }
  //UI
  @override
  Widget build(BuildContext context) {
    final shopsStream = FirebaseFirestore.instance                    //Creates a live Firestore stream of shops from shops where category is "vet" and is published
        .collection('shops')
        .where('category', isEqualTo: 'vet')
        .where('isPublished', isEqualTo: true)
        .snapshots();                                                 //this means it updates in real-time

    return Scaffold(

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        centerTitle: true,
        title: Image.asset('assets/img/pawpal_logo.png', height: 65),
      ),
      body: ListView(                                                         //Scrollable list screen
        padding: const EdgeInsets.all(16),
        children: [
          _infoCard(),                                                        //Shows top info card
          const SizedBox(height: 20),
           Text(                                                              //Section header text
            'Vet services near you',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(                                       //Reactively rebuilds when new Firestore data arrives
            stream: shopsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {      //Loading State
                return const Padding(
                  padding: EdgeInsets.only(top: 30),
                  child: Center(child: CircularProgressIndicator()),          //Shows spinner while data is loading
                );
              }

              if (snapshot.hasError) {                                        //Displays Firestore error message if query fails
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {         //Empty State
                return const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text('No vet clinics yet.'),                         //No docs found -> Show message
                );
              }

              final docs = snapshot.data!.docs;                               //Store list of Firestore documents
              //Shop Card
              return Column(
                children: docs.map((doc) {                                        //Turns each Firestore doc into a _ShopCard
                  final data = doc.data() as Map<String, dynamic>;                //data is the document fields
                  final shopId = doc.id;                                          //shopId is Firestore document ID (used for navigation + service query)

                  //Reads fields and provides defaults if missing
                  final shopName = (data['name'] ?? 'Unnamed Shop').toString();
                  final address = (data['address'] ?? '').toString();
                  //Read rating fields, keep as num as Firestore may store int/double
                  final ratingAvg = (data['ratingAvg'] ?? 0) as num;
                  final ratingCount = (data['ratingCount'] ?? 0) as num;
                  //Location Field
                  GeoPoint? geo;                                              //geo only set if location exists and is Firestore GeoPoint
                  final loc = data['location'];
                  if (loc is GeoPoint) geo = loc;
                  //Maps URL
                  final mapsUrl = (data['mapsUrl'] ?? '').toString().trim();  //Optional Google Maps link stored in Firestore, trim() removes spaces

                  String distanceText = 'Distance unavailable';               //Default if user location or shop location is missing
                  if (_userPos != null && geo != null) {
                    final km = _distanceKm(
                      _userPos!.latitude,
                      _userPos!.longitude,
                      geo.latitude,
                      geo.longitude,
                    );
                    distanceText = '${km.toStringAsFixed(2)} km away';       //If have both positions, calculte km using _distanceKm and format to 2 dp
                  }

                  void goToServices() {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ShopServicesScreen(               //Pushes ShopServicesScreen and passes shop info + category
                          shopId: shopId,
                          shopName: shopName,
                          category: ServiceCategory.vet,
                        ),
                      ),
                    );
                  }

                  final canOpenMap = mapsUrl.isNotEmpty || geo != null;   //Open map if have either url/GeoPoint

                  VoidCallback? onTapDistance = canOpenMap
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MapScreen(                  //If can open, pushes MapScreen. If geo is null, fall back to Singapore Coords
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
                  //Create Card
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
                }).toList(),                //Converts it to a list of widgets
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _infoCard() {  //Shown at top
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
            'Vet',                                                                              //Title Vet
            style: Theme.of(context)
                .textTheme
                .titleLarge?.copyWith(color: Theme.of(context).scaffoldBackgroundColor), 
          ),
          SizedBox(height: 12),
          Text(
            'Vet services including consultation, vaccination, check-ups and treatment.',
             style: TextStyle(color: Theme.of(context).scaffoldBackgroundColor ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.access_time, color:Theme.of(context).scaffoldBackgroundColor, size: 18),
              SizedBox(width: 6),
              Text('30–90 mins', style: TextStyle(color: Theme.of(context).scaffoldBackgroundColor)),
              SizedBox(width: 16),
              Icon(Icons.attach_money, color: Theme.of(context).scaffoldBackgroundColor, size: 18),
              SizedBox(width: 6),
              Text('50 – 300', style: TextStyle(color: Theme.of(context).scaffoldBackgroundColor)),
            ],
          ),
        ],
      ),
    );
  }
  //Distance Calculation Helper
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

// ===================== SHOP CARD (same as others) =====================

class _ShopCard extends StatelessWidget {
  //All the data + callback passed from parent
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

  //Price Helpers
  double _parsePrice(dynamic raw) {
    if (raw is num) return raw.toDouble();                    //Firestore price might be int/double or string, this safely converts it into double
    return double.tryParse(raw?.toString() ?? '') ?? 0.0;     //If parsing fails, returns 0.0
  }

  Future<double> _getMinActiveServicePrice() async {          //Queries shops/{shopId}/services -> only active services
    final snap = await FirebaseFirestore.instance
        .collection('shops')
        .doc(shopId)
        .collection('services')
        .where('isActive', isEqualTo: true)
        .get();                                               //one time fetch (not stream)

    if (snap.docs.isEmpty) return 0.0;                        //No services -> Price 0.0

    double minPrice = double.infinity;
    for (final d in snap.docs) {                              //Loop through services, find smallest positive price
      final m = d.data();
      final p = _parsePrice(m['price']);
      if (p > 0 && p < minPrice) minPrice = p;
    }
    return minPrice == double.infinity ? 0.0 : minPrice;      //If no valid price found, return 0
  }

  @override
  Widget build(BuildContext context) {
    return Card(
       margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(                                                       //Gives tap ripple
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
              //Rating Row
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.orange, size: 18),
                  const SizedBox(width: 6),
                  Text(ratingText),
                ],
              ),
              //Address Row
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

                //Distance Row (clickable)
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
                          decoration: onTapDistance == null         //if onTapDistance is null -> no underline + tapping deos nothing
                              ? TextDecoration.none                 //If not null, tap opens map
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
                    //auto-min price 
                    FutureBuilder<double>(                                      //Runs async Firestore quert and rebuilds when done
                      future: _getMinActiveServicePrice(),
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return  Text(
                            'Loading price...',                                 //while fetching min price, show "Loading price..."
                            style: Theme.of(context)
                            .textTheme
                            .bodyMedium,
                          );
                        }
                        final priceFrom = snap.data ?? 0.0;
                        return Text(                                                  //if have valid min price > 0  -> Show "Starting from $X"
                          priceFrom > 0
                              ? 'Starting from \$${priceFrom.toStringAsFixed(0)}'
                              : 'Prices vary',                                        //Else -> "Prices vary"
                          style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                        );
                      },
                    ),

                     ElevatedButton(
                        onPressed: onTapViewServices,                     //Triggers navigation to services
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
