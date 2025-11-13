// In: lib/dashboard_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'auth_gate.dart';
import 'activities_page.dart';
import 'custom_page_route.dart';
import 'profile_page.dart';
import 'streak_service.dart'; // Import the streak service

class EmoticoreMainPage extends StatefulWidget {
  final User user;

  const EmoticoreMainPage({super.key, required this.user});

  @override
  State<EmoticoreMainPage> createState() => _EmoticoreMainPageState();
}

class _EmoticoreMainPageState extends State<EmoticoreMainPage> {
  int _selectedIndex = 0;
  bool _isLoadingData = true;
  bool _isSavingAvatar = false;
  Stream<QuerySnapshot>? _dassStream;
  String _currentMoodId = 'neutral';
  
  // --- 1. ADD NEW STREAM FOR MOODBOARD COUNT ---
  Stream<QuerySnapshot>? _moodboardStream;
  
  // --- Maps for Mood Data ---
  final Map<String, String> _moodEmojis = {
    'happy': ' 😊 ', 'excited': ' 😃 ', 'neutral': ' 😐 ', 'anxious': ' 😟 ', 'sad': ' 😔 ',
  };
  final Map<String, String> _moodTexts = {
    'happy': 'Happy', 'excited': 'Excited', 'neutral': 'Neutral', 'anxious': 'Anxious', 'sad': 'Sad',
  };
  // --- End Mood Maps ---
  // --- Color Definitions ---
  static const Color appPrimaryColor = Color(0xFF5A9E9E);
  static const Color appBackgroundColor = Color(0xFFD2E9E9);
  static const Color statNumberColor = Color(0xFF4A69FF);
  static const Color goldBadgeColor = Color(0xFFD4AF37);
  static const Color redBadgeColor = Color(0xFFC70039);
  static const Color depressionBarColor = Color(0xFFEF5350);
  static const Color anxietyBarColor = Color(0xFFFFCA28);
  static const Color stressBarColor = Color(0xFF26C6DA);
  static const Color streakColor = Color(0xFFF08A00); // Orange/flame color

  // --- Avatar Asset Map ---
  final Map<String, String> _availableAvatarAssets = {
    'default': 'assets/avatars/user.png',
    'astronaut (2)': 'assets/avatars/astronaut (2).png',
    'astronaut': 'assets/avatars/astronaut.png',
    'bear': 'assets/avatars/bear.png',
    'boy': 'assets/avatars/boy.png',
    'cat (2)': 'assets/avatars/cat (2).png',
    'cat': 'assets/avatars/cat.png',
    'chicken': 'assets/avatars/chicken.png',
    'cow': 'assets/avatars/cow.png',
    'dog (1)': 'assets/avatars/dog (1).png',
    'dog (2)': 'assets/avatars/dog (2).png',
    'dog': 'assets/avatars/dog.png',
    'dragon': 'assets/avatars/dragon.png',
    'eagle': 'assets/avatars/eagle.png',
    'fox': 'assets/avatars/fox.png',
    'gamer': 'assets/avatars/gamer.png',
    'gorilla': 'assets/avatars/gorilla.png',
    'hen': 'assets/avatars/hen.png',
    'hippopotamus': 'assets/avatars/hippopotamus.png',
    'human': 'assets/avatars/human.png',
    'koala': 'assets/avatars/koala.png',
    'lion': 'assets/avatars/lion.png',
    'man (1)': 'assets/avatars/man (1).png',
    'man (2)': 'assets/avatars/man (2).png',
    'man (3)': 'assets/avatars/man (3).png',
    'man (4)': 'assets/avatars/man (4).png',
    'man (5)': 'assets/avatars/man (5).png',
    'man (6)': 'assets/avatars/man (6).png',
    'man (7)': 'assets/avatars/man (7).png',
    'man (8)': 'assets/avatars/man (8).png',
    'man (9)': 'assets/avatars/man (9).png',
    'man (10)': 'assets/avatars/man (10).png',
    'man (11)': 'assets/avatars/man (11).png',
    'man (12)': 'assets/avatars/man (12).png',
    'man (13)': 'assets/avatars/man (13).png',
    'man': 'assets/avatars/man.png',
    'meerkat': 'assets/avatars/meerkat.png',
    'owl': 'assets/avatars/owl.png',
    'panda': 'assets/avatars/panda.png',
    'polar-bear': 'assets/avatars/polar-bear.png',
    'profile (2)': 'assets/avatars/profile (2).png',
    'profile': 'assets/avatars/profile.png',
    'puffer-fish': 'assets/avatars/puffer-fish.png',
    'rabbit': 'assets/avatars/rabbit.png',
    'robot': 'assets/avatars/robot.png',
    'shark': 'assets/avatars/shark.png',
    'sloth': 'assets/avatars/sloth.png',
    'user (1)': 'assets/avatars/user (1).png',
    'user (2)': 'assets/avatars/user (2).png',
    'user': 'assets/avatars/user.png',
    'woman (1)': 'assets/avatars/woman (1).png',
    'woman (2)': 'assets/avatars/woman (2).png',
    'woman (3)': 'assets/avatars/woman (3).png',
    'woman (4)': 'assets/avatars/woman (4).png',
    'woman (5)': 'assets/avatars/woman (5).png',
    'woman (6)': 'assets/avatars/woman (6).png',
    'woman': 'assets/avatars/woman.png',
  };
  // --- End Avatar Asset Map ---
  
