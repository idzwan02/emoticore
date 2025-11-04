// In: lib/moodboard_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:cached_network_image/cached_network_image.dart'; // For loading images
import 'custom_page_route.dart';
import 'edit_moodboard_page.dart'; // We will create this next

class MoodboardPage extends StatefulWidget {
  const MoodboardPage({super.key});

  @override
  State<MoodboardPage> createState() => _MoodboardPageState();
}

class _MoodboardPageState extends State<MoodboardPage> {
  // Define theme colors
  static const Color appPrimaryColor = Color(0xFF5A9E9E);
  static const Color appBackgroundColor = Color(0xFFD2E9E9);

  Stream<QuerySnapshot>? _moodboardStream;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _initializeStream();
  }

  void _initializeStream() {
    if (_currentUser != null) {
      setState(() {
        _moodboardStream = FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.uid)
            .collection('moodboards') // New subcollection
            .orderBy('timestamp', descending: true)
            .snapshots();
      });
    }
  }

  // Helper to navigate to the editor page
  void _navigateToEditPage([QueryDocumentSnapshot? document]) {
     Navigator.push(
      context,
      FadeRoute(
        page: EditMoodboardPage(document: document),
      ),
    );
  }

  // Helper to build each moodboard card in the grid
  Widget _buildMoodboardCard(QueryDocumentSnapshot document) {
    final data = document.data() as Map<String, dynamic>;
    final String title = data['title'] ?? 'No Title';
    
    // Get the list of images, default to an empty list
    final List<dynamic> imageList = data['imageUrls'] ?? [];
    
    // Use the first image as the cover, or null if list is empty
    final String? coverImageUrl = imageList.isNotEmpty ? imageList[0] as String? : null;

    return InkWell(
      onTap: () => _navigateToEditPage(document),
      borderRadius: BorderRadius.circular(12.0),
      child: Card(
        elevation: 2.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        clipBehavior: Clip.antiAlias, // Clips the image to the card's shape
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Area
            AspectRatio(
              aspectRatio: 1.0, // Square aspect ratio
              child: Container(
                color: Colors.grey.shade200,
                child: coverImageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: coverImageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Center(
                        child: Lottie.asset('assets/animations/loading.json', width: 60, height: 60),
                      ),
                      errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey, size: 40),
                    )
                  : const Center(
                      child: Icon(Icons.photo_album_outlined, color: Colors.grey, size: 40),
                    ), // Placeholder
              ),
            ),
            // Title Area
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper for empty state
  Widget _buildEmptyState() {
     return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.dashboard_customize_outlined, size: 80, color: Colors.grey.shade500),
            const SizedBox(height: 16),
            const Text(
              'No Moodboards Yet',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the "+" button to create your first moodboard.',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackgroundColor,
      appBar: AppBar(
        backgroundColor: appPrimaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Moodboards',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 1.0,
      ),
      body: _currentUser == null
          ? const Center(child: Text("Please log in to see your moodboards."))
          : StreamBuilder<QuerySnapshot>(
              stream: _moodboardStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: Lottie.asset('assets/animations/loading.json', width: 150, height: 150));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                final entries = snapshot.data!.docs;
                
                // Use GridView.builder for a 2-column grid
                return GridView.builder(
                  padding: const EdgeInsets.all(12.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,      // 2 columns
                    mainAxisSpacing: 12.0,  // Space between rows
                    crossAxisSpacing: 12.0, // Space between columns
                    childAspectRatio: 0.75, // Adjust aspect ratio (height > width)
                  ),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    return _buildMoodboardCard(entries[index]);
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToEditPage(), // Pass no document to create new
        backgroundColor: appPrimaryColor,
        foregroundColor: Colors.white,
        tooltip: 'New Moodboard',
        child: const Icon(Icons.add),
      ),
    );
  }
}