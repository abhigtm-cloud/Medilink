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
  final TextEditingController _searchController = TextEditingController();
  Position? _userPosition;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _hospitalsFuture = _getHospitalsSortedByDistance();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        double distance = 9999.0;
        if (hospital.latitude != null && hospital.longitude != null && _userPosition != null) {
          distance = EmergencyService.calculateDistance(
            lat1: _userPosition!.latitude,
            lon1: _userPosition!.longitude,
            lat2: hospital.latitude!,
            lon2: hospital.longitude!,
          );
        }

        hospitalsWithDistance.add({
          'hospital': hospital,
          'distance': distance,
          'distanceStr': distance < 1
              ? '${(distance * 1000).toStringAsFixed(0)}m'
              : '${distance.toStringAsFixed(1)}km',
        });
      }

      // Sort by distance (nearest first)
      hospitalsWithDistance.sort(
          (a, b) => (a['distance'] as double).compareTo(b['distance'] as double));

      return hospitalsWithDistance;
    } catch (e) {
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
            const Text(
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.toLowerCase().trim();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search nearest hospitals by name or area…',
                prefixIcon: const Icon(Icons.search, color: Colors.red),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.cardLight,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _hospitalsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Locating hospitals nearby...'),
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

                final allHospitals = snapshot.data ?? [];
                final filtered = allHospitals.where((item) {
                  if (_searchQuery.isEmpty) return true;
                  final h = item['hospital'];
                  return h.name.toLowerCase().contains(_searchQuery) ||
                      h.address.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.location_off, size: 48, color: AppColors.textSecondaryLight),
                        SizedBox(height: 16),
                        Text('No hospitals matching location search'),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final hospital = item['hospital'];
                    final distance = item['distanceStr'];

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.local_hospital,
                              color: Colors.red,
                              size: 26,
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
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue),
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
                        trailing: ElevatedButton.icon(
                          onPressed: () {
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
                          icon: const Icon(Icons.directions, size: 14, color: Colors.white),
                          label: const Text('Map', style: TextStyle(color: Colors.white, fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: const Size(60, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

