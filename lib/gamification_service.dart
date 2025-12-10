// In: lib/services/gamification_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../gamification_data.dart'; 
import 'notification_service.dart';

class GamificationService {
  
  static Future<void> awardPoints(User? user, int points) async {
    if (user == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'totalPoints': FieldValue.increment(points),
      });
      await checkAchievements(user); // Renamed for clarity
    } catch (e) {
      print("Error awarding points: $e");
    }
  }

  // Formerly "checkBadges", now checks everything
  static Future<void> checkBadges(User? user) async {
    await checkAchievements(user);
  }

  static Future<void> checkAchievements(User? user) async {
    if (user == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final doc = await userRef.get();
    
    if (!doc.exists) return;

    final data = doc.data()!;
    final int currentPoints = data['totalPoints'] ?? 0;
    final int currentStreak = data['currentStreak'] ?? 0;
    
    bool needsUpdate = false;

    // --- 1. CHECK BADGES ---
    List<String> unlockedBadges = List<String>.from(data['unlockedBadges'] ?? []);
    
    for (var badge in allBadges) {
      if (unlockedBadges.contains(badge.id)) continue;

      bool earned = false;
      if (badge.requiredPoints > 0 && currentPoints >= badge.requiredPoints) earned = true;
      if (badge.requiredStreak > 0 && currentStreak >= badge.requiredStreak) earned = true;

      if (earned) {
        unlockedBadges.add(badge.id);
        needsUpdate = true;
        
        await NotificationService.addNotification(
          uid: user.uid,
          title: "New Badge Unlocked!",
          body: "You've earned the '${badge.name}' badge. Great job!",
          type: 'badge',
        );
      }
    }

    // --- 2. CHECK AVATARS ---
    List<String> unlockedAvatars = List<String>.from(data['unlockedAvatars'] ?? []);
    
    // Iterate through all rules in gamification_data.dart
    avatarUnlockThresholds.forEach((avatarId, cost) {
      // If we don't have it yet AND we have enough points
      if (!unlockedAvatars.contains(avatarId) && currentPoints >= cost) {
        
        unlockedAvatars.add(avatarId);
        needsUpdate = true;

        // Only notify if it was a "Paid" avatar (cost > 0)
        // We don't want to spam notifications for the default free ones
        if (cost > 0) {
          // Capitalize first letter for display
          String name = avatarId[0].toUpperCase() + avatarId.substring(1);
          
          NotificationService.addNotification(
            uid: user.uid,
            title: "New Avatar Unlocked!",
            body: "You unlocked the '$name' avatar. Go to Profile to equip it!",
            type: 'avatar',
          );
        }
      }
    });

    // --- 3. SAVE UPDATES ---
    if (needsUpdate) {
      await userRef.update({
        'unlockedBadges': unlockedBadges,
        'unlockedAvatars': unlockedAvatars,
      });
    }
  }
}