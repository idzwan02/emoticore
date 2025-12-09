// In: lib/profile_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'edit_profile_page.dart';
import 'custom_page_route.dart';

class ProfilePage extends StatefulWidget {
  final Stream<DocumentSnapshot>? userStream;
  final Map<String, String> availableAvatarAssets;
  final VoidCallback onChangeAccount;

  const ProfilePage({
    super.key,
    required this.userStream,
    required this.availableAvatarAssets,
    required this.onChangeAccount,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const Color appPrimaryColor = Color(0xFF5A9E9E);
  static const Color appBackgroundColor = Color(0xFFD2E9E9);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackgroundColor,
      appBar: AppBar(
        backgroundColor: appPrimaryColor,
        title: const Text('Profile',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
        elevation: 1.0,
        actions: [
          StreamBuilder<DocumentSnapshot>(
            stream: widget.userStream,
            builder: (context, snapshot) {
              // Default values
              String name = 'User';
              String dob = 'Not set';
              String avatarId = 'default';
              int totalPoints = 0;
              String mantra = "One day at a time.";

              if (snapshot.hasData && snapshot.data!.exists) {
                final data = snapshot.data!.data() as Map<String, dynamic>;
                name = data['name'] ?? 'User';
                dob = data['dateOfBirth'] ?? 'Not set';
                avatarId = data['selectedAvatarId'] ?? 'default';
                totalPoints = data['totalPoints'] ?? 0;
                mantra = data['mantra'] ?? "One day at a time.";
              }

              return IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                tooltip: 'Edit Profile',
                onPressed: () {
                  Navigator.push(
                    context,
                    FadeRoute(
                      page: EditProfilePage(
                        currentName: name,
                        currentDob: dob,
                        currentAvatarId: avatarId,
                        currentMantra: mantra,
                        availableAvatarAssets: widget.availableAvatarAssets,
                        userTotalPoints: totalPoints,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: widget.userStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return Center(
              child: Lottie.asset('assets/animations/loading.json',
                  width: 150, height: 150),
            );
          }
          if (!snapshot.hasData || snapshot.data == null || !snapshot.data!.exists) {
            return const Center(child: Text("User data not found. Please log out and log in again."));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final String name = data['name'] ?? 'User';
          final String email = data['email'] ?? 'No email';
          final String dob = data['dateOfBirth'] ?? 'Not set';
          final String currentAvatarId = data['selectedAvatarId'] ?? 'default';
          final String mantra = data['mantra'] ?? 'One day at a time.';

          String joinedDate = 'Unknown';
          Timestamp? joinedTimestamp = data['joinedAt'];
          if (joinedTimestamp != null) {
            joinedDate =
                DateFormat('MMMM d, yyyy').format(joinedTimestamp.toDate());
          }

          String displayAvatarPath =
              widget.availableAvatarAssets[currentAvatarId] ??
                  widget.availableAvatarAssets['default']!;

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                
                CircleAvatar(
                  radius: 80,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: AssetImage(displayAvatarPath),
                ),
                
                const SizedBox(height: 24),
                Text(
                  name, 
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: appPrimaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '"$mantra"',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14, 
                      fontStyle: FontStyle.italic,
                      color: appPrimaryColor,
                      fontWeight: FontWeight.w600
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Column(
                  children: [
                    Text(
                      email, 
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
                        Text('Born: $dob',
                            style: TextStyle(
                                fontSize: 15, color: Colors.grey.shade700)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            color: Colors.grey.shade600, size: 16),
                        const SizedBox(width: 8),
                        Text('Joined: $joinedDate',
                            style: TextStyle(
                                fontSize: 15, color: Colors.grey.shade700)),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                
                OutlinedButton.icon(
                  icon: Icon(Icons.logout, color: Colors.red.shade700),
                  label: Text(
                    "Switch Account (Log Out)",
                    style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold),
                  ),
                  onPressed: widget.onChangeAccount,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    backgroundColor: Colors.white.withOpacity(0.5),
                    side: BorderSide(color: Colors.grey.shade400),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}