// In: lib/profile_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

class ProfilePage extends StatefulWidget {
  // --- 1. Parameters passed from Dashboard ---
  final String userName;
  final String selectedAvatarId;
  final Map<String, String> availableAvatarAssets;
  final Function(String) onAvatarSelected; // Callback function
  final bool isSavingAvatar;
  final VoidCallback onChangeAccount; // <-- 2. ADD THIS CALLBACK
  // --- 3. UPDATED CONSTRUCTOR ---
  const ProfilePage({
    super.key,
    required this.userName,
    required this.selectedAvatarId,
    required this.availableAvatarAssets,
    required this.onAvatarSelected,
    required this.isSavingAvatar,
    required this.onChangeAccount, // <-- 4. ADD THIS TO CONSTRUCTOR
  });
  // --- End Parameters ---
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Define theme colors
  static const Color appPrimaryColor = Color(0xFF5A9E9E);
  static const Color appBackgroundColor = Color(0xFFD2E9E9);
  // State Variables for this page ONLY
  String _email = 'Loading...';
  String _dateOfBirth = 'Loading...';
  String _joinedDate = 'Loading...';
  bool _isLoadingProfileData = true;
  @override
  void initState() {
    super.initState();
    // Fetch data that is *only* for the profile page
    _loadProfileDetails();
  }

  // Fetches data NOT already passed in (DOB, Joined Date, Email)
  Future<void> _loadProfileDetails() async {
    if (!mounted) return;
    setState(() => _isLoadingProfileData = true);
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _email = user.email ?? 'No email'; // Set email from Auth

      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists && userDoc.data() != null) {
          Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
          _dateOfBirth = data['dateOfBirth'] ?? 'Not set';
          Timestamp? joinedTimestamp = data['joinedAt'];
          if (joinedTimestamp != null) {
            _joinedDate =
                DateFormat('MMMM d, yyyy').format(joinedTimestamp.toDate());
          } else {
            _joinedDate = 'Unknown';
          }
        } else {
          _dateOfBirth = 'Not set';
          _joinedDate = 'Unknown';
        }
      } catch (e) {
        print("Error loading profile details: $e");
        _dateOfBirth = 'Error';
        _joinedDate = 'Error';
      } finally {
        if (mounted) setState(() => _isLoadingProfileData = false);
      }
    } else {
      if (mounted)
        setState(() {
          _email = 'Not logged in';
          _dateOfBirth = '-';
          _joinedDate = '-';
          _isLoadingProfileData = false;
        });
    }
  }

  // Avatar Selection Dialog
  void _showAvatarSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Select Avatar"),
          content: SingleChildScrollView(
            child: Wrap(
              spacing: 10.0,
              runSpacing: 10.0,
              alignment: WrapAlignment.center,
              // Use map from WIDGET
              children: widget.availableAvatarAssets.entries.map((entry) {
                final String avatarId = entry.key;
                final String assetPath = entry.value;
                // Use selected ID from WIDGET
                bool isSelected = widget.selectedAvatarId == avatarId;
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    // Call CALLBACK FUNCTION from WIDGET
                    widget.onAvatarSelected(avatarId);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: isSelected
                        ? BoxDecoration(
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: appPrimaryColor, width: 3),
                          )
                        : null,
                    child: CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: AssetImage(assetPath),
                      onBackgroundImageError: (e, s) {
                        print("Error loading asset in dialog: $assetPath");
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get asset path using ID from WIDGET
    String displayAvatarPath =
        widget.availableAvatarAssets[widget.selectedAvatarId] ??
            widget.availableAvatarAssets['default']!;
    return Scaffold(
      backgroundColor: appBackgroundColor,
      appBar: AppBar(
        backgroundColor: appPrimaryColor,
        title: const Text('Profile',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
        elevation: 1.0,
        actions: [
          // --- 5. UPDATED Button ---
          TextButton.icon(
            icon: const Icon(Icons.logout, color: Colors.white), // Using 'logout' icon
            label: const Text("Log Out",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: widget.onChangeAccount, // Call the function from parent
            style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16.0)),
          ),
          // --- END UPDATE ---
        ],
      ),
      body: _isLoadingProfileData
          ? Center(
              child: Lottie.asset(
                'assets/animations/loading.json',
                width: 150,
                height: 150,
              ),
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _showAvatarSelectionDialog,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 80,
                            backgroundColor: Colors.grey.shade300,
                            backgroundImage: AssetImage(displayAvatarPath),
                            onBackgroundImageError: (e, s) {
                              print(
                                  "Error loading main profile asset: $displayAvatarPath");
                            },
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: appPrimaryColor.withOpacity(0.8),
                              child: const Icon(Icons.edit,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                          if (widget.isSavingAvatar)
                            Center(
                              child: Lottie.asset(
                                'assets/animations/loading.json',
                                width: 80,
                                height: 80,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      widget.userName,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Column(
                      children: [
                        Text(
                          _email,
                          style: TextStyle(
                              fontSize: 16, color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cake_outlined,
                                color: Colors.grey.shade600, size: 18),
                            const SizedBox(width: 8),
                            Text('Born: $_dateOfBirth',
                                style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey.shade700)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.calendar_today_outlined,
                                color: Colors.grey.shade600, size: 16),
                            const SizedBox(width: 8),
                            Text('Joined: $_joinedDate',
                                style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey.shade700)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}