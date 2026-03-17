import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medilink/features/home/models/slot.dart';
import 'package:medilink/features/home/repositories/slot_repository.dart';

/// Provides a singleton instance of [SlotRepository].
final slotRepositoryProvider = Provider<SlotRepository>((ref) {
  return SlotRepository();
});

/// Returns slots for a doctor on a specific date
final getSlotsByDoctorAndDateProvider = FutureProvider.family<List<Slot>, (String, String, String)>(
  (ref, params) async {
    final (hospitalId, doctorId, date) = params;
    final repo = ref.watch(slotRepositoryProvider);
    return repo.getSlotsByDoctorAndDate(hospitalId, doctorId, date);
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
  
  void clearError() {
    if (state.hasError) state = const AsyncValue.data(null);
  }
}

/// Public provider for slot management
final slotControllerProvider =
    StateNotifierProvider<SlotController, AsyncValue<void>>((ref) {
  return SlotController(ref);
});
