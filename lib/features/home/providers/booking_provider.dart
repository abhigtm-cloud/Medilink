import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medilink/features/home/models/booking.dart';
import 'package:medilink/features/home/repositories/booking_repository.dart';
import 'package:medilink/features/home/repositories/doctor_repository.dart';
import 'package:medilink/features/home/repositories/hospital_repository.dart';
import 'package:medilink/features/auth/providers/auth_providers.dart';
import 'package:medilink/core/services/email_service.dart';

/// Provides a singleton instance of [BookingRepository].
final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository();
});

/// Returns bookings for a specific user
final getBookingsByUserProvider =
    FutureProvider.family<List<Booking>, String>((ref, userId) async {
  final repo = ref.watch(bookingRepositoryProvider);
  return repo.getBookingsByUser(userId);
});

/// StateNotifier for managing bookings
class BookingController extends StateNotifier<AsyncValue<Booking?>> {
  BookingController(this._read) : super(const AsyncValue.data(null));

  final Ref _read;

  BookingRepository get _repo => _read.read(bookingRepositoryProvider);
  
  Future<void> createBooking(Booking booking) async {
    state = const AsyncValue.loading();
    try {
      // Create the booking
      final createdBooking = await _repo.createBooking(booking);
      state = AsyncValue.data(createdBooking);

      // Send confirmation emails (async, don't wait for it)
      _sendBookingConfirmationEmail(booking);
      
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  
  Future<void> _sendBookingConfirmationEmail(Booking booking) async {
    try {
      // Get current user info
      final authState = _read.read(authStateChangesProvider);
      final user = authState.when(
        data: (u) => u,
        orElse: () => null,
      );

      if (user == null) return;

      // Get doctor info
      final doctorRepo = _read.read(doctorRepositoryProvider);
      final doctor = await doctorRepo.getDoctorById(booking.doctorId);

      // Get hospital info
      final hospitalRepo = _read.read(hospitalRepositoryProvider);
      final hospital = await hospitalRepo.getHospitalById(booking.hospitalId);

      // Don't send if missing critical data
      if (doctor?.email == null) {
        print('DEBUG: Doctor email not available, skipping email');
        return;
      }

      // Send confirmation email
      await EmailService.sendBookingConfirmation(
        customerEmail: user.email,
        customerName: user.displayName ?? 'Patient',
        doctorName: doctor!.name,
        doctorEmail: doctor.email!,
        hospitalName: hospital?.name ?? 'Hospital',
        appointmentDate: booking.date,
        appointmentTime: booking.time,
        specialization: doctor.specialization,
      );

      print('DEBUG: Booking confirmation email sent successfully');
    } catch (e) {
      print('DEBUG: Error sending booking confirmation email: $e');
      // Don't fail the booking if email fails
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
