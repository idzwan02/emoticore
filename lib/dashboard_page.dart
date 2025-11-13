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

class EmoticoreMainPage extends StatefulWidget {
  final User user;

  const EmoticoreMainPage({super.key, required this.user});

  @override
  State<EmoticoreMainPage> createState() => _EmoticoreMainPageState();
}

class _EmoticoreMainPageState extends State<EmoticoreMainPage> {
  int _selectedIndex = 0;
  bool _isLoadingData = true; // This is now the ONLY loading flag
  bool _isSavingAvatar = false;
  Stream<QuerySnapshot>? _dassStream;
  String _currentMoodId = 'neutral';
  // (Maps and Colors are unchanged)
  final Map<String, String> _moodEmojis = {
    'happy': ' 😊 ', 'excited': ' 😃 ', 'neutral': ' 😐 ', 'anxious': ' 😟 ', 'sad': ' 😔 ',
  };
  final Map<String, String> _moodTexts = {
    'happy': 'Happy', 'excited': 'Excited', 'neutral': 'Neutral', 'anxious': 'Anxious', 'sad': 'Sad',
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
  
  Stream<DocumentSnapshot>? _userStream;

  @override
  void initState() {
    super.initState();
    // --- THIS IS THE FIX ---
    // We only call ONE function from initState.
    // This function will now run in the correct order.
    _initializeDashboard();
    // --- END FIX ---
  }

  // --- NEW FUNCTION to control loading order ---
  Future<void> _initializeDashboard() async {
    if (!mounted) return;
    
    // Set loading state
    setState(() {
      _isLoadingData = true;
    });

    try {
      // 1. Get the user
      User user = widget.user;

      // 2. Ensure the user document exists *before* doing anything else
      await _createUserDataIfMissing(user);

      // 3. NOW it is safe to initialize the streams
      _initializeStreams();

      // 4. Load one-time data (like mood)
      await _loadMoodData();

      // 5. Trigger daily check
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerDailyMoodCheck();
      });

    } catch (e) {
      print("Error initializing dashboard: $e");
      // Handle error state if necessary
    } finally {
      // 6. Set loading to false, which rebuilds the UI
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }
  // --- END NEW FUNCTION ---

  // (Daily Mood Check functions are unchanged)
  Future<void> _triggerDailyMoodCheck() async { /* ... */ }
  Future<void> _showMoodCheckDialog() async { /* ... */ }
  Future<void> _saveMood(String moodId) async { /* ... */ }

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
        });
        print("User document created successfully.");
      } catch (e) {
        print("Error creating user document: $e");
      }
    }
  }

  // --- RENAMED & SIMPLIFIED ---
  // This function is now only responsible for loading mood
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

  // (initializeStreams is unchanged)
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
  }

  // (signOut is unchanged)
  Future<void> _signOut() async { /* ... */ }

  // (updateSelectedAvatarId is unchanged)
  Future<void> _updateSelectedAvatarId(String newAvatarId) async { /* ... */ }
  
  @override
  Widget build(BuildContext context) {
    // This list is now created inside the build method.
    final List<Widget> pages = [
      _buildHomePage(), // This will now correctly show loading or content
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
  
  // (buildHomePage helper is unchanged)
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
    );
  }

  // (Header is unchanged)
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
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

  // --- (Rest of the file is unchanged) ---
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