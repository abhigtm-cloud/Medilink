/// A minimal lat/lng value object — domain layer stays free of any
/// Firebase/`cloud_firestore` `GeoPoint` import (see architecture doc §2).
class GeoPointValue {
  final double latitude;
  final double longitude;
  const GeoPointValue({required this.latitude, required this.longitude});
}

enum EmergencyStatus {
  requested,
  searchingHospital,
  hospitalAssigned,
  accepted,
  rejected,
  preparing,
  doctorAssigned,
  icuReserved,
  ambulanceDispatched,
  hospitalReady,
  patientEnRoute,
  reachedHospital,
  treatmentStarted,
  completed,
  cancelled,
  noHospitalFound;

  static EmergencyStatus fromValue(String? value) {
    return EmergencyStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => EmergencyStatus.requested,
    );
  }

  /// Human-readable label for the tracking timeline stepper.
  String get label {
    switch (this) {
      case EmergencyStatus.requested:
        return 'Requested';
      case EmergencyStatus.searchingHospital:
        return 'Finding Nearest Hospital';
      case EmergencyStatus.hospitalAssigned:
        return 'Hospital Assigned';
      case EmergencyStatus.accepted:
        return 'Hospital Accepted';
      case EmergencyStatus.rejected:
        return 'Rejected';
      case EmergencyStatus.preparing:
        return 'Preparing';
      case EmergencyStatus.doctorAssigned:
        return 'Doctor Assigned';
      case EmergencyStatus.icuReserved:
        return 'ICU Reserved';
      case EmergencyStatus.ambulanceDispatched:
        return 'Ambulance Dispatched';
      case EmergencyStatus.hospitalReady:
        return 'Hospital Ready';
      case EmergencyStatus.patientEnRoute:
        return 'Patient En Route';
      case EmergencyStatus.reachedHospital:
        return 'Reached Hospital';
      case EmergencyStatus.treatmentStarted:
        return 'Treatment Started';
      case EmergencyStatus.completed:
        return 'Completed';
      case EmergencyStatus.cancelled:
        return 'Cancelled';
      case EmergencyStatus.noHospitalFound:
        return 'No Hospital Found';
    }
  }

  bool get isTerminal =>
      this == EmergencyStatus.completed ||
      this == EmergencyStatus.cancelled ||
      this == EmergencyStatus.noHospitalFound ||
      this == EmergencyStatus.rejected;

  /// Patient may only cancel before the hospital has committed resources.
  bool get isCancellable =>
      this == EmergencyStatus.requested ||
      this == EmergencyStatus.searchingHospital ||
      this == EmergencyStatus.hospitalAssigned;
}

enum EmergencyPriority {
  critical,
  high,
  medium,
  low;

  static EmergencyPriority fromValue(String? value) {
    return EmergencyPriority.values.firstWhere(
      (p) => p.name == value,
      orElse: () => EmergencyPriority.high,
    );
  }
}

enum EmergencyType {
  cardiac,
  accident,
  breathing,
  unspecified;

  String get label {
    switch (this) {
      case EmergencyType.cardiac:
        return 'Cardiac';
      case EmergencyType.accident:
        return 'Accident';
      case EmergencyType.breathing:
        return 'Breathing Difficulty';
      case EmergencyType.unspecified:
        return 'Other / Not Sure';
    }
  }
}

class EmergencyRequest {
  final String id;
  final String patientUid;
  final EmergencyStatus status;
  final EmergencyPriority priority;
  final EmergencyType emergencyType;
  final String? selectedHospitalId;
  final double? distanceKm;
  final double? etaMinutes;
  final GeoPointValue patientLocation;
  final String? assignedDoctorId;
  final String? assignedAmbulanceId;
  final String? cancelReason;
  final String? rejectReason;
  final DateTime? createdAt;
  final DateTime? acceptedAt;
  final DateTime? arrivedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;

  const EmergencyRequest({
    required this.id,
    required this.patientUid,
    required this.status,
    required this.priority,
    required this.emergencyType,
    required this.patientLocation,
    this.selectedHospitalId,
    this.distanceKm,
    this.etaMinutes,
    this.assignedDoctorId,
    this.assignedAmbulanceId,
    this.cancelReason,
    this.rejectReason,
    this.createdAt,
    this.acceptedAt,
    this.arrivedAt,
    this.completedAt,
    this.cancelledAt,
  });
}
