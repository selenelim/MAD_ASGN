import 'package:latlong2/latlong.dart';

class Place {
  final String name;
  final double rating;
  final int reviews;
  final String distance;
  final int priceFrom;
  final LatLng location;

  const Place({
    required this.name,
    required this.rating,
    required this.reviews,
    required this.distance,
    required this.priceFrom,
    required this.location,
  });
}
