// In: lib/notifications_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'notification_service.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  static const Color appPrimaryColor = Color(0xFF5A9E9E);
  static const Color appBackgroundColor = Color(0xFFD2E9E9);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold();

    return Scaffold(
      backgroundColor: appBackgroundColor,
      appBar: AppBar(
        backgroundColor: appPrimaryColor,
        title: const Text("Notifications", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: Colors.white),
            tooltip: "Mark all as read",
            onPressed: () => NotificationService.markAllAsRead(user.uid),
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text("No notifications yet.", style: TextStyle(color: Colors.grey)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final String id = docs[index].id;
              final String title = data['title'] ?? 'Notification';
              final String body = data['body'] ?? '';
              final String type = data['type'] ?? 'system';
              final bool isRead = data['isRead'] ?? false;
              final Timestamp? ts = data['timestamp'];
              
              String timeStr = '';
              if (ts != null) {
                timeStr = DateFormat('MMM d, h:mm a').format(ts.toDate());
              }

              IconData icon;
              Color iconColor;
              if (type == 'badge') {
                icon = Icons.emoji_events;
                iconColor = Colors.orange;
              } else if (type == 'avatar') {
                icon = Icons.face;
                iconColor = Colors.blue;
              } else {
                icon = Icons.info;
                iconColor = Colors.grey;
              }

              return Card(
                color: isRead ? Colors.white : Colors.white,
                elevation: isRead ? 1 : 3,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: isRead ? BorderSide.none : const BorderSide(color: appPrimaryColor, width: 1.5),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: iconColor.withOpacity(0.1),
                    child: Icon(icon, color: iconColor),
                  ),
                  title: Text(title, style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(body),
                      const SizedBox(height: 6),
                      Text(timeStr, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                    ],
                  ),
                  onTap: () {
                    if (!isRead) {
                      NotificationService.markAsRead(user.uid, id);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}