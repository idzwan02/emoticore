// In: lib/dashboard_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart'; // <-- Import Lottie
import 'auth_gate.dart';
import 'activities_page.dart';
import 'custom_page_route.dart';
import 'profile_page.dart';

class EmoticoreMainPage extends StatefulWidget {
  const EmoticoreMainPage({super.key});

  @override
  State<EmoticoreMainPage> createState() => _EmoticoreMainPageState();
}

class _EmoticoreMainPageState extends State<EmoticoreMainPage> {
  int _selectedIndex = 0;
  String _userName = "";
  bool _isLoadingData = true;
  String _selectedAvatarId = 'default';
  bool _isSavingAvatar = false;
  Stream<QuerySnapshot>? _dassStream;
  String _currentMoodId = 'neutral';

  final Map<String, String> _moodEmojis = {
    'happy': '😊',
    'excited': '😃',
    'neutral': '😐',
    'anxious': '😟',
    'sad': '😔',
  };
  final Map<String, String> _moodTexts = {
    'happy': 'Happy',
    'excited': 'Excited',
    'neutral': 'Neutral',
    'anxious': 'Anxious',
    'sad': 'Sad',
  };

  static const Color appPrimaryColor = Color(0xFF5A9E9E);
  static const Color appBackgroundColor = Color(0xFFD2E9E9);
  static const Color statNumberColor = Color(0xFF4A69FF);
  static const Color goldBadgeColor = Color(0xFFD4AF37);
  static const Color redBadgeColor = Color(0xFFC70039);
  static const Color depressionBarColor = Color(0xFFEF5350);
  static const Color anxietyBarColor = Color(0xFFFFCA28);
  static const Color stressBarColor = Color(0xFF26C6DA);

