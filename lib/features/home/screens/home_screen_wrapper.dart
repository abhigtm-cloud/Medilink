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
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('Not authenticated')),
          );
        }

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
