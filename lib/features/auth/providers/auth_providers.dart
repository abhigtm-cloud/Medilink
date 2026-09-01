import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medilink/core/services/fcm_service.dart';
import 'package:medilink/core/services/rbac_service.dart';
import 'package:medilink/features/auth/models/app_user.dart';
import 'package:medilink/features/auth/repositories/auth_repository.dart';
import 'package:medilink/features/auth/repositories/user_profile_repository.dart';
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

/// Provides a singleton instance of [UserProfileRepository].
final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  return UserProfileRepository();
});

/// Get user profile from Firebase (real data)
final getUserProfileProvider =
    FutureProvider.family<AppUser?, String>((ref, uid) async {
  final repo = ref.watch(userProfileRepositoryProvider);
  return repo.getUserProfile(uid);
});

/// Provides a singleton instance of [RbacService].
final rbacServiceProvider = Provider<RbacService>((ref) => RbacService());

/// Provides a singleton instance of [FcmService].
final fcmServiceProvider = Provider<FcmService>((ref) => FcmService());

/// The signed-in user's server-verified role + hospital assignment, sourced
/// from Firebase custom claims (see docs/EMERGENCY_PLATFORM_ARCHITECTURE.md §3).
/// Re-reads claims (with a forced token refresh) whenever [authStateChangesProvider]
/// emits a new user, so it's up to date right after sign-in/sign-out.
///
/// If a hospital_admin assigns this user a staff role *during* their
/// session, call `ref.read(rbacServiceProvider).refreshClaims()` followed by
/// `ref.invalidate(currentAppRoleProvider)` to pick it up immediately.
final currentAppRoleProvider = FutureProvider<AppRole>((ref) async {
  final rbac = ref.watch(rbacServiceProvider);
  final user = ref.watch(authStateChangesProvider).valueOrNull;

  if (user == null) {
    rbac.reset();
    return AppRole.unknown;
  }
  return rbac.refreshClaims();
});

/// The signed-in user's hospital assignment (null for patients, or for
/// staff not yet linked to a hospital). Resolves from RBAC claims or
/// falls back to the admin's registered hospitals.
final currentHospitalIdProvider = FutureProvider<String?>((ref) async {
  try {
    final rbacHosp = ref.watch(rbacServiceProvider).currentHospitalId;
    if (rbacHosp != null && rbacHosp.isNotEmpty) return rbacHosp;
  } catch (_) {}

  final user = ref.watch(authStateChangesProvider).valueOrNull;
  if (user != null) {
    try {
      final hospitalRepo = ref.watch(hospitalRepositoryProvider);
      final hospitals = await hospitalRepo.getHospitalsByAdmin(user.uid);
      if (hospitals.isNotEmpty && hospitals.first.id != null) {
        return hospitals.first.id;
      }
      final allHospitals = await hospitalRepo.getAllHospitals();
      if (allHospitals.isNotEmpty && allHospitals.first.id != null) {
        return allHospitals.first.id;
      }
    } catch (_) {}
  }
  return null;
});

/// A synchronous representation of the current [AppUser] state.
final authStateChangesProvider = StreamProvider<AppUser?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges();
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
      
      // Force refresh the auth state stream to ensure it emits the new user
      _read.invalidate(authStateChangesProvider);
      
    } catch (e, st) {
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
      
      // Force refresh the auth state stream
      _read.invalidate(authStateChangesProvider);
      
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      throw Exception(_formatFirebaseError(e));
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      try {
        await _read.read(fcmServiceProvider).clearToken();
      } catch (e) {
        print('DEBUG: clearToken non-fatal error: $e');
      }
      try {
        _read.read(rbacServiceProvider).reset();
      } catch (_) {}

      await _repo.signOut();
      state = const AsyncValue.data(null);
      
      // Force refresh all auth-dependent providers to guarantee immediate UI redirect to Login
      _read.invalidate(authStateChangesProvider);
      _read.invalidate(currentAppRoleProvider);
      _read.invalidate(currentHospitalIdProvider);
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
        try {
          final adminHospitals = await hospitalRepo.getHospitalsByAdmin(userId);
          for (final hospital in adminHospitals) {
            if (hospital.id != null) {
              await slotRepo.deleteSlotsByHospital(hospital.id!).catchError((_) {});
              await bookingRepo.deleteBookingsByHospital(hospital.id!).catchError((_) {});
              await hospitalRepo.deleteHospital(hospital.id!).catchError((_) {});
            }
          }
        } catch (_) {}
      } else {
        // For normal users, delete their bookings
        try {
          await bookingRepo.deleteBookingsByUser(userId).catchError((_) {});
        } catch (_) {}
      }

      // Delete user profile in Realtime Database
      try {
        await _read.read(userProfileRepositoryProvider).updateUserField(userId, 'deleted', true).catchError((_) {});
      } catch (_) {}

      // Clear token & RBAC state
      try {
        await _read.read(fcmServiceProvider).clearToken();
      } catch (_) {}
      try {
        _read.read(rbacServiceProvider).reset();
      } catch (_) {}

      // Delete the Firebase Auth user account (or sign out if requires-recent-login)
      try {
        await _repo.deleteAccount();
      } catch (authDeleteError) {
        print('DEBUG: Auth deleteAccount encountered: $authDeleteError. Signing out.');
        await _repo.signOut();
      }

      state = const AsyncValue.data(null);
      _read.invalidate(authStateChangesProvider);
      _read.invalidate(currentAppRoleProvider);
      _read.invalidate(currentHospitalIdProvider);
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

