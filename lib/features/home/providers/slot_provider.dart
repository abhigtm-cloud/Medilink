import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medilink/features/home/models/doctor.dart';
import 'package:medilink/features/home/models/slot.dart';
import 'package:medilink/features/home/repositories/slot_repository.dart';

/// Provides a singleton instance of [SlotRepository].
final slotRepositoryProvider = Provider<SlotRepository>((ref) {
  return SlotRepository();
});

/// Returns real-time stream of slots for a doctor on a specific date (live updates!)
final getSlotsByDoctorAndDateProvider = StreamProvider.family<List<Slot>, (String, String, String)>(
  (ref, params) {
    final (hospitalId, doctorId, date) = params;
    final repo = ref.watch(slotRepositoryProvider);
    return repo.watchSlotsByDoctorAndDate(hospitalId, doctorId, date);
  },
);

/// StateNotifier for managing slots
class SlotController extends StateNotifier<AsyncValue<void>> {
  SlotController(this._read) : super(const AsyncValue.data(null));

  final Ref _read;

  SlotRepository get _repo => _read.read(slotRepositoryProvider);
  
  Future<void> createSlots(List<Slot> slots, String hospitalId, String doctorId, String date) async {
    state = const AsyncValue.loading();
    try {
      await _repo.createSlots(slots);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  
  Future<void> bookSlot(
    String slotId,
    String hospitalId,
    String doctorId,
    String date,
    String userId,
  ) async {
    state = const AsyncValue.loading();
    try {
      await _repo.bookSlot(slotId, hospitalId, doctorId, date, userId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteSlot({
    required String hospitalId,
    required String doctorId,
    required String date,
    required String slotId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteSlot(
        hospitalId: hospitalId,
        doctorId: doctorId,
        date: date,
        slotId: slotId,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteSlotsForDate({
    required String hospitalId,
    required String doctorId,
    required String date,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteSlotsForDate(
        hospitalId: hospitalId,
        doctorId: doctorId,
        date: date,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleSlotBusy({
    required String hospitalId,
    required String doctorId,
    required String date,
    required String slotId,
    required bool markBusy,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.toggleSlotBusy(
        hospitalId: hospitalId,
        doctorId: doctorId,
        date: date,
        slotId: slotId,
        markBusy: markBusy,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> regenerateDateSlots(Doctor doctor, String dateStr) async {
    state = const AsyncValue.loading();
    try {
      await _repo.regenerateDateSlots(doctor, dateStr);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  
  void clearError() {
    if (state.hasError) state = const AsyncValue.data(null);
  }
}

/// Public provider for slot management
final slotControllerProvider =
    StateNotifierProvider<SlotController, AsyncValue<void>>((ref) {
  return SlotController(ref);
});
