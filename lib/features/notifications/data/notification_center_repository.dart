import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medilink/features/notifications/domain/entities/app_notification.dart';

/// Plain Firestore-backed repository — kept as a single class rather than
/// the full Clean Architecture split (domain/data/datasource) used by the
/// emergency/command_center/ambulance features, since this is read-mostly
/// with one simple write (mark-as-read) and no offline/Callable-Function
/// concerns to justify the extra layers. Same precedent as
/// core/services/staff_role_service.dart.
class NotificationCenterRepository {
  NotificationCenterRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<AppNotification>> watchNotifications(String uid) {
    return _firestore
        .collection('notifications')
        .doc(uid)
        .collection('items')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map(_fromFirestore).toList());
  }

  Future<void> markAsRead(String uid, String notificationId) {
    return _firestore
        .collection('notifications')
        .doc(uid)
        .collection('items')
        .doc(notificationId)
        .update({'isRead': true});
  }

  AppNotification _fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return AppNotification(
      id: doc.id,
      type: AppNotificationType.fromValue(data['type'] as String?),
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      data: (data['data'] as Map?)?.cast<String, dynamic>() ?? const {},
      isRead: data['isRead'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
