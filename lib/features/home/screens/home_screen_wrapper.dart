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
    // Get the current authenticated user directly
    final authState = ref.watch(authStateChangesProvider);

    // Since we only reach here when user is not null (from main.dart),
    // we can safely use the data
    return authState.when(
      data: (user) {
        if (user == null) {
          // This shouldn't happen, but handle it just in case
          return const Scaffold(
            body: Center(child: Text('User not authenticated')),
          );
        }

        print('DEBUG: HomeScreen - User = ${user.email}, Role = ${user.role.displayName}');

        // Route based on user role
        if (user.role.isHospitalAdmin) {
          print('DEBUG: Routing to AdminDashboardScreen');
          return const AdminDashboardScreen();
        } else {
          print('DEBUG: Routing to UserHomeScreen');
          return const UserHomeScreen();
        }
      },
      loading: () {
        print('DEBUG: HomeScreen loading...');
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
      error: (error, st) {
        print('DEBUG: HomeScreen error: $error');
        return Scaffold(
          body: Center(child: Text('Error: $error')),
        );
      },
    );
  }
}
