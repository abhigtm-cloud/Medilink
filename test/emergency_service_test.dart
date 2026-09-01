import 'package:flutter_test/flutter_test.dart';
import 'package:medilink/core/services/emergency_service.dart';
import 'package:medilink/features/home/models/hospital.dart';

void main() {
  group('EmergencyService Distance & Sorting Tests', () {
    test('calculateDistance returns correct distance in km using Haversine', () {
      // Distance between New York (40.7128, -74.0060) and Boston (42.3601, -71.0589) ~ 305 km
      final distance = EmergencyService.calculateDistance(
        lat1: 40.7128,
        lon1: -74.0060,
        lat2: 42.3601,
        lon2: -71.0589,
      );

      expect(distance, greaterThan(290));
      expect(distance, lessThan(320));
    });

    test('Hospitals sort nearest-first based on distance', () {
      final h1 = Hospital(
        id: '1',
        name: 'Far Hospital',
        address: 'Far away',
        contact: '123',
        latitude: 40.0000,
        longitude: -74.0000,
      );

      final h2 = Hospital(
        id: '2',
        name: 'Near Hospital',
        address: 'Close by',
        contact: '456',
        latitude: 40.7100,
        longitude: -74.0050,
      );

      const userLat = 40.7128;
      const userLng = -74.0060;

      final dist1 = EmergencyService.calculateDistance(
        lat1: userLat,
        lon1: userLng,
        lat2: h1.latitude!,
        lon2: h1.longitude!,
      );

      final dist2 = EmergencyService.calculateDistance(
        lat1: userLat,
        lon1: userLng,
        lat2: h2.latitude!,
        lon2: h2.longitude!,
      );

      final list = [
        {'hospital': h1, 'distance': dist1},
        {'hospital': h2, 'distance': dist2},
      ];

      list.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));

      expect((list.first['hospital'] as Hospital).id, equals('2'));
    });
  });
}
