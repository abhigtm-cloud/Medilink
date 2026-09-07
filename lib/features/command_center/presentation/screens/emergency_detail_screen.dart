import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:medilink/core/error/failures.dart';
import 'package:medilink/core/services/location_service.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/features/ambulance/domain/entities/ambulance.dart';
import 'package:medilink/features/ambulance/presentation/providers/ambulance_providers.dart';
import 'package:medilink/features/command_center/domain/repositories/command_center_repository.dart';
import 'package:medilink/features/command_center/presentation/providers/command_center_providers.dart';
import 'package:medilink/features/command_center/presentation/widgets/emergency_priority_badge.dart';
import 'package:medilink/features/emergency/domain/entities/emergency_request.dart';
import 'package:medilink/features/emergency/presentation/providers/emergency_providers.dart';
import 'package:medilink/features/emergency/presentation/widgets/emergency_status_timeline.dart';
import 'package:medilink/features/home/providers/doctor_provider.dart';

/// Full patient snapshot + action bar for hospital staff. Every action here
/// is a Callable Function (never a direct client status write) so the
/// state machine stays enforced in exactly one place server-side — see
/// architecture doc §9.
class EmergencyDetailScreen extends ConsumerWidget {
  const EmergencyDetailScreen({super.key, required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestAsync = ref.watch(watchEmergencyProvider(requestId));
    final timelineAsync = ref.watch(watchEmergencyTimelineProvider(requestId));

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(title: const Text('Emergency Details')),
      body: requestAsync.when(
        data: (request) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(request),
              const SizedBox(height: 16),
              _buildPatientCard(request),
              const SizedBox(height: 16),
              if (request.staffInstructions.isNotEmpty) ...[
                _buildInstructionsCard(request),
                const SizedBox(height: 16),
              ],
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Timeline',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      timelineAsync.when(
                        data: (events) => EmergencyStatusTimeline(events: events),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Text('Unable to load timeline: $e'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _ActionBar(request: request),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Unable to load: $error')),
      ),
    );
  }

  Widget _buildHeader(EmergencyRequest request) {
    return Card(
      color: AppColors.primary,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.emergencyType.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(request.status.label, style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            EmergencyPriorityBadge(priority: request.priority),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientCard(EmergencyRequest request) {
    final snapshot = request.patientSnapshot;
    final location = request.patientLocation;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.person_pin_circle, color: AppColors.primary, size: 22),
                    SizedBox(width: 8),
                    Text('Patient Info & Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                if (request.distanceKm != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${request.distanceKm!.toStringAsFixed(1)} km away',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Live Location Card & Navigation Button
            if (location != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.25)),
                ),
                child: Column(
                  children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.red, size: 28),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Patient Live Location',
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.red),
                                ),
                                FutureBuilder<String>(
                                  future: LocationService.getPlaceName(location.latitude, location.longitude),
                                  builder: (context, placeSnapshot) {
                                    final place = placeSnapshot.data ?? 'Resolving location address...';
                                    return Text(
                                      place,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.navigation, color: Colors.white, size: 18),
                        label: const Text(
                          'Open Patient Location in Google Maps',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          LocationService.openGoogleMaps(
                            latitude: location.latitude,
                            longitude: location.longitude,
                            locationName: 'Emergency Patient: ${snapshot?.name ?? "Patient"}',
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Patient Medical & Contact Details
            if (snapshot == null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Patient UID: ${request.patientUid}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    const Text('Detailed profile snapshot loading from database...'),
                  ],
                ),
              )
            else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.account_circle, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            snapshot.name,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                        ),
                        if (snapshot.bloodGroup != null && snapshot.bloodGroup!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.red.shade300),
                            ),
                            child: Text(
                              'Blood: ${snapshot.bloodGroup}',
                              style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                      ],
                    ),
                    if (snapshot.age != null) ...[
                      const SizedBox(height: 6),
                      Text('• Age: ${snapshot.age} years', style: const TextStyle(fontSize: 13)),
                    ],
                    if (snapshot.medicalConditions.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        '• Medical Conditions: ${snapshot.medicalConditions.join(', ')}',
                        style: TextStyle(fontSize: 13, color: Colors.orange.shade900, fontWeight: FontWeight.w500),
                      ),
                    ],
                    if (snapshot.emergencyContactName != null && snapshot.emergencyContactName!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        '• Emergency Contact: ${snapshot.emergencyContactName} (${snapshot.emergencyContactPhone ?? 'No Phone'})',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
              if (snapshot.phoneNumber != null && snapshot.phoneNumber!.isNotEmpty) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.call, color: AppColors.primary),
                    label: Text('Call Patient (${snapshot.phoneNumber})', style: const TextStyle(fontWeight: FontWeight.w600)),
                    onPressed: () => launchUrl(Uri.parse('tel:${snapshot.phoneNumber}')),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionsCard(EmergencyRequest request) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Instructions Sent',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            for (final text in request.staffInstructions) Text('• $text'),
          ],
        ),
      ),
    );
  }
}

class _ActionBar extends ConsumerStatefulWidget {
  const _ActionBar({required this.request});

  final EmergencyRequest request;

  @override
  ConsumerState<_ActionBar> createState() => _ActionBarState();
}

