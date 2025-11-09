// In: lib/moodboard_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart'; // Make sure this is in pubspec.yaml
import 'custom_page_route.dart';
import 'edit_moodboard_page.dart';
import 'moodboard_detail_page.dart'; // <-- 1. Import the Detail Page

class MoodboardPage extends StatefulWidget {
  const MoodboardPage({super.key});

  @override
  State<MoodboardPage> createState() => _MoodboardPageState();
}

class _MoodboardPageState extends State<MoodboardPage> {
  // Define theme colors
  static const Color appPrimaryColor = Color(0xFF5A9E9E);
  static const Color appBackgroundColor = Color(0xFFD2E9E9);
  
  final List<Color> _cardColors = [
    const Color(0xFFFFF8E1), // Light Yellow
    const Color(0xFFFCE4EC), // Light Pink
    const Color(0xFFE3F2FD), // Light Blue
    const Color(0xFFF3E5F5), // Light Purple
  ];

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
            .doc(_currentUser.uid)
            .collection('moodboards')
            .orderBy('timestamp', descending: true)
            .snapshots();
      });
    }
  }

  // --- 2. UPDATED: Navigate to Detail Page ---
  void _navigateToDetailPage(QueryDocumentSnapshot document) {
     Navigator.push(
      context,
      FadeRoute(
        page: MoodboardDetailPage(document: document), // Go to the detail page
      ),
    );
  }

  // --- 3. Card Widget (Shows a simple preview) ---
  Widget _buildMoodboardCard(QueryDocumentSnapshot document, int index) {
    final data = document.data() as Map<String, dynamic>;
    final String title = data['title'] ?? 'No Title';
    final String content = data['content'] ?? '';
    final List<dynamic> imageList = data['imageUrls'] ?? [];
    
    // Use the first image as the cover, or null if list is empty
    final String? coverImageUrl = imageList.isNotEmpty ? imageList[0] as String? : null;
    
    final cardColor = _cardColors[index % _cardColors.length];

    return InkWell(
      onTap: () => _navigateToDetailPage(document), // <-- 4. Use correct navigation
      borderRadius: BorderRadius.circular(12.0),
      child: Card(
        elevation: 1.0,
        color: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        clipBehavior: Clip.antiAlias, // Important for clipping
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Show ONLY the cover image ---
            if (coverImageUrl != null)
              CachedNetworkImage(
                imageUrl: coverImageUrl,
                // Give images different heights based on index to create a staggered look
                height: (index % 3 == 0) ? 200 : 150, 
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: (index % 3 == 0) ? 200 : 150,
                  color: Colors.black.withOpacity(0.05)
                ),
                errorWidget: (context, url, error) => Container(
                  height: (index % 3 == 0) ? 200 : 150,
                  child: const Icon(Icons.broken_image, color: Colors.grey)
                ),
              ),
            // --- END ---
            
            // Text Content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.black87),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (content.isNotEmpty) ...[
                    const SizedBox(height: 8.0),
                    Text(
                      content,
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 14, height: 1.4),
                      maxLines: 3, // Only show a small snippet
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmptyState() {
     // (This function remains the same)
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
                
                // --- 5. Use MasonryGridView for the staggered list page ---
                return MasonryGridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8.0,
                  crossAxisSpacing: 8.0,
                  padding: const EdgeInsets.all(12.0),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    return _buildMoodboardCard(entries[index], index);
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        // --- 6. FAB goes to Edit Page ---
        onPressed: () {
          // Pass no document to create a new one
          Navigator.push(
            context,
            FadeRoute(page: const EditMoodboardPage()), 
          );
        },
        backgroundColor: appPrimaryColor,
        foregroundColor: Colors.white,
        tooltip: 'New Moodboard',
        child: const Icon(Icons.add),
      ),
    );
  }
}