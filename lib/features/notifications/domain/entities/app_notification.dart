/// A single item from `notifications/{uid}/items` — the Firestore-backed,
/// reliable fallback for push (see functions/src/notifications/sendFcm.ts
/// and architecture doc §16). Distinct from the legacy RTDB
/// `notifications`/`Notification` model used by the appointments feature.
enum AppNotificationType {
  emergency,
  ambulance,
  pharmacy,
  system;

  static AppNotificationType fromValue(String? value) {
    return AppNotificationType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => AppNotificationType.system,
    );
  }
}

class AppNotification {
  final String id;
  final AppNotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.data = const {},
    this.isRead = false,
    this.createdAt,
  });

  /// The `requestId` deep-link target, if this notification has one.
  String? get requestId => data['requestId'] as String?;
}
