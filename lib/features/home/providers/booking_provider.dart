import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medilink/features/home/models/booking.dart';
import 'package:medilink/features/home/repositories/booking_repository.dart';
import 'package:medilink/features/auth/providers/auth_providers.dart';

/// Provides a singleton instance of [BookingRepository].
final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository();
});

/// Returns bookings for the current user
final getUserBookingsProvider = FutureProvider<List<Booking>>((ref) async {
  final authState = ref.watch(authStateChangesProvider);
  final repo = ref.watch(bookingRepositoryProvider);
  
  return authState.when(
    data: (user) {
      if (user == null) return [];
      return repo.getBookingsByUser(user.uid);
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// StateNotifier for managing bookings
class BookingController extends StateNotifier<AsyncValue<Booking?>> {
  BookingController(this._read) : super(const AsyncValue.data(null));

  final Ref _read;

  BookingRepository get _repo => _read.read(bookingRepositoryProvider);
  
  Future<void> createBooking(Booking booking) async {
    state = const AsyncValue.loading();
    try {
      final createdBooking = await _repo.createBooking(booking);
      state = AsyncValue.data(createdBooking);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  
  Future<void> cancelBooking(String bookingId) async {
    state = const AsyncValue.loading();
    try {
      await _repo.cancelBooking(bookingId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  
  void clearError() {
    if (state.hasError) state = const AsyncValue.data(null);
  }
}

/// Public provider for booking management
final bookingControllerProvider =
    StateNotifierProvider<BookingController, AsyncValue<Booking?>>((ref) {
  return BookingController(ref);
});
