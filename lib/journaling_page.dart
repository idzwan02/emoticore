// In: lib/journaling_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cached_network_image/cached_network_image.dart'; // <-- Import
import 'custom_page_route.dart';
import 'edit_journal_page.dart';

class JournalingPage extends StatefulWidget {
  const JournalingPage({super.key});

  @override
  State<JournalingPage> createState() => _JournalingPageState();
}

class _JournalingPageState extends State<JournalingPage> with SingleTickerProviderStateMixin {
  
  static const Color appPrimaryColor = Color(0xFF5A9E9E);
  static const Color appBackgroundColor = Color(0xFFD2E9E9);
  
  final List<Color> _cardColors = [
    const Color(0xFFFFF8E1), // Light Yellow
    const Color(0xFFFCE4EC), // Light Pink
    const Color(0xFFE3F2FD), // Light Blue
    const Color(0xFFF3E5F5), // Light Purple
  ];

  late TabController _tabController;
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  late Query _baseQuery;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    if (_currentUser != null) {
      _baseQuery = FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser.uid)
          .collection('journal_entries');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _navigateToEditPage([QueryDocumentSnapshot? document]) {
     Navigator.push(
      context,
      FadeRoute(page: EditJournalPage(document: document)),
    );
  }

  Widget _buildJournalStream(Query query) {
    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
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
        
        return MasonryGridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 8.0,
          crossAxisSpacing: 8.0,
          padding: const EdgeInsets.all(12.0),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            return _buildEntryCard(entries[index], index);
          },
        );
      },
    );
  }
  
  // --- UPDATED Card Widget ---
  Widget _buildEntryCard(QueryDocumentSnapshot document, int index) {
     final data = document.data() as Map<String, dynamic>;
     final String title = data['title'] ?? 'No Title';
     final String content = data['content'] ?? '';
     final Timestamp? timestamp = data['timestamp'];
     
     // --- NEW: Get Image URL ---
     final String? imageUrl = data['imageUrl'];
     // --- END NEW ---

     String formattedDate = 'No date';
     if (timestamp != null) {
       formattedDate = DateFormat('MMM d').format(timestamp.toDate());
     }
     
     final cardColor = _cardColors[index % _cardColors.length];

    return InkWell(
      onTap: () => _navigateToEditPage(document),
      borderRadius: BorderRadius.circular(12.0),
      child: Card(
        elevation: 1.0,
        color: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        clipBehavior: Clip.antiAlias, // Important for clipping the image
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- NEW: Display Image if it exists ---
            if (imageUrl != null && imageUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: imageUrl,
                height: 120, // Fixed height for thumbnail
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 120,
                  color: Colors.black.withOpacity(0.05),
                  child: Center(child: Lottie.asset('assets/animations/loading.json', width: 60, height: 60)),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 120,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            // --- END NEW ---
            
            // Padding for text content
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
                  const SizedBox(height: 8.0),
                  Text(
                    content,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 14, height: 1.4),
                    maxLines: imageUrl != null ? 3 : 7, // Show less text if there's an image
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    formattedDate,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  // --- END UPDATED Card ---
  
  Widget _buildEmptyState() {
     return Center( child: Padding( padding: const EdgeInsets.all(24.0), child: Column( mainAxisAlignment: MainAxisAlignment.center, children: [ Icon(Icons.edit_note, size: 80, color: Colors.grey.shade500), const SizedBox(height: 16), const Text( 'No Entries Found', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold), ), const SizedBox(height: 8), Text( 'Tap the "+" button to write a journal entry, or check another tab.', style: TextStyle(fontSize: 16, color: Colors.grey.shade600), textAlign: TextAlign.center, ), ], ), ), );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackgroundColor,
      appBar: AppBar(
        backgroundColor: appPrimaryColor,
        leading: IconButton( icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context), ),
        title: const Text( 'My Journal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), ),
        elevation: 1.0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white, unselectedLabelColor: Colors.white.withOpacity(0.7),
          indicatorColor: Colors.white, indicatorWeight: 3.0,
          tabs: const [ Tab(text: 'All'), Tab(text: 'Important'), Tab(text: 'Bookmarked'), ],
        ),
      ),
      body: _currentUser == null
          ? const Center(child: Text("Please log in to see your journal."))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildJournalStream(_baseQuery.orderBy('timestamp', descending: true)),
                _buildJournalStream(_baseQuery.where('isImportant', isEqualTo: true).orderBy('timestamp', descending: true)),
                _buildJournalStream(_baseQuery.where('isBookmarked', isEqualTo: true).orderBy('timestamp', descending: true)),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToEditPage(),
        backgroundColor: appPrimaryColor, foregroundColor: Colors.white,
        tooltip: 'New Entry',
        child: const Icon(Icons.add),
      ),
    );
  }
}