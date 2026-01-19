import 'package:draft_asgn/HomeScreen.dart';
import 'package:flutter/material.dart';

class BoardingScreen extends StatelessWidget {
  const BoardingScreen({super.key});

  static const Color brown = Color.fromRGBO(75, 40, 17, 1);
  static const Color lightCream = Color.fromRGBO(253, 251, 215, 1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        centerTitle: true,
        title: Image.asset(
          'assets/img/pawpal_logo.png',
          height: 250,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _infoCard(),
          const SizedBox(height: 20),

          const Text(
            'Boarding services near you',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          BoardingPlaceCard(
            name: 'The Bark & Stay Lodge',
            rating: 4.8,
            reviews: 342,
            distance: '0.8 km',
            priceFrom: 35,
            onTap: () {
              // TODO: navigate to BookingPage
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Open booking page')),
              );
            },
          ),

          BoardingPlaceCard(
            name: 'SnugglePaws Pet Resort',
            rating: 4.9,
            reviews: 528,
            distance: '1.2 km',
            priceFrom: 45,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Open booking page')),
              );
            },
          ),

          BoardingPlaceCard(
            name: 'Cozy Tails Boarding',
            rating: 4.7,
            reviews: 210,
            distance: '2.0 km',
            priceFrom: 30,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Open booking page')),
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
        color: brown,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Boarding',
            style: TextStyle(
              color: HomeScreen.lightCream,
              fontSize: 28,
              fontWeight: FontWeight.w900
            ),
          ),
          SizedBox(height: 12,),
          Text(
            'Professional grooming services including bathing, haircuts, nail trimming and more.',
            style: TextStyle(
              color: HomeScreen.lightCream
              ),
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





// LOCATIONS


class BoardingPlaceCard extends StatelessWidget {
  final String name;
  final double rating;
  final int reviews;
  final String distance;
  final int priceFrom;
  final VoidCallback onTap;

  const BoardingPlaceCard({
    super.key,
    required this.name,
    required this.rating,
    required this.reviews,
    required this.distance,
    required this.priceFrom,
    required this.onTap,
  });

  static const Color brown = Color.fromRGBO(82, 45, 11, 1);

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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.orange, size: 18),
                    Text('$rating ($reviews)'),
                    const SizedBox(width: 12),
                    const Icon(Icons.location_on, size: 18),
                    Text(distance),
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
