import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medilink/features/emergency/domain/entities/emergency_request.dart';
import 'package:medilink/features/emergency/domain/entities/emergency_timeline_event.dart';

class TimelineEventModel extends EmergencyTimelineEvent {
  const TimelineEventModel({
    required super.id,
    required super.status,
    required super.label,
    required super.timestamp,
    super.actorRole,
  });

  factory TimelineEventModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final ts = data['timestamp'] as Timestamp?;
    return TimelineEventModel(
      id: doc.id,
      status: EmergencyStatus.fromValue(data['status'] as String?),
      label: data['label'] as String? ?? '',
      actorRole: data['actorRole'] as String?,
      timestamp: ts?.toDate() ?? DateTime.now(),
    );
  }
}
