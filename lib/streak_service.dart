// In: lib/services/streak_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class StreakService {
  
  static Future<void> updateDailyStreak(User? user) async {
    if (user == null) return;

    try {
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final doc = await userDocRef.get();
      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;
      final String lastCheckIn = data['lastCheckInDate'] ?? '';
      final int currentStreak = data['currentStreak'] ?? 0;
      final int currentLongest = data['longestStreak'] ?? 0; // Get existing longest

      // 1. If already checked in today, do nothing
      if (lastCheckIn == today) {
        return; 
      }

      // 2. Check if streak continues
      final String yesterday = DateFormat('yyyy-MM-dd')
          .format(DateTime.now().subtract(const Duration(days: 1)));

      int newStreak = 1; // Default reset
      if (lastCheckIn == yesterday) {
        newStreak = currentStreak + 1;
      }

      // 3. Calculate new Longest Streak
      int newLongest = currentLongest;
      if (newStreak > currentLongest) {
        newLongest = newStreak;
      }

      // 4. Update Everything (Streak, Date, Points, Longest)
      await userDocRef.update({
        'currentStreak': newStreak,
        'lastCheckInDate': today,
        'longestStreak': newLongest, // Save longest
        'totalPoints': FieldValue.increment(25), // Award 25 pts for check-in
      });
      
    } catch (e) {
      print("Error updating daily streak: $e");
    }
  }
}