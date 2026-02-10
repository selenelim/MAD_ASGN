import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';      //Brings in Flutter Map, OpenStreetMap-based map widget
import 'package:latlong2/latlong.dart';             //Provides the LatLng class, used to store lat and long
import 'package:url_launcher/url_launcher.dart';    //Lets us open external apps/links -> Used here to open Google Maps direction

class MapScreen extends StatelessWidget {
  final String placeName;                           //Name of the location (shown in AppBar Title)
  final LatLng location;                            //Lat+Long of the place, Used to center the map, place the marker and use as fallback directions link

  // provider-supplied link (Google Maps share link / place link / directions link) -> From ProviderAddShopScreen
  final String? mapsUrl;

  const MapScreen({
    super.key,
    required this.placeName,                        //required -> must be passed in
    required this.location,
    this.mapsUrl,                                   //optional
  });

  Future<void> _openDirections(BuildContext context) async {          //Function that opens Google Maps, async since it waits for an external app to launch
    //Prefer provider link if available
    final url = (mapsUrl ?? '').trim();                               //If mapsUrl is null, use empty string      .trim() removes empty space

    final Uri uri;                                                    //Defines a Uri varaible
    if (url.isNotEmpty) {
      // If provider link doesn't include scheme, add https://
      if (url.startsWith('http://') || url.startsWith('https://')) {      //If URL alr has scheme -> use it as is
        uri = Uri.parse(url);
      } else {
        uri = Uri.parse('https://$url');                                  //Else if scheme missing, add https:// -> this prevents launchUrl failure
      }
    } else {
      // fallback: generate directions link from lat/lng -> Runs when no provider link exists/provided
      final lat = location.latitude;                                                          //Extracts lat and lng from LatLng respectively
      final lng = location.longitude;
      uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');        //Creates a Google Maps direction link and opens navigation directly to the location
    }

    try {
      final ok = await launchUrl(                                       //Attempts to open Maps, await pauses until launch is complete, ok is true if successful
        uri,
        mode: LaunchMode.platformDefault,
      );

      if (!ok && context.mounted) {                                     //!ok -> launch failed        context.mounted -> widget still on screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unable to open Maps")),         //Shows an error message at bottom
        );
      }
    } catch (_) {                                                       //Catches any exceptions
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unable to open Maps")),         //Same fallback message
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //AppBar
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
      //Map Body
      body: FlutterMap(                             //Displays the OpenStreetMap view
        options: MapOptions(
          initialCenter: location,                  //Centers the map on the place
          initialZoom: 16,                          //Street-level detail
        ),
        children: [
          TileLayer(                                                              //Loads OpenStreetMap tiles
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            userAgentPackageName: "com.example.draft_asgn",                       //required by OSM terms
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: location,                    //Marker placed at LatLng
                width: 60,
                height: 60,
                child: const Icon(                  //Red pin icon shown on map
                  Icons.location_pin,
                  color: Colors.red,
                  size: 45,
                ),
              ),
            ],
          ),
          RichAttributionWidget(                    //Required attribution for OpenStreetMap
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
            onPressed: () => _openDirections(context),      //Directions button -> tapping on it opens Google Maps
            icon: const Icon(Icons.directions),
            label: const Text("Get directions"),
          ),
        ),
      ),
    );
  }
}
