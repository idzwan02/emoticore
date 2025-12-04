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
import 'streak_service.dart'; 
import 'gamification_service.dart';
import 'gamification_data.dart'; 

class EmoticoreMainPage extends StatefulWidget {
  final User user;

  const EmoticoreMainPage({super.key, required this.user});

  @override
  State<EmoticoreMainPage> createState() => _EmoticoreMainPageState();
}

class _EmoticoreMainPageState extends State<EmoticoreMainPage> {
  int _selectedIndex = 0;
  bool _isLoadingData = true;
  Stream<QuerySnapshot>? _dassStream;
  Stream<QuerySnapshot>? _journalStream;
  Stream<DocumentSnapshot>? _userStream;
  String _currentMoodId = 'neutral';

  // --- Maps for Mood Data ---
  final Map<String, String> _moodEmojis = {
    'happy': ' 😊 ', 'excited': ' 😃 ', 'neutral': ' 😐 ', 'anxious': ' 😟 ', 'sad': ' 😔 ',
  };
  final Map<String, String> _moodTexts = {
    'happy': 'Happy', 'excited': 'Excited', 'neutral': 'Neutral', 'anxious': 'Anxious', 'sad': 'Sad',
  };

  // --- Color Definitions ---
  static const Color appPrimaryColor = Color(0xFF5A9E9E);
  static const Color appBackgroundColor = Color(0xFFD2E9E9);
  static const Color statNumberColor = Color(0xFF4A69FF);
  static const Color goldBadgeColor = Color(0xFFD4AF37);
  static const Color redBadgeColor = Color(0xFFC70039);
  static const Color depressionBarColor = Color(0xFFEF5350);
  static const Color anxietyBarColor = Color(0xFFFFCA28);
  static const Color stressBarColor = Color(0xFF26C6DA);
  static const Color streakColor = Color(0xFFF08A00);

  @override
  void initState() {
    super.initState();
    _initializeDashboard();
  }

