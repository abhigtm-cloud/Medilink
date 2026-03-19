import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final stream = repo.authStateChanges();
  
  // Add timeout and error handling
  return stream
      .timeout(
        const Duration(seconds: 10),
        onTimeout: (sink) {
          print('DEBUG: authStateChangesProvider - Stream timeout after 10 seconds');
          print('DEBUG: authStateChangesProvider - Current user from Firebase: ${FirebaseAuth.instance.currentUser?.email}');
          // If stream times out, check current user directly
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null) {
            final appUser = AppUser.create(
              uid: currentUser.uid,
              email: currentUser.email ?? '',
              displayName: currentUser.displayName,
            );
            sink.add(appUser);
          }
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
      final user = await _repo.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> register(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repo.registerWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
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
}

/// Public provider exposing the [AuthController].
final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<AppUser?>>(
  (ref) => AuthController(ref),
);

