import 'dart:convert';                                    //converts Base64 string -> bytes for images
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:draft_asgn/AddPetScreen.dart';            //Used when navigating to Edit Pet Screen

class PetProfileScreen extends StatelessWidget {
  final String userId;                                    //which user's pets collection
  final String petId;                                     //which pet document to load

  const PetProfileScreen({                                //Requires both IDs to function
    super.key,
    required this.userId,
    required this.petId,
  });

  DocumentReference<Map<String, dynamic>> get _petRef => FirebaseFirestore        //builds Firestore path: users/{userId}/pets/{petId}
      .instance
      .collection('users')
      .doc(userId)
      .collection('pets')
      .doc(petId);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _petRef.snapshots(),                                    //snapshots()-> live firestore stream, Any edit/delete updates the screen instantly
      builder: (context, snapshot) {
        // Loading
        if (snapshot.connectionState == ConnectionState.waiting) {    //Firestore hasnt returned data yet
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),         //Shows loading spinner
          );
        }

        // Deleted or missing
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Pet Profile'),
            ),
            body: const Center(child: Text('Pet not found (maybe deleted).')),
          );
        }

        final petData = snapshot.data!.data() ?? {};                  //data() -> Map<String,dynamic>       fallback to empty map for safety

        ImageProvider? petImage;                                      //Declares nullable image
        final base64Str = petData['profilePicBase64'];                //Reads stored Base64 string
        if (base64Str is String && base64Str.isNotEmpty) {            //Correct type and not empty
          try {
            petImage = MemoryImage(base64Decode(base64Str));          //Converts Base64 -> bytes -> Image
          } catch (_) {                                               //Prevents creashes if corrupted data
            petImage = null;
          }
        }
        //UI
        return Scaffold(
         
          appBar: AppBar(
            centerTitle: true,
            backgroundColor: Colors.transparent,
            iconTheme: const IconThemeData(
              color: Colors.black
            ),
            title: Image.asset(
              'assets/img/pawpal_logo.png',
              height: 65,
            ),
            
          ),
          body: SingleChildScrollView(                                                //Scrollable
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(16),
                    image: petImage != null
                        ? DecorationImage(image: petImage, fit: BoxFit.cover)         //Shows pet image if available
                        : null,                                                       //Otherwise grey box with Icon.pet in it
                  ),
                  child: petImage == null
                      ? const Icon(Icons.pets, size: 60, color: Colors.white)
                      : null,
                ),
                const SizedBox(height: 20),
                //Reusable helper widget
                _info('Name', petData['name']),
                _info('Species', petData['species']),
                _info('Breed', petData['breed']),
                _info('Size', petData['size']),
                _info('Age', petData['age']),
                _info('Notes', petData['notes']),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(                                            //Prevents overlap with system UI
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddPetScreen(                         //Routes to AddPetScreen which is has 2 modes: Add/Edit
                              petId: petId,
                              existingPetData: petData,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            
                            title:  Text('Delete pet?',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge,
                            ),
                            content: const Text('This cannot be undone.',
                              
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),      //Passes confirm=true to the next few lines
                                child: const Text('Delete'),
                                
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await _petRef.delete();                                   //Deletes Firestore document
                          if (context.mounted) Navigator.pop(context);              //Safely go back after deletion
                        }
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ),
          ),

        );
      },
    );
  }

  static Widget _info(String label, dynamic value) {                                  //Reusable info row
    final text = (value == null || (value is String && value.trim().isEmpty))
        ? '—'                                                                         //Shows dash if empty/missing
        : value.toString();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
