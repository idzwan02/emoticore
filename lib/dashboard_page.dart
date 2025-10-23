// In: lib/dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_gate.dart';
import 'activities_page.dart';

class EmoticoreMainPage extends StatefulWidget {
  const EmoticoreMainPage({super.key});

  @override
  State<EmoticoreMainPage> createState() => _EmoticoreMainPageState();
}

class _EmoticoreMainPageState extends State<EmoticoreMainPage> {
  int _selectedIndex = 0;
  String _userName = "Loading..."; // State variable for the user's name

  // --- Define your app's colors ---
  static const Color appPrimaryColor = Color(0xFF5A9E9E);
  static const Color appBackgroundColor = Color(0xFFD2E9E9);
  static const Color statNumberColor = Color(0xFF4A69FF);
  static const Color goldBadgeColor = Color(0xFFD4AF37);
  static const Color redBadgeColor = Color(0xFFC70039);
  static const Color depressionBarColor = Color(0xFFEF5350);
  static const Color anxietyBarColor = Color(0xFFFFCA28);
  static const Color stressBarColor = Color(0xFF26C6DA);

  // Note: _pages list is defined inside the build method now

  @override
  void initState() {
    super.initState();
    _fetchUserName(); // Fetch name when the widget initializes
  }

  // --- Cleaned _fetchUserName ---
  Future<void> _fetchUserName() async {
    // Basic check if widget is still mounted
    if (!mounted) return;

    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic>? data = userDoc.data() as Map<String, dynamic>?;

          if (data != null && data.containsKey('name')) {
             final fetchedName = data['name'];
             if (mounted) {
               setState(() {
                 _userName = fetchedName ?? 'User'; // Use default if name is null
               });
             }
          } else {
             // Fallback using Auth display name if Firestore name is missing
             final authDisplayName = user.displayName;
             if (mounted) {
               setState(() {
                 _userName = authDisplayName ?? 'User';
               });
             }
          }
        } else {
           // Fallback using Auth display name if Firestore doc doesn't exist
           final authDisplayName = user.displayName;
           if (mounted) {
             setState(() {
               _userName = authDisplayName ?? 'User';
             });
           }
        }
      } else {
         // Handle case where no user is logged in
         if (mounted) {
           setState(() {
             _userName = "User"; // Or redirect to login?
           });
         }
      }
    } catch (e) {
      // Handle potential errors (e.g., network issues)
      print("Error fetching user name: $e"); // Keep one error log just in case
      if (mounted) {
        setState(() {
          _userName = "User"; // Set a default on error
        });
      }
    }
  }
  // --- END of cleaned _fetchUserName ---


  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AuthGate()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: ${e.toString()}'))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define _pages INSIDE the build method
    final List<Widget> pages = [
      // Page 0: Home Page Content
      Scaffold(
         backgroundColor: appBackgroundColor,
         body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildSectionTitle("Your Badges"),
                _buildBadgesSection(),
                _buildSectionTitle("Your Statistics"),
                _buildStatisticsSection(),
                const SizedBox(height: 20),
                _buildStatsCardsRow(),
                _buildSectionTitle("Article"),
                _buildArticleSection(),
                const SizedBox(height: 30),
              ],
            ),
          ),
      ),

      // Page 1: Activities Page
      const ActivitiesPage(),

      // Page 2: Profile Page Content
       Scaffold(
         backgroundColor: appBackgroundColor,
         appBar: AppBar(
             backgroundColor: appPrimaryColor,
             title: const Text('Profile', style: TextStyle(color: Colors.white)),
             automaticallyImplyLeading: false,
             actions: [
               IconButton(
                 icon: const Icon(Icons.logout, color: Colors.white),
                 onPressed: _signOut,
                 tooltip: "Logout",
               ),
             ],
         ),
         body: Center(
           child: Text(
             "Profile Page Content\nUser: $_userName",
              textAlign: TextAlign.center,
           ),
         ),
      ),
    ];

    // Removed the build method's print statement

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }


  // --- Helper Widgets ---

  Widget _buildHeader() {
    // Removed the print statement
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      width: double.infinity,
      decoration: const BoxDecoration(
        color: appPrimaryColor,
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white70,
            child: Icon(Icons.person, size: 40, color: Colors.white),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Welcome",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              Text(
                _userName, // Directly uses the current state variable
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white, size: 30),
            onPressed: _signOut,
            tooltip: "Logout",
          ),
        ],
      ),
    );
  }

  // ... (Keep _buildSectionTitle, _buildBadgesSection, _buildBadge,
  //      _buildStatisticsSection, _buildBarChart, _buildStatsCardsRow,
  //      _buildStatCard, _buildArticleSection, _buildBottomNav exactly as they were,
  //      they didn't have print statements) ...

   Widget _buildSectionTitle(String title) {
     return Padding(
      padding: const EdgeInsets.fromLTRB(20, 25, 20, 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildBadgesSection() {
     final List<Color> badgeColors = [
      redBadgeColor, redBadgeColor, goldBadgeColor, redBadgeColor, redBadgeColor,
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: badgeColors.map((color) => _buildBadge(color)).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(Color color) {
    return Icon(Icons.emoji_events, color: color, size: 40);
  }

  Widget _buildStatisticsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Your DASS-21 Scores"),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 120,
                            child: _buildBarChart(),
                          ),
                        ],
                      ),
                    ),
                    const VerticalDivider(
                      thickness: 1,
                      color: Colors.grey,
                      width: 20,
                    ),
                    Expanded(
                      flex: 1,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Your Mood"),
                          const SizedBox(height: 10),
                          Icon(Icons.sentiment_satisfied,
                              size: 70, color: Colors.orange.shade400),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

   Widget _buildBarChart() {
    final double depressionScore = 14;
    final double anxietyScore = 8;
    final double stressScore = 18;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 21,
        barTouchData: BarTouchData(
          enabled: false,
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 7,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10));
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                String text;
                switch (value.toInt()) {
                  case 0: text = 'Depression'; break;
                  case 1: text = 'Anxiety'; break;
                  case 2: text = 'Stress'; break;
                  default: text = ''; break;
                }
                return SideTitleWidget(
                  meta: meta,
                  child: Container(
                    width: 70,
                    alignment: Alignment.center,
                    child: Text(
                      text,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 7,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade300,
            strokeWidth: 0.8,
            dashArray: [5, 5],
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade400, width: 1),
        ),
        barGroups: [
          BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: depressionScore, color: depressionBarColor, width: 12, borderRadius: BorderRadius.circular(4))]),
          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: anxietyScore, color: anxietyBarColor, width: 12, borderRadius: BorderRadius.circular(4))]),
          BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: stressScore, color: stressBarColor, width: 12, borderRadius: BorderRadius.circular(4))]),
        ],
      ),
    );
  }

  Widget _buildStatsCardsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        children: [
          Expanded(child: _buildStatCard("8", "Badges\nUnlocked")),
          const SizedBox(width: 10),
          Expanded(child: _buildStatCard("1000", "Total\nPoints")),
          const SizedBox(width: 10),
          Expanded(child: _buildStatCard("3", "Moodboard\nCreated")),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label) {
     return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: statNumberColor)),
            const SizedBox(height: 5),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.3)),
          ],
        ),
      ),
    );
  }

  Widget _buildArticleSection() {
     return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: double.infinity,
          height: 120,
          padding: const EdgeInsets.all(16),
          child: const Text("Your article content goes here...", style: TextStyle(color: Colors.grey)),
        ),
      ),
    );
  }


  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      backgroundColor: appPrimaryColor,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white.withOpacity(0.6),
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: "Activities"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
      ],
    );
  }

} // End of _EmoticoreMainPageState class