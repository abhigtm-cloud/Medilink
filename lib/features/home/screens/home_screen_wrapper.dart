import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medilink/features/auth/providers/auth_providers.dart';
import 'package:medilink/features/auth/models/app_user.dart';
import 'package:medilink/features/home/screens/admin_dashboard_screen.dart';
import 'package:medilink/features/home/screens/user_home_screen.dart';

/// Role-based home screen that routes to admin or user home
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStream = ref.watch(authStateChangesProvider);

    return authStream.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('User not authenticated')),
          );
        }

        print('DEBUG: User = ${user.email}, Role = ${user.role.displayName}');

        // Route based on user role
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
