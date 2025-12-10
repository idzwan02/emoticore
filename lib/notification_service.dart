// In: lib/services/notification_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';


class NotificationService {
  
  // Add a notification to the user's collection
  static Future<void> addNotification({
    required String uid,
    required String title,
    required String body,
    String type = 'system', // 'badge', 'avatar', 'system'
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .add({
        'title': title,
        'body': body,
        'type': type,
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error adding notification: $e");
    }
  }

  // Mark a specific notification as read
  static Future<void> markAsRead(String uid, String notificationId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  // Mark ALL as read (Optional helper)
  static Future<void> markAllAsRead(String uid) async {
    final batch = FirebaseFirestore.instance.batch();
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}