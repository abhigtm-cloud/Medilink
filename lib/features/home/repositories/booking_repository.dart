import 'package:firebase_database/firebase_database.dart';
import 'package:medilink/features/home/models/booking.dart';

/// Repository for booking-related operations
class BookingRepository {
  final _database = FirebaseDatabase.instance.ref();
  
  static const String _bookingsPath = 'bookings';
  
  /// Create a new booking
  Future<Booking> createBooking(Booking booking) async {
    try {
      final ref = _database.child(_bookingsPath).push();
      
      await ref.set(booking.toJson());
      
      return booking.copyWith(id: ref.key);
    } catch (e) {
      throw Exception('Failed to create booking: $e');
    }
  }
  
  /// Get bookings for a user
  Future<List<Booking>> getBookingsByUser(String userId) async {
    try {
      // Fetch all bookings and filter in code (avoid Firebase index requirement)
      final snapshot = await _database.child(_bookingsPath).get();
      
      if (!snapshot.exists) {
        return [];
      }
      
      final bookings = <Booking>[];
      final data = snapshot.value as Map<dynamic, dynamic>? ?? {};
      
      data.forEach((key, value) {
        if (value is Map<dynamic, dynamic>) {
          final booking = Booking.fromJson(
            Map<String, dynamic>.from(value),
            docId: key,
          );
          // Filter by userId in code
          if (booking.userId == userId) {
            bookings.add(booking);
          }
        }
      });
      
      return bookings;
    } catch (e) {
      throw Exception('Failed to fetch bookings: $e');
    }
  }
  
  /// Cancel a booking
  Future<void> cancelBooking(String bookingId) async {
    try {
      await _database
          .child(_bookingsPath)
          .child(bookingId)
          .update({'status': 'cancelled'});
    } catch (e) {
      throw Exception('Failed to cancel booking: $e');
    }
  }
}
