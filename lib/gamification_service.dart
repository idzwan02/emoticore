// In: lib/services/gamification_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/gamification_data.dart'; 

class GamificationService {
  
  // --- 1. NEW FUNCTION: Award Points ---
  static Future<void> awardPoints(User? user, int points) async {
    if (user == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'totalPoints': FieldValue.increment(points),
      });
      // After getting points, check if we unlocked any badges
      await checkBadges(user);
    } catch (e) {
      print("Error awarding points: $e");
    }
  }
  // --- END NEW FUNCTION ---

  static Future<void> checkBadges(User? user) async {
    if (user == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final doc = await userRef.get();
    
    if (!doc.exists) return;

    final data = doc.data()!;
    final int currentPoints = data['totalPoints'] ?? 0;
    final int currentStreak = data['currentStreak'] ?? 0;
    
    List<String> unlockedIds = List<String>.from(data['unlockedBadges'] ?? []);
    bool newBadgeUnlocked = false;

    for (var badge in allBadges) {
      if (unlockedIds.contains(badge.id)) continue;

      bool earned = false;
      if (badge.requiredPoints > 0 && currentPoints >= badge.requiredPoints) {
        earned = true;
      }
      if (badge.requiredStreak > 0 && currentStreak >= badge.requiredStreak) {
        earned = true;
      }

      if (earned) {
        unlockedIds.add(badge.id);
        newBadgeUnlocked = true;
        print("UNLOCKED BADGE: ${badge.name}");
      }
    }

    if (newBadgeUnlocked) {
      await userRef.update({
        'unlockedBadges': unlockedIds,
      });
    }
  }
}