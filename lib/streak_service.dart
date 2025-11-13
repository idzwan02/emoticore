// In: lib/services/streak_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class StreakService {
  
  // This function can be called from anywhere in the app
  static Future<void> updateDailyStreak(User? user) async {
    if (user == null) return; // Not logged in

    try {
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Get the user's current data
      final doc = await userDocRef.get();
      if (!doc.exists) return; // User doc doesn't exist yet

      final data = doc.data() as Map<String, dynamic>;
      final String lastCheckIn = data['lastCheckInDate'] ?? '';
      final int currentStreak = data['currentStreak'] ?? 0;

      // --- 1. Check if user already checked in today ---
      if (lastCheckIn == today) {
        print("Streak already updated today.");
        return; // Already checked in today
      }

      // --- 2. Check if the streak is continuing ---
      final String yesterday = DateFormat('yyyy-MM-dd')
          .format(DateTime.now().subtract(const Duration(days: 1)));

      if (lastCheckIn == yesterday) {
        // Streak continues!
        await userDocRef.update({
          'currentStreak': currentStreak + 1,
          'lastCheckInDate': today,
        });
        print("Streak continued! New streak: ${currentStreak + 1}");
      } else {
        // Streak is broken or just starting
        await userDocRef.update({
          'currentStreak': 1, // Reset to 1
          'lastCheckInDate': today,
        });
        print("Streak reset to 1.");
      }
    } catch (e) {
      print("Error updating daily streak: $e");
      // Fail silently, don't crash the app
    }
  }
}