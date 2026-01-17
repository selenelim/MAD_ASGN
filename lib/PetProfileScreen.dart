import 'dart:convert';
import 'package:flutter/material.dart';

class PetProfileScreen extends StatelessWidget {
  final Map<String, dynamic> petData;

  const PetProfileScreen({super.key, required this.petData});

  @override
  Widget build(BuildContext context) {
    ImageProvider? petImage;
    if (petData['profilePicBase64'] != null) {
      try {
        petImage = MemoryImage(base64Decode(petData['profilePicBase64']));
      } catch (e) {
        petImage = null;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(petData['name'] ?? 'Pet Profile'),
        backgroundColor: const Color(0xFF522D0B),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Rounded rectangle profile pic
            Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: Colors.grey[300], // fallback color
                borderRadius: BorderRadius.circular(16),
                image: petImage != null
                    ? DecorationImage(
                        image: petImage,
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: petImage == null
                  ? const Icon(Icons.pets, size: 60, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 20),

            // Pet details
            _buildInfoRow('Name', petData['name'] ?? 'Unknown'),
            _buildInfoRow('Species', petData['species'] ?? 'Unknown'),
            _buildInfoRow('Breed', petData['breed'] ?? 'Unknown'),
            _buildInfoRow('Size', petData['size'] ?? 'Unknown'),
            _buildInfoRow('Age', petData['age'] ?? 'Unknown'),
            _buildInfoRow('Notes', petData['notes'] ?? 'None'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
