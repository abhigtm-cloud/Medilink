import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medilink/core/theme/app_theme.dart';
import 'package:medilink/core/services/email_service.dart';
import 'package:medilink/core/services/cache_service.dart';
import 'package:medilink/features/auth/providers/auth_providers.dart';
import 'package:medilink/features/auth/screens/login_screen.dart';
import 'package:medilink/features/command_center/presentation/screens/emergency_detail_screen.dart';
import 'package:medilink/features/emergency/presentation/screens/emergency_tracking_screen.dart';
import 'package:medilink/features/home/screens/home_screen_wrapper.dart';
import 'firebase_options.dart';

/// Pushed to from a deep-linked notification tap when no other navigator
/// context is available. See [_MedilinkAppState._openDeepLink].
final navigatorKey = GlobalKey<NavigatorState>();

/// Shows the in-app foreground banner for a push received while the app is
/// open. See [_MedilinkAppState._showForegroundBanner].
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Runs in a separate background isolate when a push arrives while the app
/// is backgrounded/terminated — must be a top-level function. It doesn't
/// need to do anything beyond re-init Firebase; the system tray notification
/// is shown automatically from the message's `notification` payload, and
/// tapping it is handled by `onMessageOpenedApp`/`getInitialMessage` once the
/// app is foregrounded again.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Mobile-only app - uses native Firebase SDK for iOS/Android
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Add sample hospitals if database is empty
  await _addSampleHospitalsIfNeeded();

  // Initialize OFFLINE-FIRST caching service
  // Data persists indefinitely even when system is OFF or on different network
  await CacheService.initialize();


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
      

    } else {

    }
  } catch (e) {

    // Don't block app startup if this fails
  }
}


/// Root widget for the MEDILINK application.
class MedilinkApp extends ConsumerStatefulWidget {
  const MedilinkApp({super.key});

  @override
  ConsumerState<MedilinkApp> createState() => _MedilinkAppState();
}

class _MedilinkAppState extends ConsumerState<MedilinkApp> {
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedAppSub;

  @override
  void initState() {
    super.initState();
    _foregroundSub = FirebaseMessaging.onMessage.listen(_showForegroundBanner);
    _openedAppSub = FirebaseMessaging.onMessageOpenedApp.listen(_openDeepLink);
    FirebaseMessaging.instance.getInitialMessage().then(_openDeepLink);
  }

  @override
  void dispose() {
    _foregroundSub?.cancel();
    _openedAppSub?.cancel();
    super.dispose();
  }

  void _showForegroundBanner(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text('${notification.title ?? ''}: ${notification.body ?? ''}'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(label: 'View', onPressed: () => _openDeepLink(message)),
      ),
    );
  }

  /// Deep-links straight into the relevant emergency screen — the tracking
  /// screen for patients, the Command Center detail screen for hospital
  /// staff. See architecture doc §16.
  Future<void> _openDeepLink(RemoteMessage? message) async {
    final requestId = message?.data['requestId'] as String?;
    if (requestId == null) return;

    final role = await ref.read(currentAppRoleProvider.future);
    final nav = navigatorKey.currentState;
    if (nav == null) return;

    nav.push(
      MaterialPageRoute(
        builder: (_) => role.isHospitalStaff
            ? EmergencyDetailScreen(requestId: requestId)
            : EmergencyTrackingScreen(requestId: requestId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authStream = ref.watch(authStateChangesProvider);

    return MaterialApp(
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: scaffoldMessengerKey,
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

