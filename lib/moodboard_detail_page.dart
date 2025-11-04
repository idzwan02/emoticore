// In: lib/moodboard_detail_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lottie/lottie.dart';
import 'custom_page_route.dart';
import 'edit_moodboard_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MoodboardDetailPage extends StatefulWidget {
  final QueryDocumentSnapshot document;
  const MoodboardDetailPage({super.key, required this.document});

  @override
  State<MoodboardDetailPage> createState() => _MoodboardDetailPageState();
}

class _MoodboardDetailPageState extends State<MoodboardDetailPage> {
  late Stream<DocumentSnapshot> _documentStream;

  static const Color appPrimaryColor = Color(0xFF5A9E9E);
  static const Color appBackgroundColor = Color(0xFFD2E9E9);
  static const Color cardBackgroundColor = Color(0xFFFCFCFC); // White "canvas"

  @override
  void initState() {
    super.initState();
    // Listen to changes on this specific document
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _documentStream = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('moodboards')
          .doc(widget.document.id)
          .snapshots();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _documentStream,
      builder: (context, snapshot) {
        
        // --- Handle Loading ---
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: appBackgroundColor,
            appBar: AppBar(backgroundColor: appPrimaryColor, elevation: 0),
            body: Center(
              child: Lottie.asset('assets/animations/loading.json', width: 150, height: 150),
            ),
          );
        }

        // --- Handle Error or Deleted Document ---
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
           return Scaffold(
            backgroundColor: appBackgroundColor,
            appBar: AppBar(
              backgroundColor: appPrimaryColor,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: const Center(
              child: Text(
                'Moodboard not found or has been deleted.',
                style: TextStyle(fontSize: 16),
              ),
            ),
          );
        }

        // --- Extract Live Data ---
        final data = snapshot.data!.data() as Map<String, dynamic>;
        final String title = data['title'] ?? 'No Title';
        final String content = data['content'] ?? '';
        final List<dynamic> imageList = data['imageUrls'] ?? [];
        final int imageCount = imageList.length;


        return Scaffold(
          backgroundColor: appBackgroundColor,
          appBar: AppBar(
            backgroundColor: appPrimaryColor,
            elevation: 1.0,
            title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    FadeRoute(
                      page: EditMoodboardPage(document: widget.document),
                    ),
                  );
                },
                tooltip: 'Edit Moodboard',
              ),
            ],
          ),
          // --- LAYOUT ---
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(12.0),
            child: Card(
              color: cardBackgroundColor,
              elevation: 2.0,
              shadowColor: Colors.black.withOpacity(0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
              clipBehavior: Clip.antiAlias, // Clip images
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  // --- 1. Title ---
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 8.0), // Less bottom padding
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 26, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.black87,
                        height: 1.3,
                      ),
                    ),
                  ),
                  
                  // --- 2. Description/Content (MOVED HERE) ---
                  if (content.isNotEmpty)
                    Padding(
                      // Use horizontal padding to match title
                      padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 16.0), 
                      child: Text(
                        content,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade800,
                          height: 1.5, // Line spacing
                        ),
                      ),
                    ),
                  
                  // --- 3. Image Collage ---
                  if (imageList.isNotEmpty)
                    Padding(
                      // Add padding so images don't touch the card edge
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _buildImageCollage(imageList, imageCount),
                    ),
                  
                  // Add empty space at the bottom for balance
                  const SizedBox(height: 20),

                ],
              ),
            ),
          ),
          // --- END LAYOUT ---
        );
      },
    );
  }

  // --- Helper to build the image grid ---
  Widget _buildImageCollage(List<dynamic> imageUrls, int imageCount) {
    // (This function remains the same as before)
    return MasonryGridView.count(
      crossAxisCount: 2,
      itemCount: imageUrls.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 6.0,
      crossAxisSpacing: 6.0,
      itemBuilder: (context, index) {
        // SCENARIO 1: Only 1 image
        if (imageCount == 1) {
          return StaggeredGridTile.count(
             crossAxisCellCount: 2, mainAxisCellCount: 2,
             child: _buildImageTile(imageUrls[index] as String, height: 250)
          );
        }
        // SCENARIO 2: Only 2 images
        if (imageCount == 2) {
          return StaggeredGridTile.count(
             crossAxisCellCount: 1, mainAxisCellCount: 2,
             child: _buildImageTile(imageUrls[index] as String, height: 220)
          );
        }
        // SCENARIO 3: 3+ images (use random-ish stagger)
        double height = (index % 3 == 0) ? 200 : 140;
        return StaggeredGridTile.count(
           crossAxisCellCount: 1,
           mainAxisCellCount: (index % 3 == 0) ? 2 : 1,
           child: _buildImageTile(imageUrls[index] as String, height: height)
        );
      },
    );
  }

  // --- Helper to build the image tile itself ---
  Widget _buildImageTile(String url, {required double height}) {
     // (This function remains the same)
     return ClipRRect(
      borderRadius: BorderRadius.circular(12.0),
      child: CachedNetworkImage(
        imageUrl: url,
        height: height,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          height: height,
          color: Colors.grey.shade200,
          child: Center(child: Lottie.asset('assets/animations/loading.json', width: 60, height: 60)),
        ),
        errorWidget: (context, url, error) => Container(
          height: height,
          color: Colors.grey.shade200,
          child: const Icon(Icons.broken_image, color: Colors.grey)
        ),
      ),
    );
  }
}