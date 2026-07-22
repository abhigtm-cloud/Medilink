import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medilink/core/services/rbac_service.dart';
import 'package:medilink/features/auth/providers/auth_providers.dart';
import 'package:medilink/features/auth/models/app_user.dart';
import 'package:medilink/features/home/screens/admin_dashboard_screen.dart';
import 'package:medilink/features/home/screens/user_home_screen.dart';
import 'package:medilink/features/ambulance/presentation/screens/ambulance_driver_home_screen.dart';

/// Role-based home screen that routes to admin, ambulance-driver, or user
/// home. Only `hospital_admin` (old email-domain convention) and
/// `ambulance_driver` (new custom-claim RBAC) have dedicated shells so far —
/// doctor/pharmacy/emergency_staff land on UserHomeScreen for now, same as
/// any patient, since they have no dedicated screens yet.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);
    final appRoleAsync = ref.watch(currentAppRoleProvider);

    // Registers/refreshes this device's FCM token and (for hospital staff)
    // subscribes to the hospital's emergency topic, once per role
    // resolution. See lib/core/services/fcm_service.dart.
    ref.listen<AsyncValue<AppRole>>(currentAppRoleProvider, (previous, next) {
      next.whenData((role) async {
        if (role == AppRole.unknown) return;
        final hospitalId = await ref.read(currentHospitalIdProvider.future);
        await ref.read(fcmServiceProvider).syncForRole(role, hospitalId);
      });
    });

    return authState.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('Not authenticated')),
          );
        }

        if (appRoleAsync.valueOrNull == AppRole.ambulanceDriver) {
          return const AmbulanceDriverHomeScreen();
        }

        // Route based on role
        if (user.role.isHospitalAdmin) {
          return const AdminDashboardScreen();
        } else {
          return const UserHomeScreen();
        }
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, st) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
    );
  }
}