  Stream<DocumentSnapshot>? _userStream;

  @override
  void initState() {
    super.initState();
    _initializeDashboard();
  }

  Future<void> _initializeDashboard() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingData = true;
    });

    try {
      User user = widget.user;
      await _createUserDataIfMissing(user);
      _initializeStreams();
      await _loadMoodData();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerDailyMoodCheck();
      });

    } catch (e) {
      print("Error initializing dashboard: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  // (Daily Mood Check functions are unchanged)
   Future<void> _triggerDailyMoodCheck() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final String? lastCheckDate = prefs.getString('lastMoodCheckDate');

    if (lastCheckDate != todayDate) {
      if (mounted) {
        _showMoodCheckDialog();
      }
    }
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

  // (saveMood is unchanged)
  Future<void> _saveMood(String moodId) async {
    if (mounted) {
      setState(() {
        _currentMoodId = moodId;
      });
    }
    final prefs = await SharedPreferences.getInstance();
    final String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await prefs.setString('lastMoodCheckDate', todayDate);
    
    User user = widget.user; 
    
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'currentMood': moodId, 'lastMoodUpdate': Timestamp.now()});
          
      await StreakService.updateDailyStreak(user);
          
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

  // (createUserDataIfMissing is unchanged)
  Future<void> _createUserDataIfMissing(User user) async {
    final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final userDoc = await userDocRef.get();

    if (!userDoc.exists) {
      print("User document not found! Creating one...");
      try {
        await userDocRef.set({
          'name': user.displayName ?? 'New User',
          'email': user.email ?? 'No email',
          'joinedAt': Timestamp.now(),
          'selectedAvatarId': 'default',
          'currentMood': 'neutral',
          'dateOfBirth': 'Not set',
          'totalPoints': 0,
          'currentStreak': 0,
          'lastCheckInDate': null,
        });
        print("User document created successfully.");
      } catch (e) {
        print("Error creating user document: $e");
      }
    }
  }

  // (loadMoodData is unchanged)
  Future<void> _loadMoodData() async {
    String finalMoodId = 'neutral';
    try {
      User user = widget.user;
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        Timestamp? lastUpdate = data['lastMoodUpdate'];
        if (lastUpdate != null) {
          final String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
          final String lastUpdateDate = DateFormat('yyyy-MM-dd').format(lastUpdate.toDate());
          if (todayDate == lastUpdateDate) {
            finalMoodId = data['currentMood'] ?? 'neutral';
            if (!_moodEmojis.containsKey(finalMoodId)) {
              finalMoodId = 'neutral';
            }
          }
        }
      }
    } catch (e) {
      print("Error loading mood data: $e");
    }

    if (mounted) {
      setState(() {
        _currentMoodId = finalMoodId;
      });
    }
  }

  // --- 2. UPDATE initializeStreams ---
  void _initializeStreams() {
    User user = widget.user;
    _dassStream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('dass21_results')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots();
    _userStream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots();
        
    // --- ADD THIS ---
    _moodboardStream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('moodboards')
        .snapshots();
    // --- END ADD ---
  }

  // (signOut is unchanged)
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

  // (updateSelectedAvatarId is unchanged)
  Future<void> _updateSelectedAvatarId(String newAvatarId) async { 
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null || !_availableAvatarAssets.containsKey(newAvatarId)) return;
    setState(() => _isSavingAvatar = true); 
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'selectedAvatarId': newAvatarId},
      );
      if (mounted) {
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
      if (mounted)
        setState(() => _isSavingAvatar = false); 
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // The _pages list is now created inside the build method.
    final List<Widget> pages = [
      _buildHomePage(),
      const ActivitiesPage(),
      ProfilePage(
        onChangeAccount: _signOut,
        userStream: _userStream, 
        availableAvatarAssets: _availableAvatarAssets,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages, 
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }
  
  // (buildHomePage is unchanged)
  Widget _buildHomePage() {
    return Scaffold(
      key: const ValueKey<String>('home_page'),
      backgroundColor: appBackgroundColor,
      body: _isLoadingData
          ? Center(
              child: Lottie.asset(
                'assets/animations/loading.json',
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
                  _buildSectionTitle("Daily Check-in"),
                  _buildDailyCheckInSection(),
                  _buildSectionTitle("Today's Tasks"),
                  _buildTasksSection(), 
                  _buildSectionTitle("Your Statistics"),
                  _buildStatisticsSection(),
                  const SizedBox(height: 20),
                  _buildStatsCardsRow(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  // (Header is unchanged)
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
      width: double.infinity,
      decoration: const BoxDecoration(color: appPrimaryColor),
      child: Row(
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: _userStream, 
            builder: (context, snapshot) {
              String avatarAssetId = 'default';
              String name = 'User';

              if (snapshot.hasData &&
                  snapshot.data!.exists &&
                  snapshot.data!.data() != null) {
                final data = snapshot.data!.data() as Map<String, dynamic>;
                name = data['name'] ?? 'User';
                String? fetchedId = data['selectedAvatarId'];
                if (fetchedId != null &&
                    _availableAvatarAssets.containsKey(fetchedId)) {
                  avatarAssetId = fetchedId;
                }
              }
              
              String avatarAssetPath =
                  _availableAvatarAssets[avatarAssetId] ??
                      _availableAvatarAssets['default']!;
              
              return Row(
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
                        name, 
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const Spacer(),
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
                            child: StreamBuilder<QuerySnapshot>(
                              stream: _dassStream,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Center(
                                    child: Lottie.asset(
                                      'assets/animations/loading.json',
                                      width: 100,
                                      height: 100,
                                    ),
                                  );
                                }
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
                            _moodEmojis[_currentMoodId] ?? ' 😐 ',
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

  // --- 3. THIS IS THE UPDATED WIDGET ---
  Widget _buildStatsCardsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        children: [
          // --- BADGES (Still a placeholder) ---
          Expanded(child: _buildStatCard("8", "Badges\nUnlocked")),
          const SizedBox(width: 10),
          
          // --- TOTAL POINTS (Live) ---
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: _userStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return _buildStatCard("0", "Total\nPoints");
                }
                final data = snapshot.data!.data() as Map<String, dynamic>;
                final int totalPoints = data['totalPoints'] ?? 0;
                return _buildStatCard(totalPoints.toString(), "Total\nPoints");
              }
            ),
          ),
          const SizedBox(width: 10),

          // --- MOODBOARDS (Live) ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _moodboardStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return _buildStatCard("0", "Moodboard\nCreated");
                }
                final int moodboardCount = snapshot.data!.docs.length;
                return _buildStatCard(moodboardCount.toString(), "Moodboard\nCreated");
              }
            ),
          ),
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

  // (DailyCheckInSection is unchanged)
  Widget _buildDailyCheckInSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: double.infinity,
          height: 120,
          padding: const EdgeInsets.all(16),
          child: StreamBuilder<DocumentSnapshot>(
            stream: _userStream, // Use the stream you already have!
            builder: (context, snapshot) {
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(child: Text("Loading streak..."));
              }
              
              final data = snapshot.data!.data() as Map<String, dynamic>;
              final int streak = data['currentStreak'] ?? 0;
              final String lastCheckIn = data['lastCheckInDate'] ?? '';
              final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

              final bool isCheckedInToday = (lastCheckIn == today);
              
              final Color activeColor = isCheckedInToday ? streakColor : Colors.grey.shade600;

              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.local_fire_department, // Flame icon
                        color: activeColor,
                        size: 48,
                      ),
                      Text(
                        "$streak DAY${streak == 1 ? '' : 'S'}",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: activeColor,
                        ),
                      ),
                    ],
                  ),
                  const VerticalDivider(
                    thickness: 1,
                    color: Colors.grey,
                    width: 40,
                    indent: 10,
                    endIndent: 10,
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isCheckedInToday)
                          Row(
                            children: const [
                              Icon(Icons.check_circle, color: Colors.green, size: 28),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "Check-in Complete!",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          )
                        else
                          Row(
                            children: const [
                              Icon(Icons.radio_button_unchecked, color: Colors.grey, size: 28),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "Check-in today!",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 8),
                        Text(
                          isCheckedInToday
                            ? "Great job! Your streak is safe."
                            : "Log your mood or do an activity to build your streak.",
                          style: TextStyle(color: Colors.grey.shade700, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // (TasksSection is unchanged)
  Widget _buildTasksSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Column(
            children: [
              _buildTaskTile(
                "Complete a Pop Quiz", 
                "+50 pts", 
                false
              ),
              _buildTaskTile(
                "Write a journal entry", 
                "+25 pts", 
                false
              ),
              _buildTaskTile(
                "Weekly: Take DASS-21", 
                "+100 pts", 
                true 
              ),
            ],
          ),
        ),
      ),
    );
  }

  // (TaskTile helper is unchanged)
  Widget _buildTaskTile(String title, String reward, bool isCompleted) {
    return ListTile(
      leading: Icon(
        isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
        color: isCompleted ? Colors.green : Colors.grey,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          decoration: isCompleted ? TextDecoration.lineThrough : null,
          color: isCompleted ? Colors.grey : Colors.black87,
        ),
      ),
      trailing: Text(
        reward,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isCompleted ? Colors.grey : statNumberColor,
        ),
      ),
    );
  }

  // (BottomNav is unchanged)
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