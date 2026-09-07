import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:medilink/core/services/emergency_service.dart';
import 'package:medilink/core/services/location_service.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/features/home/models/hospital.dart';
import 'package:medilink/features/home/providers/hospital_provider.dart';
import 'package:medilink/features/home/screens/doctor_list_screen.dart';

class HospitalMapScreen extends ConsumerStatefulWidget {
  const HospitalMapScreen({super.key});

  @override
  ConsumerState<HospitalMapScreen> createState() => _HospitalMapScreenState();
}

class _HospitalMapScreenState extends ConsumerState<HospitalMapScreen> {
  Position? _currentPosition;
  String _currentPlaceName = 'Detecting location...';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      final position = await LocationService.getCurrentLocation();
      if (position != null) {
        final placeName = await LocationService.getPlaceName(
          position.latitude,
          position.longitude,
        );
        if (mounted) {
          setState(() {
            _currentPosition = position;
            _currentPlaceName = placeName;
            _loading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _loading = false;
            _currentPlaceName = 'Location unavailable';
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _currentPlaceName = 'Location unavailable';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hospitalsAsync = ref.watch(getAllHospitalsProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        title: const Text('Hospitals & Clinic Locations'),
        backgroundColor: AppColors.cardLight,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location, color: AppColors.primary),
            onPressed: () {
              setState(() => _loading = true);
              _initializeLocation();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : hospitalsAsync.when(
              data: (hospitals) => _buildHospitalMapView(hospitals),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error loading hospitals: $e')),
            ),
    );
  }

  Widget _buildHospitalMapView(List<Hospital> hospitals) {
    // Sort hospitals nearest first if position available
    final sortedHospitals = List<Hospital>.from(hospitals);
    if (_currentPosition != null) {
      sortedHospitals.sort((a, b) {
        final distA = (a.latitude != null && a.longitude != null)
            ? EmergencyService.calculateDistance(
                lat1: _currentPosition!.latitude,
                lon1: _currentPosition!.longitude,
                lat2: a.latitude!,
                lon2: a.longitude!,
              )
            : 9999.0;
        final distB = (b.latitude != null && b.longitude != null)
            ? EmergencyService.calculateDistance(
                lat1: _currentPosition!.latitude,
                lon1: _currentPosition!.longitude,
                lat2: b.latitude!,
                lon2: b.longitude!,
              )
            : 9999.0;
        return distA.compareTo(distB);
      });
    }

    return Column(
      children: [
        // User Location Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: AppColors.primaryLight.withOpacity(0.15),
          child: Row(
            children: [
              const Icon(Icons.person_pin_circle, color: AppColors.primary, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Your Current Location',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'GPS Live',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _currentPlaceName,
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Hospital list sorted by distance
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: sortedHospitals.length,
            itemBuilder: (context, index) {
              final hospital = sortedHospitals[index];
              double? distKm;
              if (_currentPosition != null &&
                  hospital.latitude != null &&
                  hospital.longitude != null) {
                distKm = EmergencyService.calculateDistance(
                  lat1: _currentPosition!.latitude,
                  lon1: _currentPosition!.longitude,
                  lat2: hospital.latitude!,
                  lon2: hospital.longitude!,
                );
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.local_hospital, color: AppColors.primary, size: 28),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  hospital.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  hospital.address,
                                  style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          if (distKm != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                LocationService.formatDistance(distKm),
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.medical_services, size: 16),
                              label: const Text('View Doctors'),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DoctorListScreen(
                                      hospitalName: hospital.name,
                                      hospitalId: (hospital.id != null && hospital.id!.isNotEmpty) ? hospital.id! : hospital.name,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.directions, size: 16, color: Colors.white),
                              label: const Text('Open Map', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                              ),
                              onPressed: () {
                                if (hospital.latitude != null && hospital.longitude != null) {
                                  LocationService.openGoogleMaps(
                                    latitude: hospital.latitude!,
                                    longitude: hospital.longitude!,
                                    locationName: hospital.name,
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Hospital GPS coordinates not set')),
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

