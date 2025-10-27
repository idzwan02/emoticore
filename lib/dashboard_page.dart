// In: lib/dashboard_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_gate.dart';
import 'activities_page.dart';
import 'custom_page_route.dart'; // <-- Import the custom FadeRoute

class EmoticoreMainPage extends StatefulWidget {
  const EmoticoreMainPage({super.key});

  @override
  State<EmoticoreMainPage> createState() => _EmoticoreMainPageState();
}

class _EmoticoreMainPageState extends State<EmoticoreMainPage> {
  int _selectedIndex = 0;
  String _userName = "";
  bool _isLoadingName = true;

  Stream<QuerySnapshot>? _dassStream;

  // Define colors
  static const Color appPrimaryColor = Color(0xFF5A9E9E);
  static const Color appBackgroundColor = Color(0xFFD2E9E9);
  static const Color statNumberColor = Color(0xFF4A69FF);
  static const Color goldBadgeColor = Color(0xFFD4AF37);
  static const Color redBadgeColor = Color(0xFFC70039);
  static const Color depressionBarColor = Color(0xFFEF5350);
  static const Color anxietyBarColor = Color(0xFFFFCA28);
  static const Color stressBarColor = Color(0xFF26C6DA);

  @override
  void initState() {
    super.initState();
    _fetchUserName();
    _initializeDassStream();
  }

