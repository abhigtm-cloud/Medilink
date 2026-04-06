import 'package:firebase_database/firebase_database.dart';
import 'package:medilink/features/home/models/booking.dart';
import 'package:medilink/features/home/models/notification.dart';

/// Repository for booking-related operations
class BookingRepository {
  final _database = FirebaseDatabase.instance.ref();
  
  static const String _bookingsPath = 'bookings';
  static const String _notificationsPath = 'notifications';
  
  /// Create a new booking & notify hospital admin
  Future<Booking> createBooking(Booking booking, {String? customerName}) async {
    try {
      final ref = _database.child(_bookingsPath).push();
      
      await ref.set(booking.toJson());
      
      final newBooking = booking.copyWith(id: ref.key);
      
      // Create notification for hospital admin
      await _createAdminNotification(newBooking, customerName);
      
      return newBooking;
    } catch (e) {
      throw Exception('Failed to create booking: $e');
    }
  }
  
  /// Create a notification for hospital admin about new booking
  Future<void> _createAdminNotification(
    Booking booking,
    String? customerName,
  ) async {
    try {
      // Get hospital data to find admin ID
      final hospitalSnapshot = await _database
          .child('hospitals')
          .child(booking.hospitalId)
          .get();
      
      if (!hospitalSnapshot.exists) return;
      
      final hospitalData = hospitalSnapshot.value as Map<dynamic, dynamic>?;
      final adminId = hospitalData?['adminId'] as String?;
      
      if (adminId == null) return;
      
      // Get doctor name
      final doctorSnapshot = await _database
          .child('doctors')
          .child(booking.hospitalId)
          .child(booking.doctorId)
          .get();
      
      final doctorData = doctorSnapshot.value as Map<dynamic, dynamic>?;
      final doctorName = doctorData?['name'] as String? ?? 'Unknown Doctor';
      
      // Create notification for pending booking confirmation
      final notification = Notification(
        userId: adminId,
        type: 'booking',
        title: 'New Booking Awaiting Confirmation! ⏳',
        message: 'A new appointment needs your approval',
        data: {
          'bookingId': booking.id,
          'customerName': customerName ?? 'User',
          'doctorName': doctorName,
          'date': booking.date,
          'time': booking.time,
          'status': 'pending',
        },
        createdAt: DateTime.now(),
      );
      
      // Save notification
      final notifRef = _database
          .child(_notificationsPath)
          .child(adminId)
          .push();
      
      await notifRef.set(notification.toJson());
    } catch (e) {
      // Don't throw - booking should succeed even if notification fails
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

  /// Delete all bookings for a user
  Future<void> deleteBookingsByUser(String userId) async {
    try {
      final snapshot = await _database.child(_bookingsPath).get();
      
      if (!snapshot.exists) {
        return;
      }
      
      final data = snapshot.value as Map<dynamic, dynamic>? ?? {};
      
      // Delete each booking belonging to the user
      for (final key in data.keys) {
        final value = data[key];
        if (value is Map<dynamic, dynamic>) {
          final booking = value;
          if (booking['userId'] == userId) {
            await _database.child(_bookingsPath).child(key).remove();
          }
        }
      }
    } catch (e) {
      throw Exception('Failed to delete user bookings: $e');
    }
  }

  /// Get bookings for a specific doctor
  Future<List<Booking>> getBookingsByDoctor(
    String hospitalId,
    String doctorId,
  ) async {
    try {
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
          // Filter by doctor
          if (booking.doctorId == doctorId && booking.hospitalId == hospitalId) {
            bookings.add(booking);
          }
        }
      });
      
      return bookings;
    } catch (e) {
      throw Exception('Failed to fetch doctor bookings: $e');
    }
  }

  /// Delete all bookings for a doctor
  Future<void> deleteBookingsByDoctor(
    String hospitalId,
    String doctorId,
  ) async {
    try {
      final snapshot = await _database.child(_bookingsPath).get();
      
      if (!snapshot.exists) {
        return;
      }
      
      final data = snapshot.value as Map<dynamic, dynamic>? ?? {};
      
      // Delete each booking for the doctor
      for (final key in data.keys) {
        final value = data[key];
        if (value is Map<dynamic, dynamic>) {
          final booking = value;
          if (booking['doctorId'] == doctorId &&
              booking['hospitalId'] == hospitalId) {
            await _database.child(_bookingsPath).child(key).remove();
          }
        }
      }
    } catch (e) {
      throw Exception('Failed to delete doctor bookings: $e');
    }
  }

  /// Delete all bookings for a hospital
  Future<void> deleteBookingsByHospital(String hospitalId) async {
    try {
      final snapshot = await _database.child(_bookingsPath).get();
      
      if (!snapshot.exists) {
        return;
      }
      
      final data = snapshot.value as Map<dynamic, dynamic>? ?? {};
      
      // Delete each booking for the hospital
      for (final key in data.keys) {
        final value = data[key];
        if (value is Map<dynamic, dynamic>) {
          final booking = value;
          if (booking['hospitalId'] == hospitalId) {
            await _database.child(_bookingsPath).child(key).remove();
          }
        }
      }
    } catch (e) {
      throw Exception('Failed to delete hospital bookings: $e');
    }
  }

  /// Get all bookings for a hospital
  Future<List<Booking>> getBookingsByHospital(String hospitalId) async {
    try {
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
          if (booking.hospitalId == hospitalId) {
            bookings.add(booking);
          }
        }
      });
      
      return bookings;
    } catch (e) {
      throw Exception('Failed to fetch hospital bookings: $e');
    }
  }

  /// Get pending bookings for a hospital
  Future<List<Booking>> getPendingBookingsByHospital(String hospitalId) async {
    try {
      final bookings = await getBookingsByHospital(hospitalId);
      return bookings.where((b) => b.status == BookingStatus.pending).toList();
    } catch (e) {
      throw Exception('Failed to fetch pending bookings: $e');
    }
  }

  /// Approve a booking (change status from pending to confirmed)
  Future<void> approveBooking(String bookingId, String hospitalId) async {
    try {
      await _database
          .child(_bookingsPath)
          .child(bookingId)
          .update({'status': 'confirmed'});
    } catch (e) {
      throw Exception('Failed to approve booking: $e');
    }
  }

  /// Reject a booking (change status from pending to cancelled)
  Future<void> rejectBooking(String bookingId, String hospitalId) async {
    try {
      await _database
          .child(_bookingsPath)
          .child(bookingId)
          .update({'status': 'cancelled'});
    } catch (e) {
      throw Exception('Failed to reject booking: $e');
    }
  }

  /// Get total bookings count for a doctor in a hospital
  Future<int> getTotalBookingsCountForDoctor(
    String hospitalId,
    String doctorId,
  ) async {
    try {
      final bookings = await getBookingsByDoctor(hospitalId, doctorId);
      return bookings.length;
    } catch (e) {
      throw Exception('Failed to get bookings count: $e');
    }
  }
}
