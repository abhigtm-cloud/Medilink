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
      final authState = _read.read(authStateChangesProvider);
      final user = authState.maybeWhen(
        data: (u) => u,
        orElse: () => null,
      );
      
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      final createdHospital = await _repo.createHospital(
        hospital.copyWith(createdAt: DateTime.now()),
        user.uid,
      );
      state = AsyncValue.data(createdHospital);
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
