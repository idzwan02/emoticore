// In: lib/activities_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import 'custom_page_route.dart'; 
import 'dass21_page.dart';
import 'journaling_page.dart';
import 'moodboard_page.dart';
import 'pop_quiz_page.dart'; // Make sure this is imported

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

  // --- (Time check logic for DASS-21 is unchanged) ---
  Future<void> _handleDass21Tap() async {
    final prefs = await SharedPreferences.getInstance();
    final String? lastCompletionDateStr =
        prefs.getString('lastDass21CompletionDate');

    if (lastCompletionDateStr == null) {
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
      final int daysRemaining = 7 - daysSinceLast;
      final String dayWord = daysRemaining == 1 ? 'day' : 'days';
      if (mounted) {
        _showTimeLockDialog(
            'Assessment Locked',
            'You can take the DASS-21 assessment again in $daysRemaining $dayWord.'
        );
      }
    } else {
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
  // --- (End of DASS-21 logic) ---

  @override
  Widget build(BuildContext context) {
    // --- 1. REMOVED all the screen width calculations ---
    
    // --- 2. SET a fixed size for cards ---
    const double itemWidth = 150.0; 
    const double spacing = 15.0; // Horizontal gap between cards

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
      // --- 3. WRAP the body in a Center widget ---
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20.0, // This padding is now for the whole centered block
            vertical: 20.0,
          ),
          child: Wrap(
            spacing: spacing, // Horizontal space between cards
            runSpacing: 15.0, // Vertical space between rows
            alignment: WrapAlignment.center, // Keep this to center items
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
                  onTap: _handleDass21Tap,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // (This helper widget is unchanged)
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