import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medilink/features/auth/providers/auth_providers.dart';
import 'package:medilink/features/notifications/data/notification_center_repository.dart';
import 'package:medilink/features/notifications/domain/entities/app_notification.dart';

final notificationCenterRepositoryProvider = Provider<NotificationCenterRepository>(
  (ref) => NotificationCenterRepository(),
);

final notificationCenterProvider = StreamProvider.autoDispose<List<AppNotification>>((ref) {
  final uid = ref.watch(authStateChangesProvider).valueOrNull?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(notificationCenterRepositoryProvider).watchNotifications(uid);
});

final unreadNotificationCountProvider = Provider.autoDispose<int>((ref) {
  final notifications = ref.watch(notificationCenterProvider).valueOrNull ?? const [];
  return notifications.where((n) => !n.isRead).length;
});
