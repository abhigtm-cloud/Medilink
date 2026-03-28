import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:medilink/core/services/location_service.dart';
import 'package:medilink/core/services/emergency_service.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/features/home/providers/hospital_provider.dart';

class EmergencyHospitalsScreen extends ConsumerStatefulWidget {
  const EmergencyHospitalsScreen({super.key});

  @override
  ConsumerState<EmergencyHospitalsScreen> createState() =>
      _EmergencyHospitalsScreenState();
}

class _EmergencyHospitalsScreenState
    extends ConsumerState<EmergencyHospitalsScreen> {
  late Future<List<Map<String, dynamic>>> _hospitalsFuture;
  Position? _userPosition;

  @override
  void initState() {
    super.initState();
    _hospitalsFuture = _getHospitalsSortedByDistance();
  }

  Future<List<Map<String, dynamic>>> _getHospitalsSortedByDistance() async {
    try {
      // Get user location
      _userPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get all hospitals
      final hospitalsAsync = ref.read(getAllHospitalsProvider);
      final hospitals = hospitalsAsync.value ?? [];

      // Build list with distance and availability info
      final hospitalsWithDistance = <Map<String, dynamic>>[];

      for (final hospital in hospitals) {
        if (hospital.latitude != null && hospital.longitude != null) {
          final distance = EmergencyService.calculateDistance(
            lat1: _userPosition!.latitude,
            lon1: _userPosition!.longitude,
            lat2: hospital.latitude!,
            lon2: hospital.longitude!,
          );

          hospitalsWithDistance.add({
            'hospital': hospital,
            'distance': distance,
            'distanceStr': distance < 1
                ? '${(distance * 1000).toStringAsFixed(0)}m'
                : '${distance.toStringAsFixed(1)}km',
          });
        }
      }

      // Sort by distance (nearest first)
      hospitalsWithDistance.sort(
          (a, b) => (a['distance'] as double).compareTo(b['distance'] as double));

      return hospitalsWithDistance;
    } catch (e) {
      print('DEBUG: Error getting hospitals: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: AppColors.cardLight,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'EMERGENCY',
              style: TextStyle(
                color: Colors.red,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Available Hospitals (Nearest First)',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
            ),
          ],
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _hospitalsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text('Locating hospitals nearby...'),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          final hospitals = snapshot.data ?? [];

          if (hospitals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_off, size: 48),
                  const SizedBox(height: 16),
                  const Text('No hospitals with location found'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: hospitals.length,
            itemBuilder: (context, index) {
              final item = hospitals[index];
              final hospital = item['hospital'];
              final distance = item['distanceStr'];

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.local_hospital,
                        color: Colors.red,
                        size: 28,
                      ),
                    ),
                  ),
                  title: Text(
                    hospital.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.navigation, size: 12, color: Colors.blue),
                          const SizedBox(width: 4),
                          Text(
                            'Distance: $distance',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.place, size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              hospital.address,
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: Icon(Icons.arrow_forward_ios,
                      size: 16, color: AppColors.primary),
                  onTap: () {
                    // Open Google Maps directly
                    if (hospital.latitude != null && hospital.longitude != null) {
                      LocationService.openGoogleMaps(
                        latitude: hospital.latitude!,
                        longitude: hospital.longitude!,
                        locationName: hospital.name,
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Hospital location not available'),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
