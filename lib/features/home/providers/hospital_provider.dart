import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medilink/features/home/models/hospital.dart';
import 'package:medilink/features/home/repositories/hospital_repository.dart';
import 'package:medilink/features/auth/providers/auth_providers.dart';

/// Provides a singleton instance of [HospitalRepository].
final hospitalRepositoryProvider = Provider<HospitalRepository>((ref) {
  return HospitalRepository();
});

/// Returns all hospitals
final getAllHospitalsProvider = FutureProvider<List<Hospital>>((ref) async {
  final repo = ref.watch(hospitalRepositoryProvider);
  return repo.getAllHospitals();
});

/// Returns hospitals for the current admin user
final getAdminHospitalsProvider = FutureProvider<List<Hospital>>((ref) async {
  final authState = ref.watch(authStateChangesProvider);
  final repo = ref.watch(hospitalRepositoryProvider);
  
  return authState.when(
    data: (user) {
      if (user == null) return [];
      return repo.getHospitalsByAdmin(user.uid);
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Returns a specific hospital by ID
final getHospitalByIdProvider = FutureProvider.family<Hospital?, String>((ref, hospitalId) async {
  final repo = ref.watch(hospitalRepositoryProvider);
  return repo.getHospitalById(hospitalId);
});

/// StateNotifier for managing hospital creation
class HospitalController extends StateNotifier<AsyncValue<Hospital?>> {
  HospitalController(this._read) : super(const AsyncValue.data(null));

  final Ref _read;

  HospitalRepository get _repo => _read.read(hospitalRepositoryProvider);
  
  Future<void> createHospital(Hospital hospital) async {
    state = const AsyncValue.loading();
    try {
      // Get current user UID directly from Firebase (no stream timeout issues)
      final authRepo = _read.read(authRepositoryProvider);
      final userId = authRepo.getCurrentUserUid();
      
      if (userId == null || userId.isEmpty) {
        throw Exception('User not authenticated - Please sign in again');
      }

      // Check if admin already has a hospital - with extended timeout
      try {
        final hasHospital = await _repo.adminHasHospital(userId).timeout(
          const Duration(seconds: 90),
          onTimeout: () {
            throw Exception('Server is slow - Please try again (authentication check timeout)');
          },
        );
        if (hasHospital) {
          throw Exception('Hospital admins can only create one hospital');
        }
      } catch (e) {
        if (e.toString().contains('timeout') || e.toString().contains('Server is slow')) {
          rethrow;
        }
        // Continue anyway if check fails (hospital might not exist yet)
      }
      
      final createdHospital = await _repo.createHospital(
        hospital.copyWith(createdAt: DateTime.now()),
        userId,
      ).timeout(
        const Duration(seconds: 90),
        onTimeout: () {
          throw Exception('Server is responding slowly - Please check your connection and try again (hospital creation timeout)');
        },
      );
      
      state = AsyncValue.data(createdHospital);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  
  Future<void> deleteHospital(String hospitalId) async {
    state = const AsyncValue.loading();
    try {
      // Delete hospital and all related data
      await _repo.deleteHospital(hospitalId);
      
      // Invalidate cache and refresh auth state to ensure consistency
      _read.invalidate(authStateChangesProvider);
      _read.invalidate(getAdminHospitalsProvider);
      _read.invalidate(getAllHospitalsProvider);
      
      state = AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  
  void clearError() {
    if (state.hasError) state = const AsyncValue.data(null);
  }
}

/// Public provider for hospital creation
final hospitalControllerProvider =
    StateNotifierProvider<HospitalController, AsyncValue<Hospital?>>((ref) {
  return HospitalController(ref);
});
