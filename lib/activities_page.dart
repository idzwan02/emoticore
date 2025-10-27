// In: lib/activities_page.dart

import 'package:flutter/material.dart';
import 'custom_page_route.dart'; // <-- Import the custom FadeRoute
import 'dass21_page.dart';     // <-- Import the DASS-21 page

class ActivitiesPage extends StatelessWidget {
  const ActivitiesPage({super.key});

  // Define the background color
  static const Color activitiesPageColor = Color(0xFFB0D8D8);
  // Define the primary color (consistent with AppBar)
  static const Color appPrimaryColor = Color(0xFF5A9E9E);

  @override
  Widget build(BuildContext context) {
    // Define spacing and calculate item width
    const double horizontalPadding = 20.0;
    const double spacing = 15.0; // Horizontal gap between cards
    const int crossAxisCount = 2; // Number of columns

    // Calculate the available width for items based on screen size
    final double screenWidth = MediaQuery.of(context).size.width;
    final double totalHorizontalPadding = horizontalPadding * 2;
    final double totalSpacing = spacing * (crossAxisCount - 1);
    final double availableWidth = screenWidth - totalHorizontalPadding - totalSpacing;
    final double itemWidth = availableWidth / crossAxisCount;

    return Scaffold(
      backgroundColor: activitiesPageColor,
      appBar: AppBar(
        backgroundColor: appPrimaryColor, // Use consistent primary color
        // Removed the leading back button as navigation is handled by BottomNavBar
        automaticallyImplyLeading: false,
        title: const Text(
          'Activities',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 1.0, // Reduced elevation for a flatter look
      ),
      // Use Padding + Wrap for centering the last item
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
                onTap: () {
                  // TODO: Implement navigation to Journaling Page using FadeRoute
                  print('Journaling tapped');
                  // Example: Navigator.push(context, FadeRoute(page: JournalingPage()));
                },
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildActivityCard(
                context: context,
                icon: Icons.dashboard_customize,
                label: 'Moodboard',
                onTap: () {
                  // TODO: Implement navigation to Moodboard Page using FadeRoute
                  print('Moodboard tapped');
                  // Example: Navigator.push(context, FadeRoute(page: MoodboardPage()));
                },
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildActivityCard(
                context: context,
                icon: Icons.quiz,
                label: 'Quizzes',
                onTap: () {
                   // TODO: Implement navigation to Quizzes Page using FadeRoute
                  print('Quizzes tapped');
                   // Example: Navigator.push(context, FadeRoute(page: QuizzesPage()));
                },
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildActivityCard(
                context: context,
                icon: Icons.checklist_rtl,
                label: 'DASS-21',
                onTap: () {
                  // --- Use FadeRoute for DASS-21 ---
                  Navigator.push(
                    context,
                    FadeRoute(page: const Dass21Page()), // USE FadeRoute
                  );
                  // --- End FadeRoute ---
                },
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildActivityCard(
                context: context,
                icon: Icons.assignment_turned_in,
                label: 'Daily Task',
                onTap: () {
                  // TODO: Implement navigation to Daily Task Page using FadeRoute
                  print('Daily Task tapped');
                  // Example: Navigator.push(context, FadeRoute(page: DailyTaskPage()));
                },
              ),
            ),
          ],
        ),
      ),
      // No BottomNavigationBar here, as this page is shown *within* the dashboard's structure
    );
  }

  // Helper widget to build each activity card
  Widget _buildActivityCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15.0), // Match shape for ripple
      child: AspectRatio( // Ensure card is square
        aspectRatio: 1.0,
        child: Card(
          elevation: 2.0, // Softer shadow
          shadowColor: Colors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, size: 50.0, color: appPrimaryColor), // Use theme color for icon
              const SizedBox(height: 12.0), // Adjusted spacing
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15.0, // Slightly smaller font
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