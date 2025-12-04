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
import 'gamification_service.dart'; // <-- IMPORT NEW SERVICE
import 'gamification_data.dart'; // <-- IMPORT NEW DATA

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
  Stream<QuerySnapshot>? _moodboardStream;
  Stream<DocumentSnapshot>? _userStream;
  String _currentMoodId = 'neutral';

  // (Mood Maps Unchanged)
  final Map<String, String> _moodEmojis = {
    'happy': ' 😊 ', 'excited': ' 😃 ', 'neutral': ' 😐 ', 'anxious': ' 😟 ', 'sad': ' 😔 ',
  };
  final Map<String, String> _moodTexts = {
    'happy': 'Happy', 'excited': 'Excited', 'neutral': 'Neutral', 'anxious': 'Anxious', 'sad': 'Sad',
  };

  // (Colors Unchanged)
  static const Color appPrimaryColor = Color(0xFF5A9E9E);
  static const Color appBackgroundColor = Color(0xFFD2E9E9);
  static const Color statNumberColor = Color(0xFF4A69FF);
  static const Color goldBadgeColor = Color(0xFFD4AF37);
  static const Color redBadgeColor = Color(0xFFC70039);
  static const Color depressionBarColor = Color(0xFFEF5350);
  static const Color anxietyBarColor = Color(0xFFFFCA28);
  static const Color stressBarColor = Color(0xFF26C6DA);
  static const Color streakColor = Color(0xFFF08A00);

  // --- AVATAR MAP REMOVED (Imported from gamification_data.dart) ---

  @override
  void initState() {
    super.initState();
    _initializeDashboard();
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

  // (Daily Mood Check Unchanged)
  Future<void> _triggerDailyMoodCheck() async { /* ... */ }
  Future<void> _showMoodCheckDialog() async { /* ... */ }

  // (Save Mood Updated to check badges)
  Future<void> _saveMood(String moodId) async {
    if (mounted) setState(() => _currentMoodId = moodId);
    final prefs = await SharedPreferences.getInstance();
    final String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await prefs.setString('lastMoodCheckDate', todayDate);
    
    User user = widget.user; 
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid)
          .update({'currentMood': moodId, 'lastMoodUpdate': Timestamp.now()});
          
      await StreakService.updateDailyStreak(user);
      
      // --- ADDED: Check badges after streak update ---
      await GamificationService.checkBadges(user);
      // --- END ---
      
    } catch (e) {
      print("Error saving mood: $e");
    }
  }

  // (Create User Data Updated to include badge list)
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
          'lastCheckInDate': null,
          'unlockedBadges': [], // --- ADDED THIS ---
        });
      } catch (e) {
        print("Error creating user document: $e");
      }
    }
  }

  // (Load Mood Data Unchanged)
  Future<void> _loadMoodData() async { /* ... */ }

  // (Initialize Streams Unchanged)
  void _initializeStreams() {
    User user = widget.user;
    _dassStream = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('dass21_results').orderBy('timestamp', descending: true).limit(1).snapshots();
    _moodboardStream = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('moodboards').snapshots();
    _userStream = FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots();
  }

  // (Sign Out Unchanged)
  Future<void> _signOut() async { /* ... */ }

  // (Update Avatar Unchanged - Note: Uses masterAvatarAssets now)
  Future<void> _updateSelectedAvatarId(String newAvatarId) async { 
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null || !masterAvatarAssets.containsKey(newAvatarId)) return; // Use master map
    setState(() => _isSavingAvatar = true); 
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'selectedAvatarId': newAvatarId},
      );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Avatar updated!'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update avatar.'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSavingAvatar = false); 
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
        // --- Use Imported Master Map ---
        availableAvatarAssets: masterAvatarAssets, 
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: _buildBottomNav(),
    );
  }
  
  // (Build Home Page Unchanged)
  Widget _buildHomePage() { /* ... Same as before ... */
    return Scaffold(
      key: const ValueKey<String>('home_page'),
      backgroundColor: appBackgroundColor,
      body: _isLoadingData
          ? Center(child: Lottie.asset('assets/animations/loading.json', width: 150, height: 150))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  _buildSectionTitle("Your Badges"),
                  _buildBadgesSection(), // <-- This is updated below
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

  // (Header Unchanged - Uses masterAvatarAssets)
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
              // Use master map
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

  // --- UPDATED: Dynamic Badges Section ---
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
              // Get list of unlocked IDs
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
                  // Find the badge data from our master list
                  final badge = allBadges.firstWhere(
                    (b) => b.id == id, 
                    orElse: () => allBadges[0] // Fallback
                  );
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

  // (Section Title, Stats, Bar Chart, Tasks, etc. are UNCHANGED)
  Widget _buildSectionTitle(String title) { return Padding(padding: const EdgeInsets.fromLTRB(20, 25, 20, 10), child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87))); }
  Widget _buildStatisticsSection() { /* ... Same as previous version ... */ return Container(); /* Placeholder to keep response short */ } 
  // IMPORTANT: You should keep the _buildStatisticsSection from the previous full code. I'm omitting it here purely to save space, but it hasn't changed.
  
  // (Stats Cards - Logic remains the same, just removed the placeholder)
  Widget _buildStatsCardsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        children: [
          // --- UPDATED: Live Badge Count ---
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
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _moodboardStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return _buildStatCard("0", "Moodboard\nCreated");
                return _buildStatCard(snapshot.data!.docs.length.toString(), "Moodboard\nCreated");
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
            stream: _userStream, 
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

  // --- UPDATED WIDGET FOR TASKS ---
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
              // Task 1: Pop Quiz (Static for now, but encouraging)
              _buildTaskTile(
                "Complete a Pop Quiz", 
                "+50 pts", 
                false
              ),
              
              // Task 2: Journal / Check-in (Dynamic via User Stream)
              StreamBuilder<DocumentSnapshot>(
                stream: _userStream,
                builder: (context, snapshot) {
                  bool isDone = false;
                  if (snapshot.hasData && snapshot.data!.exists) {
                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    final String lastCheckIn = data['lastCheckInDate'] ?? '';
                    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
                    if (lastCheckIn == today) {
                      isDone = true;
                    }
                  }
                  return _buildTaskTile(
                    "Daily Check-in", 
                    "+25 pts", 
                    isDone
                  );
                }
              ),

              // Task 3: DASS-21 (Dynamic via DASS Stream)
              // --- THIS IS THE CRITICAL FIX ---
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
                      
                      // If it's been LESS than 7 days, it's considered "Done" for the week.
                      if (diff < 7) {
                        isDone = true;
                      }
                    }
                  }
                  
                  return _buildTaskTile(
                    "Weekly: Take DASS-21", 
                    "+100 pts", 
                    isDone
                  );
                }
              ),
              // --- END FIX ---
            ],
          ),
        ),
      ),
    );
  }

  // Helper for the new tasks section
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