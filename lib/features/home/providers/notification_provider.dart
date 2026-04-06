import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medilink/features/home/models/notification.dart';
import 'package:medilink/features/home/repositories/notification_repository.dart';
import 'package:medilink/features/auth/providers/auth_providers.dart';

final notificationRepositoryProvider = Provider((ref) {
  return NotificationRepository();
});

/// Get all notifications for the current user
final getUserNotificationsProvider = FutureProvider<List<Notification>>((ref) async {
  final authState = ref.watch(authStateChangesProvider);
  
  return authState.when(
    data: (user) async {
      if (user == null) return [];
      
      final repo = ref.watch(notificationRepositoryProvider);
      return repo.getNotificationsForUser(user.uid);
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Get unread notification count
final getUnreadCountProvider = FutureProvider<int>((ref) async {
  final authState = ref.watch(authStateChangesProvider);
  
  return authState.when(
    data: (user) async {
      if (user == null) return 0;
      
      final repo = ref.watch(notificationRepositoryProvider);
      return repo.getUnreadCount(user.uid);
    },
    loading: () => 0,
    error: (_, __) => 0,
  );
});
