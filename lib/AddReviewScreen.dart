import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddReviewScreen extends StatefulWidget {
  final String shopId;
  const AddReviewScreen({super.key, required this.shopId});

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  int rating = 5;
  final commentCtrl = TextEditingController();
  bool loading = false;

  Future<void> _submit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => loading = true);

    try {
      final shopRef =
          FirebaseFirestore.instance.collection('shops').doc(widget.shopId);
      final reviewRef = shopRef.collection('reviews').doc();

      await FirebaseFirestore.instance.runTransaction((tx) async {
        final shopSnap = await tx.get(shopRef);
        final shop = (shopSnap.data() as Map<String, dynamic>?) ?? {};

        final count = (shop['ratingCount'] ?? 0) as num;
        final avg = (shop['ratingAvg'] ?? 0) as num;

        final newCount = count + 1;
        final newAvg = ((avg * count) + rating) / newCount;

        tx.set(reviewRef, {
          'userId': user.uid,
          'rating': rating,
          'comment': commentCtrl.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });

        tx.update(shopRef, {
          'ratingCount': newCount,
          'ratingAvg': double.parse(newAvg.toString()),
        });
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review added ✅')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final bg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: Image.asset('assets/img/pawpal_logo.png', height: 65),
        centerTitle: true,
      ),
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

            Row(
              children: List.generate(5, (i) {
                final star = i + 1;
                return IconButton(
                  onPressed: () => setState(() => rating = star),
                  icon: Icon(
                    star <= rating ? Icons.star : Icons.star_border,
                    color: Colors.orange,
                  ),
                );
              }),
            ),

            const SizedBox(height: 8),

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

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: loading ? null : _submit,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

