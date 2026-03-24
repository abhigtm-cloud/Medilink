import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medilink/features/auth/models/app_user.dart';
import 'package:medilink/features/auth/repositories/auth_repository.dart';
import 'package:medilink/features/home/repositories/hospital_repository.dart';
import 'package:medilink/features/home/repositories/doctor_repository.dart';
import 'package:medilink/features/home/repositories/slot_repository.dart';
import 'package:medilink/features/home/repositories/booking_repository.dart';

/// Provides a singleton instance of [AuthRepository].
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Provides a singleton instance of [HospitalRepository].
final hospitalRepositoryProvider = Provider<HospitalRepository>((ref) {
  return HospitalRepository();
});

/// Provides a singleton instance of [DoctorRepository].
final doctorRepositoryProvider = Provider<DoctorRepository>((ref) {
  return DoctorRepository();
});

/// Provides a singleton instance of [SlotRepository].
final slotRepositoryProvider = Provider<SlotRepository>((ref) {
  return SlotRepository();
});

/// Provides a singleton instance of [BookingRepository].
final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository();
});

/// A synchronous representation of the current [AppUser] state.
final authStateChangesProvider = StreamProvider<AppUser?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges().asBroadcastStream().timeout(
    const Duration(seconds: 20),
    onTimeout: (sink) {
      print('DEBUG: authStateChangesProvider - Stream timeout');
      sink.addError(Exception('Authentication timeout - please check your connection'));
    },
  );
});

/// StateNotifier responsible for handling explicit login / logout actions.
class AuthController extends StateNotifier<AsyncValue<AppUser?>> {
  AuthController(this._read) : super(const AsyncValue.data(null));

  final Ref _read;

  AuthRepository get _repo => _read.read(authRepositoryProvider);

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      print('DEBUG: AuthController.signIn - Starting sign-in for: $email');
      final user = await _repo.signInWithEmailAndPassword(
        email: email,
        password: password,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Sign-in took too long. Please check your internet connection.');
        },
      );
      
      state = AsyncValue.data(user);
      print('DEBUG: AuthController.signIn - Sign-in successful for: $email');
      print('DEBUG: AuthController.signIn - User role: ${user.role.displayName}');
      
      // Force refresh the auth state stream to ensure it emits the new user
      print('DEBUG: AuthController.signIn - Triggering authStateChangesProvider refresh');
      _read.refresh(authStateChangesProvider);
      
    } catch (e, st) {
      print('DEBUG: AuthController.signIn - Error for user $email: $e');
      state = AsyncValue.error(e, st);
      throw Exception(_formatFirebaseError(e));
    }
  }

  Future<void> register(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      print('DEBUG: AuthController.register - Starting registration for: $email');
      final user = await _repo.registerWithEmailAndPassword(
        email: email,
        password: password,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Registration took too long. Please check your internet connection.');
        },
      );
      state = AsyncValue.data(user);
      print('DEBUG: AuthController.register - Registration successful for: $email');
      
      // Force refresh the auth state stream
      print('DEBUG: AuthController.register - Triggering authStateChangesProvider refresh');
      _read.refresh(authStateChangesProvider);
      
    } catch (e, st) {
      print('DEBUG: AuthController.register - Error for user $email: $e');
      state = AsyncValue.error(e, st);
      throw Exception(_formatFirebaseError(e));
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _repo.signOut();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Delete user account with cascade deletion of all related data
  Future<void> deleteAccount() async {
    state = const AsyncValue.loading();
    try {
      final userId = _repo.getCurrentUserUid();
      if (userId == null) {
        throw Exception('No user is currently logged in');
      }

      final hospitalRepo = _read.read(hospitalRepositoryProvider);
      final slotRepo = _read.read(slotRepositoryProvider);
      final bookingRepo = _read.read(bookingRepositoryProvider);
      final currentUser = _read.read(authStateChangesProvider).maybeWhen(
        data: (u) => u,
        orElse: () => null,
      );

      // If user is a hospital admin, delete their hospital and all related data
      if (currentUser?.role.isHospitalAdmin ?? false) {
        final adminHospitals = await hospitalRepo.getHospitalsByAdmin(userId);
        
        for (final hospital in adminHospitals) {
          if (hospital.id != null) {
            // Delete slots and bookings for the hospital
            await slotRepo.deleteSlotsByHospital(hospital.id!);
            await bookingRepo.deleteBookingsByHospital(hospital.id!);
            
            // Delete the hospital
            await hospitalRepo.deleteHospital(hospital.id!);
          }
        }
      } else {
        // For normal users, delete their bookings
        await bookingRepo.deleteBookingsByUser(userId);
      }

      // Finally, delete the user account
      await _repo.deleteAccount();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Clears error state when switching between login and register screens.
  void clearError() {
    if (state.hasError) state = const AsyncValue.data(null);
  }

  /// Formats Firebase authentication errors for user display
  static String _formatFirebaseError(Object error) {
    final msg = error.toString();
    if (msg.contains('user-not-found')) {
      return 'No account found with this email address.';
    }
    if (msg.contains('wrong-password') || msg.contains('invalid-credential')) {
      return 'Invalid email or password. Please try again.';
    }
    if (msg.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    }
    if (msg.contains('too-many-requests')) {
      return 'Too many failed login attempts. Please try again later.';
    }
    if (msg.contains('user-disabled')) {
      return 'This account has been disabled.';
    }
    if (msg.contains('network-request-failed') || msg.contains('TimeoutException')) {
      return 'Network error. Please check your internet connection.';
    }
    return 'An error occurred during sign-in. Please try again.';
  }

}

/// Public provider exposing the [AuthController].
final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<AppUser?>>(
  (ref) => AuthController(ref),
);

