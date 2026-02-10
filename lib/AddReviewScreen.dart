//Add Reviews for Shop

import 'package:cloud_firestore/cloud_firestore.dart';        //Used for reading/writing shop + review data
import 'package:firebase_auth/firebase_auth.dart';            //Access to Firebase Auth, to get current logged-in user
import 'package:flutter/material.dart';

class AddReviewScreen extends StatefulWidget {
  final String shopId;                                        //Stores the shop document ID, used to know which shop review belongs to 
  const AddReviewScreen({super.key, required this.shopId});   //must pass shopId when opening screen

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  int rating = 5;                                             //Default star rating
  final commentCtrl = TextEditingController();
  bool loading = false;

  Future<void> _submit() async {                              //async allows non-blocking execution and use of await in function -> Await pause the function only until results come back
    final user = FirebaseAuth.instance.currentUser;           //Gets currently logged in user
    if (user == null) return;                                 //Safety Check: User not logged in -> Stpo immediately

    setState(() => loading = true);                           //Shows loading spinner and Disables submit button

    try {
      final shopRef =
          FirebaseFirestore.instance.collection('shops').doc(widget.shopId);    //Ref to: shops/{shopId}
      final reviewRef = shopRef.collection('reviews').doc();                    //Ref to: shops/{shopId}/reviews/{autoId}

      await FirebaseFirestore.instance.runTransaction((tx) async {              //Starts transaction, Ensures rating count and average update automatically
        final shopSnap = await tx.get(shopRef);                                 //Reads the shop document inside the transaction
        final shop = (shopSnap.data() as Map<String, dynamic>?) ?? {};          //Convert document data to Map, No data -> Empty map instead of crashing

        final count = (shop['ratingCount'] ?? 0) as num;            //Reads number of existing ratings, Defaults to 0 if field doesnt exist
        final avg = (shop['ratingAvg'] ?? 0) as num;                //Reads current average rating, Defaults to 0

        final newCount = count + 1;                                 //Increment total review count
        final newAvg = ((avg * count) + rating) / newCount;         //Correct weighted average formula -> Prevents recalculating all reviews

        tx.set(reviewRef, {                             //Save Review -> Writes the review document
          'userId': user.uid,                           //Stores who wrote the review
          'rating': rating,                             //Star rating (1-5)
          'comment': commentCtrl.text.trim(),           //Review text, .trim() removes extra spaces
          'createdAt': FieldValue.serverTimestamp(),    //Uses firestore server time 
        });

        tx.update(shopRef, {                            //Updates shop ratings -> Updates shop document fields
          'ratingCount': newCount,                      //Saves new review count
          'ratingAvg': double.parse(newAvg.toString()), //Forces value to be stored as double -> Prevents firestore num/int mix issues
        });
      });
      //Success Handling
      if (!mounted) return;
      Navigator.pop(context);                               //Close the Add Review Screen
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review added ✅')),   //Shows success message
      );
    } catch (e) {                                           //Carches Firestore/Auth errors
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),              //Displays error message
      );
    } finally {                                             //Always runs
      if (mounted) setState(() => loading = false);         //Stops loading spinner
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final bg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bg,
      //AppBar
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: Image.asset('assets/img/pawpal_logo.png', height: 65),
        centerTitle: true,
      ),
      //Body
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
             Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Add Review',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 8),
             Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Rating',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            //Star Rating Row
            Row(
              children: List.generate(5, (i) {                        //Creates 5 stars
                final star = i + 1;                                   //Star no (1-5)
                return IconButton(
                  onPressed: () => setState(() => rating = star),     //Tapping updates ratings immediately
                  icon: Icon(
                    star <= rating ? Icons.star : Icons.star_border,  //Filled star if selected and Outline Star otherwise
                    color: Colors.orange,                           //Filled star is Orange
                  ),
                );
              }),
            ),

            const SizedBox(height: 8),
            //TextField (Write the Review)
            TextField(
              controller: commentCtrl,
              maxLines: 4,
              cursorColor: primary,
              decoration: InputDecoration(
                labelText: 'Comment (optional)',
                labelStyle: TextStyle(color: primary),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: primary,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: primary,
                    width: 2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
            //Submit Button
            SizedBox(
              width: double.infinity,                           //Button stretches full width of screen
              height: 48,
              child: ElevatedButton(
                onPressed: loading ? null : _submit,            //loading==true -> onPressed = null , button disabled     laoding==false -> onPressed = _submit, calls _submit()
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)    //loading==true -> Show loading spinner
                    : const Text('Submit'),                                     //loading==false -> Show text 'Submit'
              ),
            ),
          ],
        ),
      ),
    );
  }
}

