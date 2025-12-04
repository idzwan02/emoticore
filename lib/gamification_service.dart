// In: lib/services/gamification_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../gamification_data.dart'; // Import the data we just made

class GamificationService {
  
  static Future<void> checkBadges(User? user) async {
    if (user == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final doc = await userRef.get();
    
    if (!doc.exists) return;

    final data = doc.data()!;
    final int currentPoints = data['totalPoints'] ?? 0;
    final int currentStreak = data['currentStreak'] ?? 0;
    
    // Get list of badges user ALREADY has
    // (We cast to List<dynamic> then map to String to be safe)
    List<String> unlockedIds = List<String>.from(data['unlockedBadges'] ?? []);

    bool newBadgeUnlocked = false;

    // Check every defined badge
    for (var badge in allBadges) {
      // If user already has it, skip
      if (unlockedIds.contains(badge.id)) continue;

      bool earned = false;

      // Check Point Requirement
      if (badge.requiredPoints > 0 && currentPoints >= badge.requiredPoints) {
        earned = true;
      }
      
      // Check Streak Requirement
      if (badge.requiredStreak > 0 && currentStreak >= badge.requiredStreak) {
        earned = true;
      }

      if (earned) {
        unlockedIds.add(badge.id);
        newBadgeUnlocked = true;
        // Ideally, you'd show a "Badge Unlocked!" notification here, 
        // but for now we just save it silently.
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