  // Reload if user changes (important for multi-user)
  @override
  void didUpdateWidget(EmoticoreMainPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.uid != widget.user.uid) {
      _initializeDashboard();
    }
  }

  Future<void> _initializeDashboard() async {
    if (!mounted) return;
    setState(() => _isLoadingData = true);

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
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  // --- Daily Mood Check ---
  Future<void> _triggerDailyMoodCheck() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    
    final prefs = await SharedPreferences.getInstance();
    final String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final String key = 'lastMoodCheckDate_${widget.user.uid}'; 
    final String? lastCheckDate = prefs.getString(key);
    
    if (lastCheckDate != todayDate) {
      if (mounted) _showMoodCheckDialog();
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
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
                          Text(_moodEmojis[moodId]!, style: const TextStyle(fontSize: 36)),
                          const SizedBox(height: 8),
                          Text(_moodTexts[moodId]!, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
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
    if (mounted) setState(() => _currentMoodId = moodId);
    
    final prefs = await SharedPreferences.getInstance();
    final String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    User user = widget.user; 
    
    final String key = 'lastMoodCheckDate_${user.uid}';
    await prefs.setString(key, todayDate);
    
    try {
      // 1. Update Mood
      await FirebaseFirestore.instance.collection('users').doc(user.uid)
          .update({'currentMood': moodId, 'lastMoodUpdate': Timestamp.now()});
          
      // 2. Update Streak AND Points (This is now handled inside StreakService)
      await StreakService.updateDailyStreak(user);

      // 3. Check Badges
      await GamificationService.checkBadges(user);
          
    } catch (e) {
      print("Error saving mood: $e");
    }
  }

  // --- Data Loading ---
  Future<void> _createUserDataIfMissing(User user) async {
    final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final userDoc = await userDocRef.get();

    if (!userDoc.exists) {
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
          'longestStreak': 0, // Initialize new field
          'lastCheckInDate': null,
          'unlockedBadges': [], 
        });
      } catch (e) {
        print("Error creating user document: $e");
      }
    }
  }

  Future<void> _loadMoodData() async {
    String finalMoodId = 'neutral';
    try {
      User user = widget.user;
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        Timestamp? lastUpdate = data['lastMoodUpdate'];
        if (lastUpdate != null) {
          final String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
          final String lastUpdateDate = DateFormat('yyyy-MM-dd').format(lastUpdate.toDate());
          if (todayDate == lastUpdateDate) {
            finalMoodId = data['currentMood'] ?? 'neutral';
            if (!_moodEmojis.containsKey(finalMoodId)) finalMoodId = 'neutral';
          }
        }
      }
    } catch (e) {
      print("Error loading mood data: $e");
    }
    if (mounted) setState(() => _currentMoodId = finalMoodId);
  }

  void _initializeStreams() {
    User user = widget.user;
    _dassStream = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('dass21_results').orderBy('timestamp', descending: true).limit(1).snapshots();
    _journalStream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('journal_entries')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots();
    _userStream = FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots();
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(context, FadeRoute(page: const AuthGate()), (route) => false);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomePage(),
      const ActivitiesPage(),
      ProfilePage(
        onChangeAccount: _signOut,
        userStream: _userStream, 
        availableAvatarAssets: masterAvatarAssets, 
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: _buildBottomNav(),
    );
  }
  
  Widget _buildHomePage() {
    return Scaffold(
      key: const ValueKey<String>('home_page'),
      backgroundColor: appBackgroundColor,
      body: _isLoadingData
          ? Center(child: Lottie.asset('assets/animations/loading.json', width: 150, height: 150))
          : RefreshIndicator(
              // --- THIS ADDS PULL-TO-REFRESH ---
              onRefresh: _initializeDashboard, 
              color: appPrimaryColor,
              backgroundColor: Colors.white,
              child: SingleChildScrollView(
                // We add physics to ensure it's always scrollable, 
                // otherwise refresh won't work on short screens.
                physics: const AlwaysScrollableScrollPhysics(),
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
                  _buildStatsCardsRow(), // Updated
                  const SizedBox(height: 30),
                ],
              ),
            ),
            ),
    );
  }

  // (Header Unchanged)
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
              if (snapshot.hasData && snapshot.data!.exists && snapshot.data!.data() != null) {
                final data = snapshot.data!.data() as Map<String, dynamic>;
                name = data['name'] ?? 'User';
                String? fetchedId = data['selectedAvatarId'];
                if (fetchedId != null && masterAvatarAssets.containsKey(fetchedId)) {
                  avatarAssetId = fetchedId;
                }
              }
              String avatarAssetPath = masterAvatarAssets[avatarAssetId] ?? masterAvatarAssets['default']!;
              
              return Row(
                children: [
                  CircleAvatar(radius: 32, backgroundColor: Colors.white70, backgroundImage: AssetImage(avatarAssetPath)),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Welcome", style: TextStyle(color: Colors.white, fontSize: 16)),
                      Text(name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
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
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }

  Widget _buildBadgesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
          child: StreamBuilder<DocumentSnapshot>(
            stream: _userStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(child: Text("Loading..."));
              }
              
              final data = snapshot.data!.data() as Map<String, dynamic>;
              final List<String> unlockedIds = List<String>.from(data['unlockedBadges'] ?? []);

              if (unlockedIds.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text("Start completing tasks to earn badges!", style: TextStyle(color: Colors.grey)),
                  ),
                );
              }

              return Wrap(
                spacing: 15.0,
                runSpacing: 10.0,
                alignment: WrapAlignment.center,
                children: unlockedIds.map((id) {
                  final badge = allBadges.firstWhere((b) => b.id == id, orElse: () => allBadges[0]);
                  return Tooltip(
                    message: badge.description,
                    triggerMode: TooltipTriggerMode.tap,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(badge.icon, color: badge.color, size: 40),
                        const SizedBox(height: 4),
                        Text(badge.name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
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
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return Center(child: Lottie.asset('assets/animations/loading.json', width: 100, height: 100));
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
                          Text(_moodEmojis[_currentMoodId] ?? ' 😐 ', style: const TextStyle(fontSize: 60)),
                          const SizedBox(height: 5),
                          Text(_moodTexts[_currentMoodId] ?? 'Neutral', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
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
              showTitles: true, interval: 7, reservedSize: 28,
              getTitlesWidget: (value, meta) {
                if (value % 7 == 0 && value <= 42) return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10));
                return const Text('');
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true, reservedSize: 30,
              getTitlesWidget: (value, meta) {
                String text;
                switch (value.toInt()) {
                  case 0: text = 'Stress'; break;
                  case 1: text = 'Anxiety'; break;
                  case 2: text = 'Depression'; break;
                  default: text = ''; break;
                }
                return SideTitleWidget(meta: meta, child: Container(width: 70, alignment: Alignment.center, child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11), overflow: TextOverflow.ellipsis)));
              },
            ),
          ),
        ),
        gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 7, getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade300, strokeWidth: 0.8, dashArray: [5, 5])),
        borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.shade400, width: 1)),
        barGroups: [
          BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: stressScore, color: stressBarColor, width: 12, borderRadius: BorderRadius.circular(4))]),
          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: anxietyScore, color: anxietyBarColor, width: 12, borderRadius: BorderRadius.circular(4))]),
          BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: depressionScore, color: depressionBarColor, width: 12, borderRadius: BorderRadius.circular(4))]),
        ],
      ),
    );
  }

  // --- 4. UPDATED STATS ROW ---
  Widget _buildStatsCardsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        children: [
          // Badges
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: _userStream,
              builder: (context, snapshot) {
                String count = "0";
                if (snapshot.hasData && snapshot.data!.exists) {
                   final data = snapshot.data!.data() as Map<String, dynamic>;
                   final list = data['unlockedBadges'] as List?;
                   count = (list?.length ?? 0).toString();
                }
                return _buildStatCard(count, "Badges\nUnlocked");
              }
            ),
          ),
          const SizedBox(width: 10),
          // Total Points
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: _userStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData || !snapshot.data!.exists) return _buildStatCard("0", "Total\nPoints");
                final data = snapshot.data!.data() as Map<String, dynamic>;
                return _buildStatCard((data['totalPoints'] ?? 0).toString(), "Total\nPoints");
              }
            ),
          ),
          const SizedBox(width: 10),
          // --- UPDATED: Longest Streak ---
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: _userStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData || !snapshot.data!.exists) return _buildStatCard("0", "Longest\nStreak");
                final data = snapshot.data!.data() as Map<String, dynamic>;
                return _buildStatCard((data['longestStreak'] ?? 0).toString(), "Longest\nStreak");
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
            Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: statNumberColor)),
            const SizedBox(height: 5),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.3)),
          ],
        ),
      ),
    );
  }

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
            stream: _userStream, 
            builder: (context, snapshot) {
              if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: Text("Loading streak..."));
              
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
                      Icon(Icons.local_fire_department, color: activeColor, size: 48),
                      Text("$streak DAY${streak == 1 ? '' : 'S'}", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: activeColor)),
                    ],
                  ),
                  const VerticalDivider(thickness: 1, color: Colors.grey, width: 40, indent: 10, endIndent: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isCheckedInToday)
                          Row(children: const [Icon(Icons.check_circle, color: Colors.green, size: 28), SizedBox(width: 10), Expanded(child: Text("Check-in Complete!", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))]),
                        if (!isCheckedInToday)
                          Row(children: const [Icon(Icons.radio_button_unchecked, color: Colors.grey, size: 28), SizedBox(width: 10), Expanded(child: Text("Check-in today!", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))]),
                        const SizedBox(height: 8),
                        Text(isCheckedInToday ? "Great job! Your streak is safe." : "Log your mood or do an activity to build your streak.", style: TextStyle(color: Colors.grey.shade700, height: 1.4)),
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
              _buildTaskTile("Complete a Pop Quiz", "+50 pts", false),

              StreamBuilder<QuerySnapshot>(
                stream: _journalStream,
                builder: (context, snapshot) {
                  bool isDone = false;
                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                    final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                    final Timestamp? timestamp = data['timestamp'];
                    if (timestamp != null) {
                      final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
                      final String entryDate = DateFormat('yyyy-MM-dd').format(timestamp.toDate());
                      if (today == entryDate) {
                        isDone = true;
                      }
                    }
                  }
                  return _buildTaskTile("Write a journal entry", "+25 pts", isDone);
                }
              ),
              
              StreamBuilder<DocumentSnapshot>(
                stream: _userStream,
                builder: (context, snapshot) {
                  bool isDone = false;
                  if (snapshot.hasData && snapshot.data!.exists) {
                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    final String lastCheckIn = data['lastCheckInDate'] ?? '';
                    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
                    if (lastCheckIn == today) isDone = true;
                  }
                  return _buildTaskTile("Daily Check-in", "+25 pts", isDone);
                }
              ),

              StreamBuilder<QuerySnapshot>(
                stream: _dassStream,
                builder: (context, snapshot) {
                  bool isDone = false;
                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                    final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                    final Timestamp? timestamp = data['timestamp'];
                    if (timestamp != null) {
                      final DateTime lastDate = timestamp.toDate();
                      final int diff = DateTime.now().difference(lastDate).inDays;
                      if (diff < 7) isDone = true; 
                    }
                  }
                  return _buildTaskTile("Weekly: Take DASS-21", "+100 pts", isDone);
                }
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskTile(String title, String reward, bool isCompleted) {
    return ListTile(
      leading: Icon(isCompleted ? Icons.check_circle : Icons.radio_button_unchecked, color: isCompleted ? Colors.green : Colors.grey),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w500, decoration: isCompleted ? TextDecoration.lineThrough : null, color: isCompleted ? Colors.grey : Colors.black87)),
      trailing: Text(reward, style: TextStyle(fontWeight: FontWeight.bold, color: isCompleted ? Colors.grey : statNumberColor)),
    );
  }

  Widget _buildBottomNav() {
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
}