import 'package:geolocator/geolocator.dart';
import 'package:medilink/features/home/models/hospital.dart';
import 'package:medilink/features/home/models/slot.dart';

class EmergencyService {
  /// Calculate distance between two coordinates (in km)
  static double calculateDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 -
        ((lat2 - lat1) * p).cos() / 2 +
        ((lon1 - lon2) * p).cos() * ((lat1 * p).cos()) * ((lat2 * p).cos()) / 2;
    return 12742 * Asin(a.isNaN ? 0 : a.toDouble()); // 2 * R; R = 6371 km
  }

  /// Find nearest hospital with available doctor
  static Future<Hospital?> findNearestHospitalWithAvailability({
    required List<Hospital> hospitals,
    required List<Slot> allSlots,
  }) async {
    try {
      // Get user's current location
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (hospitals.isEmpty) return null;

      // Calculate distance for each hospital that has coordinates
      final hospitalsWithDistance = hospitals
          .where((h) => h.latitude != null && h.longitude != null)
          .map((h) {
        final distance = calculateDistance(
          lat1: position.latitude,
          lon1: position.longitude,
          lat2: h.latitude!,
          lon2: h.longitude!,
        );

        // Check if hospital has available slots today or tomorrow
        final now = DateTime.now();
        final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        final tomorrow = '${now.add(const Duration(days: 1)).year}-${now.add(const Duration(days: 1)).month.toString().padLeft(2, '0')}-${now.add(const Duration(days: 1)).day.toString().padLeft(2, '0')}';

        final availableSlots = allSlots
            .where((s) => s.hospitalId == h.id && (s.date == today || s.date == tomorrow) && s.isAvailable)
            .length;

        return {
          'hospital': h,
          'distance': distance,
          'availableSlots': availableSlots,
        };
      })
          .where((h) => (h['availableSlots'] as int) > 0) // Only hospitals with available slots
          .toList();

      if (hospitalsWithDistance.isEmpty) return null;

      // Sort by distance and get nearest
      hospitalsWithDistance.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));

      return hospitalsWithDistance.first['hospital'] as Hospital;
    } catch (e) {
      print('DEBUG: Error finding nearest hospital: $e');
      return null;
    }
  }

  /// Get distance from user to hospital
  static Future<double?> getDistanceToHospital({
    required Hospital hospital,
  }) async {
    try {
      if (hospital.latitude == null || hospital.longitude == null) return null;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return calculateDistance(
        lat1: position.latitude,
        lon1: position.longitude,
        lat2: hospital.latitude!,
        lon2: hospital.longitude!,
      );
    } catch (e) {
      print('DEBUG: Error getting distance: $e');
      return null;
    }
  }
}

extension on double {
  double toDouble() => this;
}
