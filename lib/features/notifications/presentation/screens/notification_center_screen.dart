import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/features/auth/providers/auth_providers.dart';
import 'package:medilink/features/command_center/presentation/screens/emergency_detail_screen.dart';
import 'package:medilink/features/emergency/presentation/screens/emergency_tracking_screen.dart';
import 'package:medilink/features/notifications/domain/entities/app_notification.dart';
import 'package:medilink/features/notifications/presentation/providers/notification_center_providers.dart';

/// Firestore-backed alerts for the emergency platform (emergency status
/// changes, ambulance dispatch, etc.) — separate from the legacy RTDB
/// `NotificationsScreen` used for bookings. See architecture doc §16.
class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationCenterProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(title: const Text('Notifications')),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: AppColors.textTertiaryLight),
                  const SizedBox(height: 16),
                  const Text('No notifications yet'),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _NotificationTile(notification: notifications[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Unable to load: $error')),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.notification});

  final AppNotification notification;

  IconData get _icon {
    switch (notification.type) {
      case AppNotificationType.emergency:
        return Icons.emergency;
      case AppNotificationType.ambulance:
        return Icons.local_shipping;
      case AppNotificationType.pharmacy:
        return Icons.medication;
      case AppNotificationType.system:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      color: notification.isRead ? AppColors.cardLight : AppColors.primary.withOpacity(0.08),
      child: ListTile(
        leading: Icon(_icon, color: AppColors.primary),
        title: Text(notification.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(notification.body),
        trailing: notification.isRead
            ? null
            : Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              ),
        onTap: () => _handleTap(context, ref),
      ),
    );
  }

  Future<void> _handleTap(BuildContext context, WidgetRef ref) async {
    final uid = ref.read(authStateChangesProvider).valueOrNull?.uid;
    if (uid != null && !notification.isRead) {
      await ref.read(notificationCenterRepositoryProvider).markAsRead(uid, notification.id);
    }

    final requestId = notification.requestId;
    if (requestId == null) return;
    if (!context.mounted) return;

    final role = await ref.read(currentAppRoleProvider.future);
    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => role.isHospitalStaff
            ? EmergencyDetailScreen(requestId: requestId)
            : EmergencyTrackingScreen(requestId: requestId),
      ),
    );
  }
}
