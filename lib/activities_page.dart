// In: lib/activities_page.dart

import 'package:flutter/material.dart';

class ActivitiesPage extends StatelessWidget {
  const ActivitiesPage({super.key});

  static const Color activitiesPageColor = Color(0xFFB0D8D8);

  @override
  Widget build(BuildContext context) {
    // --- Define spacing and calculate item width ---
    const double horizontalPadding = 20.0;
    const double spacing = 15.0; // Horizontal gap between cards
    const int crossAxisCount = 2;

    // Calculate the available width for items
    final double screenWidth = MediaQuery.of(context).size.width;
    final double totalHorizontalPadding = horizontalPadding * 2;
    final double totalSpacing = spacing * (crossAxisCount - 1);
    final double availableWidth = screenWidth - totalHorizontalPadding - totalSpacing;
    final double itemWidth = availableWidth / crossAxisCount;
    // --- End calculation ---

    return Scaffold(
      backgroundColor: activitiesPageColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF5A9E9E),
        title: const Text(
          '\tActivities',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 2.0,
      ),
      // --- Use Padding + Wrap instead of GridView ---
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 20.0),
        child: Wrap(
          spacing: spacing, // Horizontal space between cards
          runSpacing: 15.0, // Vertical space between rows
          alignment: WrapAlignment.center, // Center items horizontally
          children: <Widget>[
            // Each card is wrapped in a SizedBox to control its width
            SizedBox(
              width: itemWidth,
              child: _buildActivityCard(
                context: context,
                icon: Icons.edit_note,
                label: 'Journaling',
                onTap: () { print('Journaling tapped'); },
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildActivityCard(
                context: context,
                icon: Icons.dashboard_customize,
                label: 'Moodboard',
                onTap: () { print('Moodboard tapped'); },
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildActivityCard(
                context: context,
                icon: Icons.quiz,
                label: 'Quizzes',
                onTap: () { print('Quizzes tapped'); },
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildActivityCard(
                context: context,
                icon: Icons.checklist_rtl,
                label: 'DASS-21',
                onTap: () { print('DASS-21 tapped'); },
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildActivityCard(
                context: context,
                icon: Icons.assignment_turned_in,
                label: 'Daily Task',
                onTap: () { print('Daily Task tapped'); },
              ),
            ),
          ],
        ),
      ),
      // bottomNavigationBar: _buildBottomNav(), // Optional
    );
  }
  // --- End Wrap ---

  // --- _buildActivityCard remains the same ---
  Widget _buildActivityCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15.0),
      child: AspectRatio( // Make card square using AspectRatio
        aspectRatio: 1.0,
        child: Card(
          elevation: 3.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, size: 50.0, color: Colors.blue.shade700),
              const SizedBox(height: 10.0),
              Padding( // Add padding to text if needed
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
                  ),
                  maxLines: 1, // Prevent text wrapping if too long
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Optional Bottom Nav ---
  // Widget _buildBottomNav() { ... }
}