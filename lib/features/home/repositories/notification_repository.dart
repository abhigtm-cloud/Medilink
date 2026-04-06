import 'package:firebase_database/firebase_database.dart';
import 'package:medilink/features/home/models/notification.dart' as notify;

/// Repository for notification-related operations
class NotificationRepository {
  final _database = FirebaseDatabase.instance.ref();

  static const String _notificationsPath = 'notifications';

  /// Create a new notification (e.g., when a booking is made)
  Future<notify.Notification> createNotification(
      notify.Notification notification) async {
    try {
      final ref = _database.child(_notificationsPath).child(notification.userId).push();

      await ref.set(notification.toJson());

      return notification.copyWith(id: ref.key);
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  /// Get all notifications for a user
  Future<List<notify.Notification>> getNotificationsForUser(String userId) async {
    try {
      final snapshot =
          await _database.child(_notificationsPath).child(userId).get();

      if (!snapshot.exists) {
        return [];
      }

      final notifications = <notify.Notification>[];
      final data = snapshot.value as Map<dynamic, dynamic>? ?? {};

      data.forEach((key, value) {
        if (value is Map<dynamic, dynamic>) {
          final notification = notify.Notification.fromJson(
            Map<String, dynamic>.from(value),
            docId: key,
          );
          notifications.add(notification);
        }
      });

      // Sort by creation date (newest first)
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return notifications;
    } catch (e) {
      throw Exception('Failed to fetch notifications: $e');
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String userId, String notificationId) async {
    try {
      await _database
          .child(_notificationsPath)
          .child(userId)
          .child(notificationId)
          .update({'isRead': true});
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String userId, String notificationId) async {
    try {
      await _database
          .child(_notificationsPath)
          .child(userId)
          .child(notificationId)
          .remove();
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  /// Get unread notification count for a user
  Future<int> getUnreadCount(String userId) async {
    try {
      final notifications = await getNotificationsForUser(userId);
      return notifications.where((n) => !n.isRead).length;
    } catch (e) {
      print('DEBUG: Error getting unread count: $e');
      return 0;
    }
  }
}