class _ActionBarState extends ConsumerState<_ActionBar> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    await action();
    if (mounted) setState(() => _busy = false);
  }

  void _showFailure(Object failure) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$failure')));
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.request.status;
    final repo = ref.read(commandCenterRepositoryProvider);

    // Initial state requiring hospital approval
    if (status == EmergencyStatus.hospitalAssigned ||
        status == EmergencyStatus.requested ||
        status == EmergencyStatus.searchingHospital) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check_circle, color: Colors.white),
              label: const Text('Accept / Approve', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: _busy
                  ? null
                  : () => _run(() async {
                        final result = await repo.acceptEmergency(widget.request.id);
                        result.match(
                          _showFailure,
                          (_) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  backgroundColor: AppColors.success,
                                  content: Text('Emergency Case Approved! Medical team mobilized.'),
                                ),
                              );
                            }
                          },
                        );
                      }),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.cancel, color: AppColors.error),
              label: const Text('Reject', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: AppColors.error),
              ),
              onPressed: _busy ? null : () => _showReasonDialog(context, 'Reject Emergency',
                  (reason) => repo.rejectEmergency(widget.request.id, reason)),
            ),
          ),
        ],
      );
    }

    if (status == EmergencyStatus.accepted ||
        status == EmergencyStatus.doctorAssigned ||
        status == EmergencyStatus.ambulanceDispatched ||
        status == EmergencyStatus.hospitalReady ||
        status == EmergencyStatus.patientEnRoute) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (status == EmergencyStatus.accepted || widget.request.assignedDoctorId == null)
            ElevatedButton.icon(
              icon: const Icon(Icons.medical_services),
              label: const Text('Assign Doctor'),
              onPressed: _busy ? null : () => _showDoctorPicker(context, repo),
            ),
          if (widget.request.assignedAmbulanceId == null) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.local_shipping),
              label: const Text('Dispatch Ambulance'),
              onPressed: _busy ? null : () => _showAmbulancePicker(context),
            ),
          ],
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.message),
            label: const Text('Send Instructions'),
            onPressed: _busy ? null : () => _showReasonDialog(context, 'Send Instructions',
                (text) => repo.sendInstruction(widget.request.id, text),
                label: 'Message'),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.local_hospital),
            label: const Text('Mark Patient Arrived'),
            onPressed: _busy
                ? null
                : () => _run(() async {
                      final result = await repo.markArrived(widget.request.id);
                      result.match(_showFailure, (_) {});
                    }),
          ),
        ],
      );
    }

    if (status == EmergencyStatus.reachedHospital || status == EmergencyStatus.treatmentStarted) {
      return ElevatedButton.icon(
        icon: const Icon(Icons.task_alt),
        label: const Text('Close Emergency'),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
        onPressed: _busy ? null : () => _showReasonDialog(context, 'Close Emergency',
            (outcome) => repo.closeEmergency(widget.request.id, outcome),
            label: 'Outcome (e.g. "Treated and discharged")'),
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _showReasonDialog(
    BuildContext context,
    String title,
    Future<Either<Failure, Unit>> Function(String) action, {
    String label = 'Reason',
  }) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: label),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Submit')),
        ],
      ),
    );
    if (confirmed != true || controller.text.trim().isEmpty) return;
    await _run(() async {
      final result = await action(controller.text.trim());
      result.match(_showFailure, (_) {});
    });
  }

  Future<void> _showDoctorPicker(BuildContext context, CommandCenterRepository repo) async {
    final hospitalId = widget.request.selectedHospitalId;
    if (hospitalId == null) return;

    final doctors = await ref.read(getDoctorsByHospitalProvider(hospitalId).future);
    if (!context.mounted) return;
    if (doctors.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No doctors found for this hospital')));
      return;
    }

    final doctorId = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Doctor'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: doctors
                .map((doctor) => ListTile(
                      title: Text(doctor.name),
                      subtitle: Text(doctor.specialization),
                      onTap: () => Navigator.pop(context, doctor.id),
                    ))
                .toList(),
          ),
        ),
      ),
    );
    if (doctorId == null) return;

    await _run(() async {
      final result = await repo.assignDoctor(widget.request.id, doctorId);
      result.match(_showFailure, (_) {});
    });
  }

  Future<void> _showAmbulancePicker(BuildContext context) async {
    final hospitalId = widget.request.selectedHospitalId;
    if (hospitalId == null) return;

    final fleet = await ref.read(hospitalFleetProvider(hospitalId).future);
    final available = fleet.where((a) => a.status == AmbulanceStatus.available).toList();
    if (!context.mounted) return;
    if (available.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No ambulances available right now')));
      return;
    }

    final ambulanceId = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dispatch Ambulance'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: available
                .map((ambulance) => ListTile(
                      title: Text(ambulance.vehicleNumber),
                      subtitle: Text('${ambulance.driverName} · ${ambulance.driverPhone}'),
                      onTap: () => Navigator.pop(context, ambulance.id),
                    ))
                .toList(),
          ),
        ),
      ),
    );
    if (ambulanceId == null) return;

    await _run(() async {
      final result =
          await ref.read(ambulanceRepositoryProvider).dispatchAmbulance(widget.request.id, ambulanceId);
      result.match(_showFailure, (_) {});
    });
  }
}
