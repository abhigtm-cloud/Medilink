import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
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
  final MapController _mapController = MapController();
  Position? _currentPosition;
  String _currentPlaceName = 'Detecting location...';
  bool _loading = true;
  Hospital? _selectedHospital;
  bool _isMapView = true;

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
          // Move map camera to user position
          _mapController.move(
            LatLng(position.latitude, position.longitude),
            13.5,
          );
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

  void _centerOnUser() {
    if (_currentPosition != null) {
      _mapController.move(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        14.0,
      );
    } else {
      _initializeLocation();
    }
  }

  void _selectHospital(Hospital hospital) {
    setState(() {
      _selectedHospital = hospital;
    });
    if (hospital.latitude != null && hospital.longitude != null) {
      _mapController.move(
        LatLng(hospital.latitude!, hospital.longitude!),
        14.5,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hospitalsAsync = ref.watch(getAllHospitalsProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        title: const Text('Hospital Geo Map & Locations'),
        backgroundColor: AppColors.cardLight,
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(
              _isMapView ? Icons.format_list_bulleted : Icons.map_outlined,
              color: AppColors.primary,
            ),
            tooltip: _isMapView ? 'Show List View' : 'Show Geo Map',
            onPressed: () {
              setState(() {
                _isMapView = !_isMapView;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.my_location, color: AppColors.primary),
            tooltip: 'Recenter on My Location',
            onPressed: _centerOnUser,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : hospitalsAsync.when(
              data: (hospitals) => _isMapView
                  ? _buildGeoMapView(hospitals)
                  : _buildHospitalListView(hospitals),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error loading hospitals: $e')),
            ),
    );
  }

  /// Interactive Geo Map with OpenStreetMap tiles and custom tags over hospital locations
  Widget _buildGeoMapView(List<Hospital> hospitals) {
    final userLat = _currentPosition?.latitude ?? 30.7441;
    final userLng = _currentPosition?.longitude ?? 76.6471;
    final userLatLng = LatLng(userLat, userLng);

    // Filter hospitals with valid coordinates
    final hospitalsWithCoords = hospitals
        .where((h) => h.latitude != null && h.longitude != null)
        .toList();

    return Stack(
      children: [
        // OpenStreetMap Interactive Canvas
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: userLatLng,
            initialZoom: 13.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
            onTap: (_, __) {
              if (_selectedHospital != null) {
                setState(() => _selectedHospital = null);
              }
            },
          ),
          children: [
            // Map Tile Layer (OpenStreetMap)
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.medilink.app',
              maxZoom: 19,
            ),

            // Markers with custom tags on map
            MarkerLayer(
              markers: [
                // 1. User Live Location Marker (Pulsing blue dot with tag)
                if (_currentPosition != null)
                  Marker(
                    point: userLatLng,
                    width: 100,
                    height: 60,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade800,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Text(
                            'You Are Here',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade600,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.4),
                                blurRadius: 8,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // 2. Hospital Markers with Location Tags
                ...hospitalsWithCoords.map((hospital) {
                  final isSelected = _selectedHospital?.id == hospital.id ||
                      _selectedHospital?.name == hospital.name;
                  double? distKm;
                  if (_currentPosition != null) {
                    distKm = EmergencyService.calculateDistance(
                      lat1: _currentPosition!.latitude,
                      lon1: _currentPosition!.longitude,
                      lat2: hospital.latitude!,
                      lon2: hospital.longitude!,
                    );
                  }

                  return Marker(
                    point: LatLng(hospital.latitude!, hospital.longitude!),
                    width: 150,
                    height: 70,
                    child: GestureDetector(
                      onTap: () => _selectHospital(hospital),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Hospital Tag Pill over location
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? Colors.white : AppColors.primary,
                                width: isSelected ? 2 : 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.local_hospital,
                                  size: 13,
                                  color: isSelected ? Colors.white : AppColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    hospital.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.black87,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (distKm != null) ...[
                                  const SizedBox(width: 4),
                                  Text(
                                    '(${LocationService.formatDistance(distKm)})',
                                    style: TextStyle(
                                      color: isSelected ? Colors.white70 : Colors.blue.shade700,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // Pin Needle / Icon
                          Icon(
                            Icons.location_on,
                            size: isSelected ? 34 : 26,
                            color: isSelected ? AppColors.primary : Colors.red.shade700,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),

        // Top Location Bar
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.person_pin_circle, color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Your Location',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'GPS Live',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _currentPlaceName,
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Text(
                  '${hospitalsWithCoords.length} Hospitals on Map',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Zoom & Recenter Controls
        Positioned(
          right: 16,
          bottom: _selectedHospital != null ? 220 : 20,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.small(
                heroTag: 'zoomInBtn',
                backgroundColor: Colors.white,
                child: const Icon(Icons.add, color: Colors.black87),
                onPressed: () {
                  final zoom = _mapController.camera.zoom + 1;
                  _mapController.move(_mapController.camera.center, zoom);
                },
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'zoomOutBtn',
                backgroundColor: Colors.white,
                child: const Icon(Icons.remove, color: Colors.black87),
                onPressed: () {
                  final zoom = _mapController.camera.zoom - 1;
                  _mapController.move(_mapController.camera.center, zoom);
                },
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'recenterBtn',
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.my_location, color: Colors.white),
                onPressed: _centerOnUser,
              ),
            ],
          ),
        ),

        // Selected Hospital Bottom Card
        if (_selectedHospital != null)
          Positioned(
            left: 12,
            right: 12,
            bottom: 16,
            child: _buildSelectedHospitalCard(_selectedHospital!),
          ),
      ],
    );
  }

  /// Popup card shown when user taps on any hospital tag on the map
  Widget _buildSelectedHospitalCard(Hospital hospital) {
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
      elevation: 10,
      shadowColor: Colors.black38,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        hospital.address,
                        style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => setState(() => _selectedHospital = null),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (distKm != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '📍 ${LocationService.formatDistance(distKm)}',
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                if (hospital.contact.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.phone, size: 14, color: AppColors.textSecondaryLight),
                  const SizedBox(width: 4),
                  Text(
                    hospital.contact,
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.medical_services, size: 16),
                    label: const Text('View Doctors'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DoctorListScreen(
                            hospitalName: hospital.name,
                            hospitalId: (hospital.id != null && hospital.id!.isNotEmpty)
                                ? hospital.id!
                                : hospital.name,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.directions, size: 16, color: Colors.white),
                    label: const Text('Open Map', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                          const SnackBar(content: Text('Hospital coordinates not set')),
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
  }

  /// List View fallback
  Widget _buildHospitalListView(List<Hospital> hospitals) {
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

    return ListView.builder(
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
                                hospitalId: (hospital.id != null && hospital.id!.isNotEmpty)
                                    ? hospital.id!
                                    : hospital.name,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.map, size: 16, color: Colors.white),
                        label: const Text('View on Map', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        onPressed: () {
                          setState(() {
                            _isMapView = true;
                            _selectedHospital = hospital;
                          });
                          if (hospital.latitude != null && hospital.longitude != null) {
                            _mapController.move(
                              LatLng(hospital.latitude!, hospital.longitude!),
                              15.0,
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
    );
  }
}

