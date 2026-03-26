import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medilink/features/home/models/doctor.dart';
import 'package:medilink/features/home/repositories/doctor_repository.dart';
import 'package:medilink/features/home/repositories/slot_repository.dart';
import 'package:medilink/features/home/repositories/booking_repository.dart';

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

/// Returns doctors for a specific hospital
final getDoctorsByHospitalProvider = FutureProvider.family<List<Doctor>, String>(
  (ref, hospitalId) async {
    final repo = ref.watch(doctorRepositoryProvider);
    return repo.getDoctorsByHospital(hospitalId);
  },
);

/// Returns a specific doctor
final getDoctorByIdProvider = FutureProvider.family<Doctor?, (String, String)>(
  (ref, params) async {
    final (hospitalId, doctorId) = params;
    final repo = ref.watch(doctorRepositoryProvider);
    return repo.getDoctorById(hospitalId, doctorId);
  },
);

/// StateNotifier for managing doctor creation
class DoctorController extends StateNotifier<AsyncValue<Doctor?>> {
  DoctorController(this._read) : super(const AsyncValue.data(null));

  final Ref _read;

  DoctorRepository get _repo => _read.read(doctorRepositoryProvider);
  
  Future<void> createDoctor(Doctor doctor) async {
    state = const AsyncValue.loading();
    try {
      final createdDoctor = await _repo.createDoctor(
        doctor.copyWith(createdAt: DateTime.now()),
      );
      state = AsyncValue.data(createdDoctor);

    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  
  Future<void> createMultipleDoctors(List<Doctor> doctors, String hospitalId) async {
    state = const AsyncValue.loading();
    try {
      for (final doctor in doctors) {
        await _repo.createDoctor(
          doctor.copyWith(createdAt: DateTime.now()),
        );
      }
      state = AsyncValue.data(null);

    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Delete a doctor and all related slots and bookings
  Future<void> deleteDoctor(String hospitalId, String doctorId) async {
    state = const AsyncValue.loading();
    try {
      final slotRepo = _read.read(slotRepositoryProvider);
      final bookingRepo = _read.read(bookingRepositoryProvider);

      // Delete all slots for this doctor
      await slotRepo.deleteSlotsByDoctor(hospitalId, doctorId);

      // Delete all bookings for this doctor
      await bookingRepo.deleteBookingsByDoctor(hospitalId, doctorId);

      // Finally, delete the doctor
      await _repo.deleteDoctor(hospitalId, doctorId);

      // Invalidate cache
      await _read.refresh(getDoctorsByHospitalProvider(hospitalId));

      state = AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  
  void clearError() {
    if (state.hasError) state = const AsyncValue.data(null);
  }
}

/// Public provider for doctor management
final doctorControllerProvider =
    StateNotifierProvider<DoctorController, AsyncValue<Doctor?>>((ref) {
  return DoctorController(ref);
});
