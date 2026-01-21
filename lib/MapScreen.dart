import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class MapScreen extends StatelessWidget {
  final String placeName;
  final LatLng location;

  const MapScreen({
    super.key,
    required this.placeName,
    required this.location,
  });

  Future<void> _openDirections(BuildContext context) async {
    final lat = location.latitude;
    final lng = location.longitude;

    // Directions link (works even if Google Maps app is not installed)
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );

    try {
      final ok = await launchUrl(
        uri,
        mode: LaunchMode.platformDefault, // IMPORTANT
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
            // CHANGE this to your actual package name (AndroidManifest.xml)
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

      // Big button at bottom for better UX
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
