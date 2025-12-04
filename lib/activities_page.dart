// In: lib/activities_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <-- IMPORT ADDED
import 'package:cloud_firestore/cloud_firestore.dart'; // <-- IMPORT ADDED
import 'custom_page_route.dart';
import 'dass21_page.dart';
import 'journaling_page.dart';
import 'moodboard_page.dart';
import 'pop_quiz_page.dart';

class ActivitiesPage extends StatefulWidget {
  const ActivitiesPage({super.key});

  @override
  State<ActivitiesPage> createState() => _ActivitiesPageState();
}

class _ActivitiesPageState extends State<ActivitiesPage> {
  // Define the background color
  static const Color activitiesPageColor = Color(0xFFB0D8D8);
  // Define the primary color (consistent with AppBar)
  static const Color appPrimaryColor = Color(0xFF5A9E9E);

  // --- UPDATED TIME CHECK LOGIC ---
  Future<void> _handleDass21Tap() async {
    // 1. Show a loading indicator while we check (optional, but good UX if network is slow)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      String? lastCompletionDateStr = prefs.getString('lastDass21CompletionDate');

      // 2. LOOPHOLE FIX: If local data is missing, check Firestore
      if (lastCompletionDateStr == null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final querySnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('dass21_results')
              .orderBy('timestamp', descending: true)
              .limit(1)
              .get();

          if (querySnapshot.docs.isNotEmpty) {
            // Found a record on the server!
            final lastDoc = querySnapshot.docs.first;
            final Timestamp timestamp = lastDoc['timestamp'];
            lastCompletionDateStr = timestamp.toDate().toIso8601String();

            // Save it locally so next time is faster
            await prefs.setString(
                'lastDass21CompletionDate', lastCompletionDateStr);
          }
        }
      }

      // Close the loading indicator
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // 3. Now proceed with the check logic
      if (lastCompletionDateStr == null) {
        // Truly no record found anywhere. Let them proceed.
        if (mounted) {
          Navigator.push(
            context,
            FadeRoute(page: const Dass21Page()),
          );
        }
        return;
      }

      final DateTime lastCompletionDate = DateTime.parse(lastCompletionDateStr);
      final int daysSinceLast =
          DateTime.now().difference(lastCompletionDate).inDays;

      if (daysSinceLast < 7) {
        // It has been less than 7 days
        final int daysRemaining = 7 - daysSinceLast;
        final String dayWord = daysRemaining == 1 ? 'day' : 'days';
        if (mounted) {
          _showTimeLockDialog(
              'Assessment Locked',
              'You can take the DASS-21 assessment again in $daysRemaining $dayWord.');
        }
      } else {
        // It has been 7 or more days, let them proceed
        if (mounted) {
          Navigator.push(
            context,
            FadeRoute(page: const Dass21Page()),
          );
        }
      }
    } catch (e) {
      // Close loading if error
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      print("Error checking DASS date: $e");
      // If error, we default to letting them in or showing an error message
      // For now, let's just let them in to avoid locking them out due to a bug
      if (mounted) {
        Navigator.push(
          context,
          FadeRoute(page: const Dass21Page()),
        );
      }
    }
  }

  Future<void> _showTimeLockDialog(String title, String content) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          actions: <Widget>[
            TextButton(
              child: const Text('OK',
                  style: TextStyle(
                      color: appPrimaryColor, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
  // --- End Updated Logic ---

  @override
  Widget build(BuildContext context) {
    const double itemWidth = 150.0; 
    const double spacing = 15.0; 

    return Scaffold(
      backgroundColor: activitiesPageColor,
      appBar: AppBar(
        backgroundColor: appPrimaryColor,
        automaticallyImplyLeading: false,
        title: const Text(
          'Activities',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 1.0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20.0,
            vertical: 20.0,
          ),
          child: Wrap(
            spacing: spacing,
            runSpacing: 15.0,
            alignment: WrapAlignment.center,
            children: <Widget>[
              // Card 1: Journaling
              SizedBox(
                width: itemWidth,
                child: _buildActivityCard(
                  context: context,
                  icon: Icons.edit_note,
                  label: 'Journaling',
                  onTap: () {
                    Navigator.push(
                      context,
                      FadeRoute(page: const JournalingPage()),
                    );
                  },
                ),
              ),
              // Card 2: Moodboard
              SizedBox(
                width: itemWidth,
                child: _buildActivityCard(
                  context: context,
                  icon: Icons.dashboard_customize,
                  label: 'Moodboard',
                  onTap: () {
                    Navigator.push(
                      context,
                      FadeRoute(page: const MoodboardPage()),
                    );
                  },
                ),
              ),
              // Card 3: Pop Quiz
              SizedBox(
                width: itemWidth,
                child: _buildActivityCard(
                  context: context,
                  icon: Icons.quiz,
                  label: 'Pop Quiz',
                  onTap: () {
                    Navigator.push(
                      context,
                      FadeRoute(page: const PopQuizPage()),
                    );
                  },
                ),
              ),
              // Card 4: DASS-21
              SizedBox(
                width: itemWidth,
                child: _buildActivityCard(
                  context: context,
                  icon: Icons.checklist_rtl,
                  label: 'DASS-21',
                  onTap: _handleDass21Tap, // Using the new secure check
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15.0),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Card(
          elevation: 2.0,
          shadowColor: Colors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                icon,
                size: 50.0,
                color: appPrimaryColor,
              ),
              const SizedBox(height: 12.0),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15.0,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}