import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_theme.dart';
import 'package:medilink/core/services/location_service.dart';
import 'package:medilink/core/services/emergency_service.dart';
import 'package:medilink/features/home/screens/doctor_list_screen.dart';
import 'package:medilink/features/home/screens/search_screen.dart';
import 'package:medilink/features/home/screens/bookings_screen.dart';
import 'package:medilink/features/home/screens/account_screen.dart';
import 'package:medilink/features/home/screens/hospital_map_screen.dart';
import 'package:medilink/features/auth/screens/login_screen.dart';
import 'package:medilink/features/auth/providers/auth_providers.dart';
import 'package:medilink/features/home/providers/hospital_provider.dart';
import 'package:medilink/features/home/providers/slot_provider.dart';
import 'package:medilink/features/home/models/hospital.dart';

/// User home screen for browsing hospitals and booking appointments
class UserHomeScreen extends ConsumerStatefulWidget {
  const UserHomeScreen({super.key});

  @override
  ConsumerState<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends ConsumerState<UserHomeScreen> {
  int _selectedBottomNav = 0;
  Position? _currentPosition;
  bool _loadingLocation = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    final position = await LocationService.getCurrentLocation();
    if (mounted) {
      setState(() {
        _currentPosition = position;
        _loadingLocation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    PreferredSizeWidget? appBar;
    Widget? drawer;

    switch (_selectedBottomNav) {
      case 0:
        body = SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLocationSection(),
              _buildPromoSection(),
              _buildNearbyHospitalsSection(),
            ],
          ),
        );
        appBar = _buildAppBar();
        drawer = _buildDrawer();
        break;
      case 1:
        body = const SearchScreen();
        break;
      case 2:
        body = const BookingsScreen();
        break;
      case 3:
        body = const HospitalMapScreen();
        break;
      case 4:
        body = const AccountScreen();
        break;
      default:
        body = const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: appBar,
      drawer: drawer,
      body: body,
      floatingActionButton: _selectedBottomNav == 0 ? _buildEmergencyButton() : null,
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildEmergencyButton() {
    return FloatingActionButton.extended(
      onPressed: _handleEmergency,
      backgroundColor: Colors.red,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.emergency),
      label: const Text('EMERGENCY'),
    );
  }

  Future<void> _handleEmergency() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Finding Nearest Hospital...'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Locating your position...'),
          ],
        ),
      ),
    );

    try {
      // Get all hospitals
      final hospitalsAsync = ref.read(getAllHospitalsProvider);
      final hospitals = hospitalsAsync.value ?? [];

      if (hospitals.isEmpty) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hospitals available')),
        );
        return;
      }

      // Get user's current location
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Find nearest hospital with coordinates
      var nearestHospital = hospitals.first;
      var minDistance = double.infinity;

      for (final hospital in hospitals) {
        if (hospital.latitude != null && hospital.longitude != null) {
          final distance = EmergencyService.calculateDistance(
            lat1: position.latitude,
            lon1: position.longitude,
            lat2: hospital.latitude!,
            lon2: hospital.longitude!,
          );

          if (distance < minDistance) {
            minDistance = distance;
            nearestHospital = hospital;
          }
        }
      }

      Navigator.pop(context); // Close loading dialog

      // Navigate to that hospital's doctor list
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DoctorListScreen(
            hospitalName: nearestHospital.name,
            hospitalId: nearestHospital.id ?? '',
          ),
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.cardLight,
      elevation: 1,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu, color: AppColors.primary),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: const Text(
        'MEDILINK',
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: AppColors.primary),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.account_circle_outlined, color: AppColors.primary),
          onPressed: () {},
        ),
      ],
      centerTitle: false,
    );
  }

  Widget _buildDrawer() {
    final userAsync = ref.watch(authStateChangesProvider);
    return Drawer(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                  ),
                  child: userAsync.when(
                    data: (user) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.4),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              size: 32,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            user?.displayName ?? 'User',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? '',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      );
                    },
                    loading: () => const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                    error: (_, __) => const Text('Error loading user', style: TextStyle(color: Colors.white)),
                  ),
                ),
                Divider(height: 1, color: AppColors.dividerLight),
                _buildDrawerMenuItem(
                  icon: Icons.home_outlined,
                  label: 'Home',
                  onTap: () {
                    setState(() => _selectedBottomNav = 0);
                    Navigator.pop(context);
                  },
                ),
                _buildDrawerMenuItem(
                  icon: Icons.search_outlined,
                  label: 'Search',
                  onTap: () {
                    setState(() => _selectedBottomNav = 1);
                    Navigator.pop(context);
                  },
                ),
                _buildDrawerMenuItem(
                  icon: Icons.calendar_today_outlined,
                  label: 'My Bookings',
                  onTap: () {
                    setState(() => _selectedBottomNav = 2);
                    Navigator.pop(context);
                  },
                ),
                _buildDrawerMenuItem(
                  icon: Icons.map_outlined,
                  label: 'Hospitals Map',
                  onTap: () {
                    setState(() => _selectedBottomNav = 3);
                    Navigator.pop(context);
                  },
                ),
                _buildDrawerMenuItem(
                  icon: Icons.person_outline,
                  label: 'Account',
                  onTap: () {
                    setState(() => _selectedBottomNav = 4);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.dividerLight),
          _buildDrawerMenuItem(
            icon: Icons.logout_rounded,
            label: 'Logout',
            onTap: () {
              ref.read(authControllerProvider.notifier).signOut();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            isDestructive: true,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDrawerMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final textColor = isDestructive ? AppColors.error : AppColors.textPrimaryLight;
    final iconColor = isDestructive ? AppColors.error : AppColors.primary;

    return ListTile(
      leading: Icon(icon, color: iconColor, size: 22),
      title: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      minLeadingWidth: 24,
      onTap: onTap,
    );
  }

  Widget _buildLocationSection() {
    return Container(
      color: AppColors.cardLight,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.location_on, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Location',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                if (_loadingLocation)
                  Text(
                    'Loading location...',
                    style: Theme.of(context).textTheme.titleSmall,
                  )
                else if (_currentPosition != null)
                  Text(
                    '${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}',
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                else
                  Text(
                    'Location not available',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.error,
                        ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: AppColors.primary,
              size: 20,
            ),
            onPressed: _loadingLocation ? null : _loadCurrentLocation,
          ),
        ],
      ),
    );
  }

  Widget _buildPromoSection() {
    return Container(
      color: AppColors.cardLight,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 8),
      child: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.healthcareGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'First Time Discount',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Get 20% off on your first appointment',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                    ),
                    child: const Text(
                      'Explore',
                      style: TextStyle(
                        color: Color(0xFF20B2AA),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            const Icon(Icons.local_offer, color: Colors.white, size: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildNearbyHospitalsSection() {
    final hospitalsAsync = ref.watch(getAllHospitalsProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Available Hospitals',
                style: TextStyle(
                  color: Color(0xFF1A1A2E),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'View all',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        hospitalsAsync.when(
          data: (hospitals) {
            if (hospitals.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.local_hospital_outlined, size: 48, color: AppColors.borderLight),
                      const SizedBox(height: 12),
                      Text(
                        'No hospitals found',
                        style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              );
            }
            
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: hospitals.length,
              itemBuilder: (context, index) =>
                  _buildHospitalCard(hospitals[index]),
            );
          },
          loading: () => Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            ),
          ),
          error: (error, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text(
                    'Failed to load hospitals',
                    style: TextStyle(color: AppColors.error, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHospitalCard(Hospital hospital) {
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
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.cardLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hospital Header with Photo or Icon
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: AppTheme.healthcareGradient,
                ),
                child: hospital.photoUrl != null
                    ? Image.memory(
                        base64Decode(hospital.photoUrl!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(
                              Icons.local_hospital,
                              size: 48,
                              color: Colors.white,
                            ),
                          );
                        },
                      )
                    : Center(
                        child: Icon(
                          Icons.local_hospital,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
              ),
              // Hospital Info
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hospital.name,
                      style: TextStyle(
                        color: AppColors.textPrimaryLight,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Address
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            hospital.address,
                            style: TextStyle(
                              color: AppColors.textSecondaryLight,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Contact
                    Row(
                      children: [
                        Icon(Icons.phone,
                            size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          hospital.contact,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // View Doctors Button
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
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
                            child: const Text(
                              'View Doctors',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: hospital.latitude != null && hospital.longitude != null
                                ? () => LocationService.openGoogleMaps(
                                      latitude: hospital.latitude!,
                                      longitude: hospital.longitude!,
                                      locationName: hospital.name,
                                    )
                                : null,
                            child: const Icon(
                              Icons.directions,
                              color: Colors.white,
                              size: 18,
                            ),
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
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return BottomNavigationBar(
      currentIndex: _selectedBottomNav,
      onTap: (index) => setState(() => _selectedBottomNav = index),
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.cardLight,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondaryLight,
      elevation: 8,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Bookings'),
        BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Maps'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
      ],
    );
  }
}
