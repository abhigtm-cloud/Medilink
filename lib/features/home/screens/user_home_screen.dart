import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_theme.dart';
import 'package:medilink/core/services/location_service.dart';
import 'package:medilink/features/home/screens/doctor_list_screen.dart';
import 'package:medilink/features/home/screens/search_screen.dart';
import 'package:medilink/features/home/screens/bookings_screen.dart';
import 'package:medilink/features/home/screens/account_screen.dart';
import 'package:medilink/features/home/screens/hospital_map_screen.dart';
import 'package:medilink/core/services/cache_service.dart';
import 'package:medilink/features/emergency/domain/entities/emergency_request.dart';
import 'package:medilink/features/emergency/presentation/widgets/sos_button.dart';
import 'package:medilink/features/emergency/presentation/providers/emergency_providers.dart';
import 'package:medilink/features/emergency/presentation/screens/emergency_tracking_screen.dart';
import 'package:medilink/features/auth/screens/login_screen.dart';
import 'package:medilink/features/auth/providers/auth_providers.dart';
import 'package:medilink/features/home/providers/hospital_provider.dart';
import 'package:medilink/features/home/models/hospital.dart';
import 'package:medilink/features/notifications/presentation/providers/notification_center_providers.dart';
import 'package:medilink/features/notifications/presentation/screens/notification_center_screen.dart';
import 'package:medilink/features/pharmacy/presentation/screens/medicine_search_screen.dart';
import 'package:medilink/features/pharmacy/presentation/screens/prescription_upload_screen.dart';
import 'package:medilink/features/ai_assistant/presentation/screens/ai_assistant_screen.dart';
import 'package:medilink/features/medication_reminders/presentation/screens/medication_reminders_screen.dart';
import 'package:url_launcher/url_launcher.dart';

/// User home screen for browsing hospitals and booking appointments
class UserHomeScreen extends ConsumerStatefulWidget {
  const UserHomeScreen({super.key});

  @override
  ConsumerState<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends ConsumerState<UserHomeScreen> {
  int _selectedBottomNav = 0;
  Position? _currentPosition;
  String? _currentPlaceName;
  bool _loadingLocation = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
    _resumeActiveEmergencyIfAny();
  }

  /// If the app was killed/reopened mid-emergency, restore active emergency state
  Future<void> _resumeActiveEmergencyIfAny() async {
    final requestId =
        await ref.read(emergencyRepositoryProvider).getCachedActiveRequestId() ??
        CacheService.getActiveEmergencyId();
    if (requestId == null || !mounted) return;
    ref.read(activeEmergencyIdProvider.notifier).state = requestId;
  }

  Future<void> _loadCurrentLocation() async {
    final position = await LocationService.getCurrentLocation();
    if (mounted) {
      String? placeName;
      if (position != null) {
        placeName = await LocationService.getPlaceName(
          position.latitude,
          position.longitude,
        );
      }
      setState(() {
        _currentPosition = position;
        _currentPlaceName = placeName;
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
      body: Column(
        children: [
          const ActiveEmergencyBanner(),
          Expanded(child: body),
        ],
      ),
      floatingActionButton: _selectedBottomNav == 0 ? const SosButton() : null,
      bottomNavigationBar: _buildBottomNavigation(),
    );
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
        Consumer(
          builder: (context, ref, _) {
            final unreadCount = ref.watch(unreadNotificationCountProvider);
            return IconButton(
              icon: Badge(
                isLabelVisible: unreadCount > 0,
                label: Text('$unreadCount'),
                child: const Icon(Icons.notifications_outlined, color: AppColors.primary),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationCenterScreen()),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.account_circle_outlined, color: AppColors.primary),
          onPressed: () => setState(() => _selectedBottomNav = 4),
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
                Divider(height: 1, color: AppColors.dividerLight),
                _buildDrawerMenuItem(
                  icon: Icons.medication_outlined,
                  label: 'Pharmacy',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MedicineSearchScreen()),
                    );
                  },
                ),
                _buildDrawerMenuItem(
                  icon: Icons.receipt_long_outlined,
                  label: 'Upload Prescription',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PrescriptionUploadScreen()),
                    );
                  },
                ),
                Divider(height: 1, color: AppColors.dividerLight),
                _buildDrawerMenuItem(
                  icon: Icons.smart_toy_outlined,
                  label: 'AI Health Assistant',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AiAssistantScreen()),
                    );
                  },
                ),
                _buildDrawerMenuItem(
                  icon: Icons.alarm_outlined,
                  label: 'Medication Reminders',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MedicationRemindersScreen()),
                    );
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
                else if (_currentPosition != null && _currentPlaceName != null)
                  Text(
                    _currentPlaceName!,
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            hospital.name,
                            style: TextStyle(
                              color: AppColors.textPrimaryLight,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () async {
                            final rawPhone = hospital.contact.replaceAll(RegExp(r'[^0-9+]'), '');
                            final uri = Uri.parse('tel:$rawPhone');
                            try {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            } catch (_) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Hospital Phone: ${hospital.contact}')),
                                );
                              }
                            }
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.success.withOpacity(0.3)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.phone_in_talk, size: 14, color: AppColors.success),
                                SizedBox(width: 4),
                                Text(
                                  'Call',
                                  style: TextStyle(
                                    color: AppColors.success,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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

/// Floating persistent emergency notification banner visible across the app
/// whenever an emergency SOS request is active.
class ActiveEmergencyBanner extends ConsumerWidget {
  const ActiveEmergencyBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeId = ref.watch(activeEmergencyIdProvider);
    if (activeId == null || activeId.isEmpty) {
      return const SizedBox.shrink();
    }

    final emergencyAsync = ref.watch(watchEmergencyProvider(activeId));

    return emergencyAsync.when(
      data: (request) {
        final isClosed = request.status == EmergencyStatus.cancelled ||
            request.status == EmergencyStatus.completed ||
            request.status == EmergencyStatus.rejected;

        if (isClosed) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red.shade700, Colors.red.shade900],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.emergency,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'EMERGENCY SOS IN PROGRESS',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          '${request.emergencyType.label} • ${request.status.label}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'ETA: ~${request.etaMinutes?.toInt() ?? 5}m',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.red.shade800,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.location_on, size: 16),
                      label: const Text(
                        'Live Tracking Screen',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EmergencyTrackingScreen(requestId: request.id),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Cancel Emergency?'),
                          content: const Text(
                            'Are you sure you want to cancel this emergency SOS?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('No'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Yes, Cancel'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await ref
                            .read(emergencyRepositoryProvider)
                            .cancelEmergency(request.id, 'Cancelled by patient from banner');
                        await CacheService.setActiveEmergencyId(null);
                        ref.read(activeEmergencyIdProvider.notifier).state = null;
                      }
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
