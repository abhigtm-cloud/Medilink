import 'package:medilink/features/emergency/domain/entities/emergency_request.dart';

enum AmbulanceStatus {
  available,
  dispatched,
  offline,
  maintenance;

  static AmbulanceStatus fromValue(String? value) {
    return AmbulanceStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => AmbulanceStatus.offline,
    );
  }

  String get label {
    switch (this) {
      case AmbulanceStatus.available:
        return 'Available';
      case AmbulanceStatus.dispatched:
        return 'Dispatched';
      case AmbulanceStatus.offline:
        return 'Offline';
      case AmbulanceStatus.maintenance:
        return 'Maintenance';
    }
  }
}

class Ambulance {
  final String id;
  final String hospitalId;
  final String vehicleNumber;
  final String? driverUid;
  final String driverName;
  final String driverPhone;
  final AmbulanceStatus status;
  final GeoPointValue? currentLocation;
  final String? activeTripId;

  const Ambulance({
    required this.id,
    required this.hospitalId,
    required this.vehicleNumber,
    required this.driverName,
    required this.driverPhone,
    required this.status,
    this.driverUid,
    this.currentLocation,
    this.activeTripId,
  });
}

enum AmbulanceTripStatus {
  dispatched,
  completed;

  static AmbulanceTripStatus fromValue(String? value) {
    return AmbulanceTripStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => AmbulanceTripStatus.dispatched,
    );
  }
}

class AmbulanceTrip {
  final String id;
  final String emergencyRequestId;
  final String hospitalId;
  final String ambulanceId;
  final AmbulanceTripStatus status;
  final DateTime? dispatchedAt;
  final DateTime? completedAt;

  const AmbulanceTrip({
    required this.id,
    required this.emergencyRequestId,
    required this.hospitalId,
    required this.ambulanceId,
    required this.status,
    this.dispatchedAt,
    this.completedAt,
  });
}
