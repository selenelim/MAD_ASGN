import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class MapScreen extends StatelessWidget {
  final String placeName;
  final LatLng location;

  // ✅ provider-supplied link (Google Maps share link / place link / directions link)
  final String? mapsUrl;

  const MapScreen({
    super.key,
    required this.placeName,
    required this.location,
    this.mapsUrl,
  });

  Future<void> _openDirections(BuildContext context) async {
    // ✅ Prefer provider link if available
    final url = (mapsUrl ?? '').trim();

    final Uri uri;
    if (url.isNotEmpty) {
      // If provider link doesn't include scheme, add https://
      if (url.startsWith('http://') || url.startsWith('https://')) {
        uri = Uri.parse(url);
      } else {
        uri = Uri.parse('https://$url');
      }
    } else {
      // fallback: generate directions link from lat/lng
      final lat = location.latitude;
      final lng = location.longitude;
      uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    }

    try {
      final ok = await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
      );

      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unable to open Maps")),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unable to open Maps")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(placeName),
        actions: [
          IconButton(
            tooltip: "Get directions",
            icon: const Icon(Icons.directions),
            onPressed: () => _openDirections(context),
          ),
        ],
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: location,
          initialZoom: 16,
        ),
        children: [
          TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            userAgentPackageName: "com.example.draft_asgn",
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: location,
                width: 60,
                height: 60,
                child: const Icon(
                  Icons.location_pin,
                  color: Colors.red,
                  size: 45,
                ),
              ),
            ],
          ),
          RichAttributionWidget(
            attributions: [
              TextSourceAttribution('© OpenStreetMap contributors'),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: ElevatedButton.icon(
            onPressed: () => _openDirections(context),
            icon: const Icon(Icons.directions),
            label: const Text("Get directions"),
          ),
        ),
      ),
    );
  }
}
