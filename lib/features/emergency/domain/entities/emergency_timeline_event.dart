import 'package:medilink/features/emergency/domain/entities/emergency_request.dart';

/// One entry in an emergency request's append-only audit trail
/// (`emergency_requests/{id}/timeline`). This is the direct data source for
/// the patient's live status stepper. See architecture doc §4.3.
class EmergencyTimelineEvent {
  final String id;
  final EmergencyStatus status;
  final String label;
  final String? actorRole;
  final DateTime timestamp;

  const EmergencyTimelineEvent({
    required this.id,
    required this.status,
    required this.label,
    required this.timestamp,
    this.actorRole,
  });
}
