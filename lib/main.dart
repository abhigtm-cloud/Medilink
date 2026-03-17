import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medilink/core/theme/app_theme.dart';
import 'package:medilink/features/auth/providers/auth_providers.dart';
import 'package:medilink/features/auth/screens/login_screen.dart';
import 'package:medilink/features/home/screens/home_screen_wrapper.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // On web, pass options explicitly so the JS SDK always receives non-null config.
  final options = kIsWeb
      ? DefaultFirebaseOptions.web
      : DefaultFirebaseOptions.currentPlatform;
  await Firebase.initializeApp(options: options);

  runApp(const ProviderScope(child: MedilinkApp()));
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
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
        error: (e, _) => Scaffold(
          body: Center(
            child: Text('Something went wrong: $e'),
          ),
        ),
      ),
    );
  }
}

