import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:medilink/core/services/location_service.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/features/emergency/domain/entities/emergency_request.dart';
import 'package:medilink/features/emergency/domain/entities/emergency_timeline_event.dart';
import 'package:medilink/features/emergency/presentation/providers/emergency_providers.dart';
import 'package:medilink/features/emergency/presentation/widgets/emergency_status_timeline.dart';
import 'package:medilink/features/ambulance/presentation/widgets/ambulance_tracking_card.dart';
import 'package:medilink/features/home/models/hospital.dart';
import 'package:medilink/features/home/providers/hospital_provider.dart';

import 'package:medilink/core/services/cache_service.dart';
import 'package:medilink/features/home/screens/home_screen_wrapper.dart';

/// Live tracking screen the patient lands on right after `triggerSos`
/// resolves, and the screen a cold-started app resumes into if an emergency
/// is still active.
class EmergencyTrackingScreen extends ConsumerWidget {
  const EmergencyTrackingScreen({super.key, required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emergencyAsync = ref.watch(watchEmergencyProvider(requestId));
    final timelineAsync = ref.watch(watchEmergencyTimelineProvider(requestId));

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        title: const Text('Emergency Tracking'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Return to Home (Emergency stays submitted & active)',
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            }
          },
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                );
              }
            },
            icon: const Icon(Icons.home, color: Colors.white, size: 18),
            label: const Text(
              'Home',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: emergencyAsync.when(
        data: (request) => _TrackingBody(request: request, timelineAsync: timelineAsync),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Unable to load emergency status: $error'),
          ),
        ),
      ),
    );
  }
}

class _TrackingBody extends ConsumerWidget {
  const _TrackingBody({required this.request, required this.timelineAsync});

  final EmergencyRequest request;
  final AsyncValue<List<EmergencyTimelineEvent>> timelineAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Background Active Info Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.shield_outlined, color: Colors.amber.shade800, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'SOS is submitted and running in background. You can navigate back to Home anytime.',
                    style: TextStyle(fontSize: 12, color: Colors.amber.shade900, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildStatusCard(context),
          const SizedBox(height: 16),
          if (request.selectedHospitalId != null)
            _HospitalCard(hospitalId: request.selectedHospitalId!),
          const SizedBox(height: 16),
          if (request.assignedAmbulanceId != null) ...[
            AmbulanceTrackingCard(ambulanceId: request.assignedAmbulanceId!),
            const SizedBox(height: 16),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Status',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  timelineAsync.when(
                    data: (events) => EmergencyStatusTimeline(events: events),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Text('Unable to load timeline: $error'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (request.status.isCancellable) _buildCancelButton(context, ref),
        ],
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    final color = request.status == EmergencyStatus.noHospitalFound ||
            request.status == EmergencyStatus.cancelled
        ? AppColors.error
        : AppColors.primary;

    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              request.status.label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            if (request.distanceKm != null && request.etaMinutes != null) ...[
              const SizedBox(height: 8),
              Text(
                '${request.distanceKm!.toStringAsFixed(1)} km away · '
                'ETA ~${request.etaMinutes!.toStringAsFixed(0)} min',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCancelButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.cancel, color: AppColors.error),
        label: const Text('Cancel Emergency', style: TextStyle(color: AppColors.error)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.error),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: () => _confirmCancel(context, ref),
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Emergency?'),
        content: const Text(
          'This will notify the hospital that the emergency is no longer needed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final result = await ref
        .read(emergencyRepositoryProvider)
        .cancelEmergency(request.id, 'Cancelled by patient');

    if (!context.mounted) return;
    result.match(
      (failure) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.message))),
      (_) {
        CacheService.setActiveEmergencyId(null);
        ref.read(activeEmergencyIdProvider.notifier).state = null;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Emergency cancelled')));
      },
    );
  }
}

class _HospitalCard extends ConsumerWidget {
  const _HospitalCard({required this.hospitalId});

  final String hospitalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hospitalAsync = ref.watch(getHospitalByIdProvider(hospitalId));

    return hospitalAsync.when(
      data: (hospital) => hospital == null
          ? const SizedBox.shrink()
          : _buildCard(context, hospital),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildCard(BuildContext context, Hospital hospital) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.local_hospital, color: Colors.red, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hospital.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hospital.address,
                        style: TextStyle(
                          color: AppColors.textSecondaryLight,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.phone, color: AppColors.success, size: 26),
                  onPressed: () => launchUrl(Uri.parse('tel:${hospital.contact}')),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.directions, color: Colors.white),
                label: const Text(
                  'OPEN MAP & NAVIGATE TO HOSPITAL',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                      const SnackBar(
                        content: Text('Hospital location coordinates not available'),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

