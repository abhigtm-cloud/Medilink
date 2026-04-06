import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medilink/core/theme/app_theme.dart';
import 'package:medilink/core/services/email_service.dart';
import 'package:medilink/core/services/cache_service.dart';
import 'package:medilink/features/auth/providers/auth_providers.dart';
import 'package:medilink/features/auth/screens/login_screen.dart';
import 'package:medilink/features/home/screens/home_screen_wrapper.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Mobile-only app - uses native Firebase SDK for iOS/Android
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Add sample hospitals if database is empty
  await _addSampleHospitalsIfNeeded();

  // Initialize OFFLINE-FIRST caching service
  // Data persists indefinitely even when system is OFF or on different network
  await CacheService.initialize();
  print('DEBUG: 📱 MOBILE-FIRST APP - Offline persistence enabled');

  // Initialize EmailJS for sending booking confirmations
  await EmailService.initialize();

  runApp(const ProviderScope(child: MedilinkApp()));
}

/// Adds sample hospital data to Firebase if none exists
Future<void> _addSampleHospitalsIfNeeded() async {
  try {
    final db = FirebaseDatabase.instance.ref();
    final snapshot = await db.child('hospitals').get();
    
    if (!snapshot.exists) {
      print('DEBUG: 🏥 Adding sample hospitals to Firebase...');
      
      await db.child('hospitals').set({
        'hospital_1': {
          'name': 'City Medical Hospital',
          'address': '123 Main Street, Downtown District',
          'contact': '+92-300-1234567',
          'adminId': 'sample-admin-001',
          'photoUrl': '',
          'createdAt': DateTime.now().toIso8601String(),
        },
        'hospital_2': {
          'name': 'Green Valley Medical Center',
          'address': '456 Park Avenue, Suburb Area',
          'contact': '+92-300-7654321',
          'adminId': 'sample-admin-002',
          'photoUrl': '',
          'createdAt': DateTime.now().toIso8601String(),
        },
        'hospital_3': {
          'name': 'Wellness Clinic & Diagnostic Center',
          'address': '789 Health Road, Medical Complex',
          'contact': '+92-300-9876543',
          'adminId': 'sample-admin-003',
          'photoUrl': '',
          'createdAt': DateTime.now().toIso8601String(),
        },
        'hospital_4': {
          'name': 'Emergency Care Hospital',
          'address': '321 Relief Lane, City Center',
          'contact': '+92-300-5555555',
          'adminId': 'sample-admin-004',
          'photoUrl': '',
          'createdAt': DateTime.now().toIso8601String(),
        },
      });
      
      print('DEBUG: ✅ Sample hospitals added successfully!');
    } else {
      print('DEBUG: 📊 Hospitals data already exists in Firebase');
    }
  } catch (e) {
    print('DEBUG: ⚠️ Error adding sample hospitals: $e');
    // Don't block app startup if this fails
  }
}


/// Root widget for the MEDILINK application.
class MedilinkApp extends ConsumerWidget {
  const MedilinkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStream = ref.watch(authStateChangesProvider);

    return MaterialApp(
      title: 'MEDILINK',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: authStream.when(
        data: (user) {
          if (user == null) {
            return const LoginScreen();
          }
          return const HomeScreen();
        },
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (e, st) => Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Error'),
                const SizedBox(height: 16),
                Text('$e'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(authStateChangesProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

