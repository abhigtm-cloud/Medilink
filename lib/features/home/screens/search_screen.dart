import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_theme.dart';
import 'package:medilink/core/services/location_service.dart';
import 'package:medilink/core/services/emergency_service.dart';
import 'package:medilink/features/home/providers/hospital_provider.dart';
import 'package:medilink/features/home/models/hospital.dart';
import 'package:medilink/features/home/screens/doctor_list_screen.dart';

/// Search Screen for searching hospitals by location or name, sorted by distance.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Position? _userPosition;
  bool _loadingLocation = true;

  @override
  void initState() {
    super.initState();
    _fetchUserLocation();
  }

  Future<void> _fetchUserLocation() async {
    final pos = await LocationService.getCurrentLocation();
    if (mounted) {
      setState(() {
        _userPosition = pos;
        _loadingLocation = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _processAndFilterHospitals(List<Hospital> hospitals) {
    final query = _searchController.text.toLowerCase().trim();

    final list = <Map<String, dynamic>>[];

    for (final hospital in hospitals) {
      final matchesQuery = query.isEmpty ||
          hospital.name.toLowerCase().contains(query) ||
          hospital.address.toLowerCase().contains(query);

      if (!matchesQuery) continue;

      double? distKm;
      if (_userPosition != null && hospital.latitude != null && hospital.longitude != null) {
        distKm = EmergencyService.calculateDistance(
          lat1: _userPosition!.latitude,
          lon1: _userPosition!.longitude,
          lat2: hospital.latitude!,
          lon2: hospital.longitude!,
        );
      }

      list.add({
        'hospital': hospital,
        'distance': distKm,
        'distanceStr': distKm == null
            ? null
            : (distKm < 1 ? '${(distKm * 1000).toStringAsFixed(0)}m' : '${distKm.toStringAsFixed(1)}km'),
      });
    }

    // Sort nearest first (items without coordinates go to end)
    list.sort((a, b) {
      final distA = a['distance'] as double?;
      final distB = b['distance'] as double?;
      if (distA == null && distB == null) return 0;
      if (distA == null) return 1;
      if (distB == null) return -1;
      return distA.compareTo(distB);
    });

    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: AppColors.cardLight,
        elevation: 1,
        title: Text(
          'Search Hospitals Nearby',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.cardLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight, width: 1),
                boxShadow: AppTheme.cardShadow,
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search hospital name, address or location',
                  hintStyle: TextStyle(
                    color: AppColors.textSecondaryLight,
                  ),
                  border: InputBorder.none,
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppColors.primary,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),

          // Search Results
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final hospitalsAsync = ref.watch(getAllHospitalsProvider);

    return hospitalsAsync.when(
      data: (hospitals) {
        final processed = _processAndFilterHospitals(hospitals);

        if (processed.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 48,
                  color: AppColors.borderLight,
                ),
                const SizedBox(height: 12),
                Text(
                  'No hospitals found matching search',
                  style: TextStyle(
                    color: AppColors.textSecondaryLight,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: processed.length,
          itemBuilder: (context, index) {
            final item = processed[index];
            final hospital = item['hospital'] as Hospital;
            final distanceStr = item['distanceStr'] as String?;

            return GestureDetector(
              onTap: () {
                if (hospital.id != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DoctorListScreen(
                        hospitalName: hospital.name,
                        hospitalId: hospital.id!,
                      ),
                    ),
                  );
                }
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.cardLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight, width: 1),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: hospital.photoUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                base64Decode(hospital.photoUrl!),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.local_hospital,
                                    color: AppColors.primary,
                                    size: 32,
                                  );
                                },
                              ),
                            )
                          : Icon(
                              Icons.local_hospital,
                              color: AppColors.primary,
                              size: 32,
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  hospital.name,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimaryLight,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (distanceStr != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    distanceStr,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            hospital.address,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondaryLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.phone_outlined,
                                size: 14,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  hospital.contact,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (hospital.latitude != null && hospital.longitude != null)
                                TextButton.icon(
                                  onPressed: () {
                                    LocationService.openGoogleMaps(
                                      latitude: hospital.latitude!,
                                      longitude: hospital.longitude!,
                                      locationName: hospital.name,
                                    );
                                  },
                                  icon: const Icon(Icons.directions, size: 14, color: AppColors.primary),
                                  label: const Text('Map', style: TextStyle(fontSize: 11, color: AppColors.primary)),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(50, 24),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      ),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 12),
            Text(
              'Failed to load hospitals',
              style: TextStyle(
                color: AppColors.error,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

