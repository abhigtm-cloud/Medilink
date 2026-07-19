import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medilink/features/emergency/domain/entities/emergency_request.dart';

class EmergencyRequestModel extends EmergencyRequest {
  const EmergencyRequestModel({
    required super.id,
    required super.patientUid,
    required super.status,
    required super.priority,
    required super.emergencyType,
    required super.patientLocation,
    super.selectedHospitalId,
    super.distanceKm,
    super.etaMinutes,
    super.assignedDoctorId,
    super.assignedAmbulanceId,
    super.cancelReason,
    super.rejectReason,
    super.createdAt,
    super.acceptedAt,
    super.arrivedAt,
    super.completedAt,
    super.cancelledAt,
  });

  factory EmergencyRequestModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final location = data['patientLocation'] as GeoPoint?;

    DateTime? ts(String key) => (data[key] as Timestamp?)?.toDate();

    return EmergencyRequestModel(
      id: doc.id,
      patientUid: data['patientUid'] as String? ?? '',
      status: EmergencyStatus.fromValue(data['status'] as String?),
      priority: EmergencyPriority.fromValue(data['priority'] as String?),
      emergencyType: EmergencyType.values.firstWhere(
        (t) => t.name == data['emergencyType'],
        orElse: () => EmergencyType.unspecified,
      ),
      patientLocation: GeoPointValue(
        latitude: location?.latitude ?? 0,
        longitude: location?.longitude ?? 0,
      ),
      selectedHospitalId: data['selectedHospitalId'] as String?,
      distanceKm: (data['distanceKm'] as num?)?.toDouble(),
      etaMinutes: (data['etaMinutes'] as num?)?.toDouble(),
      assignedDoctorId: data['assignedDoctorId'] as String?,
      assignedAmbulanceId: data['assignedAmbulanceId'] as String?,
      cancelReason: data['cancelReason'] as String?,
      rejectReason: data['rejectReason'] as String?,
      createdAt: ts('createdAt'),
      acceptedAt: ts('acceptedAt'),
      arrivedAt: ts('arrivedAt'),
      completedAt: ts('completedAt'),
      cancelledAt: ts('cancelledAt'),
    );
  }

  factory EmergencyRequestModel.fromJson(Map<String, dynamic> json) {
    final loc = json['patientLocation'] as Map?;
    DateTime? dt(String key) =>
        json[key] != null ? DateTime.tryParse(json[key] as String) : null;

    return EmergencyRequestModel(
      id: json['id'] as String,
      patientUid: json['patientUid'] as String? ?? '',
      status: EmergencyStatus.fromValue(json['status'] as String?),
      priority: EmergencyPriority.fromValue(json['priority'] as String?),
      emergencyType: EmergencyType.values.firstWhere(
        (t) => t.name == json['emergencyType'],
        orElse: () => EmergencyType.unspecified,
      ),
      patientLocation: GeoPointValue(
        latitude: (loc?['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (loc?['longitude'] as num?)?.toDouble() ?? 0,
      ),
      selectedHospitalId: json['selectedHospitalId'] as String?,
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      etaMinutes: (json['etaMinutes'] as num?)?.toDouble(),
      createdAt: dt('createdAt'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientUid': patientUid,
      'status': status.name,
      'priority': priority.name,
      'emergencyType': emergencyType.name,
      'patientLocation': {
        'latitude': patientLocation.latitude,
        'longitude': patientLocation.longitude,
      },
      'selectedHospitalId': selectedHospitalId,
      'distanceKm': distanceKm,
      'etaMinutes': etaMinutes,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
