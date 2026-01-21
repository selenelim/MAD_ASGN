import 'package:flutter/material.dart';

class PlaceCard extends StatelessWidget {
  final String name;
  final double rating;
  final int reviews;
  final String distance;
  final int priceFrom;

  final VoidCallback onTap;         // open service page
  final VoidCallback onTapLocation; // open map page

  const PlaceCard({
    super.key,
    required this.name,
    required this.rating,
    required this.reviews,
    required this.distance,
    required this.priceFrom,
    required this.onTap,
    required this.onTapLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.orange, size: 18),
                    Text('$rating ($reviews)'),
                    const SizedBox(width: 12),

                    // Only location opens map
                    InkWell(
                      onTap: onTapLocation,
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, size: 18),
                          Text(
                            distance,
                            style: const TextStyle(
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'From \$$priceFrom',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