  final Map<String, String> _availableAvatarAssets = {
    'default': 'assets/avatars/user.png',
    'avatar1': 'assets/avatars/dog.png',
    'avatar2': 'assets/avatars/dog (1).png',
    'avatar3': 'assets/avatars/gorilla.png',
  };

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _initializeDassStream();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerDailyMoodCheck();
    });
  }

  // --- Mood Check Functions (Keep as they were) ---
  Future<void> _triggerDailyMoodCheck() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final String? lastCheckDate = prefs.getString('lastMoodCheckDate');
    //if (lastCheckDate != todayDate) {
      if (mounted) {
        _showMoodCheckDialog();
      }
    //}
  }

  Future<void> _showMoodCheckDialog() async {
    if (!mounted) return;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('How are you feeling today?'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          content: Container(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 16.0,
                runSpacing: 16.0,
                children: _moodEmojis.keys.map((moodId) {
                  return GestureDetector(
                    onTap: () {
                      _saveMood(moodId);
                      Navigator.of(dialogContext).pop();
                    },
                    child: SizedBox(
                      width: 70,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _moodEmojis[moodId]!,
                            style: const TextStyle(fontSize: 36),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _moodTexts[moodId]!,
                            style: const TextStyle(fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveMood(String moodId) async {
    if (mounted) {
      setState(() {
        _currentMoodId = moodId;
      });
    }
    final prefs = await SharedPreferences.getInstance();
    final String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await prefs.setString('lastMoodCheckDate', todayDate);
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'currentMood': moodId, 'lastMoodUpdate': Timestamp.now()});
      } catch (e) {
        print("Error saving mood to Firestore: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not save mood.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // --- Data Fetching & User Management (Keep as they were) ---
  Future<void> _loadInitialData() async {
    if (!mounted) return;
    if (!_isLoadingData) setState(() => _isLoadingData = true);
    String finalUserName = "User";
    String finalAvatarId = 'default';
    String finalMoodId = 'neutral';
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
          finalUserName = data['name'] ?? user.displayName ?? 'User';
          String? fetchedId = data['selectedAvatarId'];
          if (fetchedId != null &&
              _availableAvatarAssets.containsKey(fetchedId)) {
            finalAvatarId = fetchedId;
          }
          Timestamp? lastUpdate = data['lastMoodUpdate'];
          if (lastUpdate != null) {
            final String todayDate = DateFormat(
              'yyyy-MM-dd',
            ).format(DateTime.now());
            final String lastUpdateDate = DateFormat(
              'yyyy-MM-dd',
            ).format(lastUpdate.toDate());
            if (todayDate == lastUpdateDate) {
              finalMoodId = data['currentMood'] ?? 'neutral';
              if (!_moodEmojis.containsKey(finalMoodId)) {
                finalMoodId = 'neutral';
              }
            }
          }
        } else {
          finalUserName = user.displayName ?? 'User';
        }
      }
    } catch (e) {
      print("Error loading initial data (name/avatar/mood): $e");
    } finally {
      if (mounted) {
        setState(() {
          _userName = finalUserName;
          _selectedAvatarId = finalAvatarId;
          _currentMoodId = finalMoodId;
          _isLoadingData = false;
        });
      }
    }
  }

  void _initializeDassStream() {
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

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          FadeRoute(page: const AuthGate()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _updateSelectedAvatarId(String newAvatarId) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null || !_availableAvatarAssets.containsKey(newAvatarId))
      return;
    setState(() => _isSavingAvatar = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'selectedAvatarId': newAvatarId},
      );
      if (mounted) {
        setState(() {
          _selectedAvatarId = newAvatarId;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avatar updated!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print("Error updating avatar ID: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update avatar.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    final List<Widget> pages = [
      // Page 0: Home Page Content
      Scaffold(
        key: ValueKey<String>(userId ?? 'logged_out_home'),
        backgroundColor: appBackgroundColor,
        // --- UPDATED ---
        body: _isLoadingData
            ? Center(
                child: Lottie.asset(
                  'assets/animations/loading.json', // <-- Use new filename
                  width: 150,
                  height: 150,
                ),
              )
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

      // Page 2: Profile Page
      ProfilePage(
        userName: _userName,
        selectedAvatarId: _selectedAvatarId,
        availableAvatarAssets: _availableAvatarAssets,
        onAvatarSelected: _updateSelectedAvatarId,
        isSavingAvatar: _isSavingAvatar,
      ),
    ];

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        key: ValueKey<int>(_selectedIndex),
        child: pages[_selectedIndex],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // --- Helper Widgets ---

  Widget _buildHeader() {
    String avatarAssetPath =
        _availableAvatarAssets[_selectedAvatarId] ??
        _availableAvatarAssets['default']!;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      width: double.infinity,
      decoration: const BoxDecoration(color: appPrimaryColor),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white70,
            backgroundImage: AssetImage(avatarAssetPath),
            onBackgroundImageError: (e, s) {
              print("Error loading header avatar: $avatarAssetPath");
            },
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Welcome",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              Text(
                _userName,
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
      redBadgeColor,
      redBadgeColor,
      goldBadgeColor,
      redBadgeColor,
      redBadgeColor,
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
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                            // --- UPDATED ---
                            child: StreamBuilder<QuerySnapshot>(
                              stream: _dassStream,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Center(
                                    child: Lottie.asset(
                                      // Use Lottie here
                                      'assets/animations/loading.json',
                                      width: 100,
                                      height: 100,
                                    ),
                                  );
                                }
                                // ... (rest of StreamBuilder remains the same)
                                if (snapshot.hasError) {
                                  return const Center(
                                    child: Text(
                                      'Error',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  );
                                }
                                if (!snapshot.hasData ||
                                    snapshot.data!.docs.isEmpty) {
                                  return _buildBarChart(0, 0, 0);
                                }
                                Map<String, dynamic>? latestData =
                                    snapshot.data!.docs.first.data()
                                        as Map<String, dynamic>?;
                                double depression =
                                    (latestData?['depressionScore'] as num?)
                                        ?.toDouble() ??
                                    0;
                                double anxiety =
                                    (latestData?['anxietyScore'] as num?)
                                        ?.toDouble() ??
                                    0;
                                double stress =
                                    (latestData?['stressScore'] as num?)
                                        ?.toDouble() ??
                                    0;
                                return _buildBarChart(
                                  depression,
                                  anxiety,
                                  stress,
                                );
                              },
                            ),
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
                          Text(
                            _moodEmojis[_currentMoodId] ?? '😐',
                            style: const TextStyle(fontSize: 60),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _moodTexts[_currentMoodId] ?? 'Neutral',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
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

  Widget _buildBarChart(
    double depressionScore,
    double anxietyScore,
    double stressScore,
  ) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 42,
        barTouchData: BarTouchData(enabled: false),
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
                if (value % 7 == 0 && value <= 42) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const Text('');
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
                  case 0:
                    text = 'Stress';
                    break;
                  case 1:
                    text = 'Anxiety';
                    break;
                  case 2:
                    text = 'Depression';
                    break;
                  default:
                    text = '';
                    break;
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
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: stressScore,
                color: stressBarColor,
                width: 12,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(
                toY: anxietyScore,
                color: anxietyBarColor,
                width: 12,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
          BarChartGroupData(
            x: 2,
            barRods: [
              BarChartRodData(
                toY: depressionScore,
                color: depressionBarColor,
                width: 12,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
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
            Text(
              value,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: statNumberColor,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
                height: 1.3,
              ),
            ),
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
          child: const Text(
            "Your article content goes here...",
            style: TextStyle(color: Colors.grey),
          ),
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
        BottomNavigationBarItem(
          icon: Icon(Icons.list_alt),
          label: "Activities",
        ),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
      ],
    );
  }
}