  Future<void> _fetchUserName() async {
    // (Keep this function as it was - cleaned version)
    if (!mounted) return;
    if (!_isLoadingName) setState(() => _isLoadingName = true);

    String finalUserName = "User";
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get()
            .timeout(const Duration(seconds: 15));

        if (userDoc.exists) {
          Map<String, dynamic>? data = userDoc.data() as Map<String, dynamic>?;
          finalUserName = data?['name'] ?? user.displayName ?? 'User';
        } else {
           finalUserName = user.displayName ?? 'User';
        }
      }
    } catch (e) {
      print("Error fetching user name: $e");
    } finally {
      if (mounted) {
        setState(() {
          _userName = finalUserName;
          _isLoadingName = false;
        });
      }
    }
  }

  void _initializeDassStream() {
    // (Keep this function as it was)
     User? user = FirebaseAuth.instance.currentUser;
     if (user != null) {
       _dassStream = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('dass21_results')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .snapshots();
     } else {
        print("Cannot initialize DASS stream: User is null.");
     }
  }


  // --- Updated _signOut function with FadeRoute ---
  Future<void> _signOut() async {
     try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil( // Keep pushAndRemoveUntil
          context,
          FadeRoute(page: const AuthGate()), // USE FadeRoute HERE
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
  // --- End updated _signOut ---

  @override
  Widget build(BuildContext context) {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    // Define _pages INSIDE the build method
    final List<Widget> pages = [
      // Page 0: Home Page Content
      Scaffold(
         key: ValueKey<String>(userId ?? 'logged_out_home'), // Keep key
         backgroundColor: appBackgroundColor,
         body: _isLoadingName
             ? const Center(child: CircularProgressIndicator())
             : SingleChildScrollView(
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
         key: ValueKey<String>(userId ?? 'logged_out_profile'), // Keep key
         backgroundColor: appBackgroundColor,
         appBar: AppBar(
             backgroundColor: appPrimaryColor,
             title: const Text('Profile', style: TextStyle(color: Colors.white)),
             automaticallyImplyLeading: false,
             actions: [ IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: _signOut, tooltip: "Logout",), ],
         ),
         body: _isLoadingName
              ? const Center(child: CircularProgressIndicator())
              : Center( child: Text("Profile Page Content\nUser: $_userName", textAlign: TextAlign.center, ), ),
      ),
    ];

    return Scaffold(
      // --- Use AnimatedSwitcher for Tab Transitions ---
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300), // Animation duration
        transitionBuilder: (Widget child, Animation<double> animation) {
          // Use FadeTransition
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: pages[_selectedIndex], // Show the currently selected page
        key: ValueKey<int>(_selectedIndex), // Key to detect page change
      ),
      // --- End AnimatedSwitcher ---
      bottomNavigationBar: _buildBottomNav(),
    );
  }


  // --- Helper Widgets ---

  Widget _buildHeader() {
    // (Keep this function as it was)
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      width: double.infinity,
      decoration: const BoxDecoration( color: appPrimaryColor, ),
      child: Row(
         children: [
          const CircleAvatar(radius: 32, backgroundColor: Colors.white70, child: Icon(Icons.person, size: 40, color: Colors.white)),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Welcome", style: TextStyle(color: Colors.white, fontSize: 16)),
              Text(_userName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
          const Spacer(),
          IconButton(icon: const Icon(Icons.logout, color: Colors.white, size: 30), onPressed: _signOut, tooltip: "Logout"),
        ],
      ),
    );
  }

   Widget _buildSectionTitle(String title) {
     // (Keep this function as it was)
     return Padding(
      padding: const EdgeInsets.fromLTRB(20, 25, 20, 10),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }

  Widget _buildBadgesSection() {
    // (Keep this function as it was)
     final List<Color> badgeColors = [ redBadgeColor, redBadgeColor, goldBadgeColor, redBadgeColor, redBadgeColor ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Card(
        elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Row( mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: badgeColors.map((color) => _buildBadge(color)).toList(), ),
        ),
      ),
    );
  }

  Widget _buildBadge(Color color) {
    // (Keep this function as it was)
    return Icon(Icons.emoji_events, color: color, size: 40);
  }

  Widget _buildStatisticsSection() {
    // (Keep this function as it was, uses StreamBuilder internally)
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // REMOVED title text here previously
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
                            child: StreamBuilder<QuerySnapshot>(
                              stream: _dassStream,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator(strokeWidth: 2.0));
                                }
                                if (snapshot.hasError) {
                                  print("DASS Stream Error: ${snapshot.error}");
                                  return const Center(child: Text('Error loading scores', style: TextStyle(color: Colors.red)));
                                }
                                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                  return _buildBarChart(0, 0, 0);
                                }
                                Map<String, dynamic>? latestData = snapshot.data!.docs.first.data() as Map<String, dynamic>?;
                                double depression = (latestData?['depressionScore'] as num?)?.toDouble() ?? 0;
                                double anxiety = (latestData?['anxietyScore'] as num?)?.toDouble() ?? 0;
                                double stress = (latestData?['stressScore'] as num?)?.toDouble() ?? 0;
                                return _buildBarChart(depression, anxiety, stress);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const VerticalDivider(thickness: 1, color: Colors.grey, width: 20),
                    Expanded(
                      flex: 1,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Your Mood"),
                          const SizedBox(height: 10),
                          Icon(Icons.sentiment_satisfied, size: 70, color: Colors.orange.shade400),
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

   Widget _buildBarChart(double depressionScore, double anxietyScore, double stressScore) {
    // (Keep this function as it was - with reordered bars)
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround, maxY: 42, barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true, rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles( sideTitles: SideTitles( showTitles: true, interval: 7, reservedSize: 28, getTitlesWidget: (value, meta) { if (value % 7 == 0 && value <= 42) { return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10)); } return const Text(''); }, ), ),
          bottomTitles: AxisTitles( sideTitles: SideTitles( showTitles: true, reservedSize: 30, getTitlesWidget: (value, meta) { String text; switch (value.toInt()) { case 0: text = 'Stress'; break; case 1: text = 'Anxiety'; break; case 2: text = 'Depression'; break; default: text = ''; break; } return SideTitleWidget( meta: meta, child: Container( width: 70, alignment: Alignment.center, child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11), overflow: TextOverflow.ellipsis), ), ); }, ), ),
        ),
        gridData: FlGridData( show: true, drawVerticalLine: false, horizontalInterval: 7, getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade300, strokeWidth: 0.8, dashArray: [5, 5]), ),
        borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.shade400, width: 1)),
        barGroups: [
          BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: stressScore, color: stressBarColor, width: 12, borderRadius: BorderRadius.circular(4))]),
          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: anxietyScore, color: anxietyBarColor, width: 12, borderRadius: BorderRadius.circular(4))]),
          BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: depressionScore, color: depressionBarColor, width: 12, borderRadius: BorderRadius.circular(4))]),
        ],
      ),
    );
  }

  Widget _buildStatsCardsRow() {
    // (Keep this function as it was)
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
    // (Keep this function as it was)
     return Card(
      elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    // (Keep this function as it was)
     return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Card(
        elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: double.infinity, height: 120, padding: const EdgeInsets.all(16),
          child: const Text("Your article content goes here...", style: TextStyle(color: Colors.grey)),
        ),
      ),
    );
  }


  Widget _buildBottomNav() {
    // (Keep this function as it was)
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) { setState(() { _selectedIndex = index; }); },
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