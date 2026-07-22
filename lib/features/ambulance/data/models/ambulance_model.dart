import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medilink/features/ambulance/domain/entities/ambulance.dart';
import 'package:medilink/features/emergency/domain/entities/emergency_request.dart';

class AmbulanceModel extends Ambulance {
  const AmbulanceModel({
    required super.id,
    required super.hospitalId,
    required super.vehicleNumber,
    required super.driverName,
    required super.driverPhone,
    required super.status,
    super.driverUid,
    super.currentLocation,
    super.activeTripId,
  });

  factory AmbulanceModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final location = data['currentLocation'] as GeoPoint?;

    return AmbulanceModel(
      id: doc.id,
      hospitalId: data['hospitalId'] as String? ?? '',
      vehicleNumber: data['vehicleNumber'] as String? ?? '',
      driverName: data['driverName'] as String? ?? '',
      driverPhone: data['driverPhone'] as String? ?? '',
      driverUid: data['driverUid'] as String?,
      status: AmbulanceStatus.fromValue(data['status'] as String?),
      activeTripId: data['activeTripId'] as String?,
      currentLocation: location == null
          ? null
          : GeoPointValue(latitude: location.latitude, longitude: location.longitude),
    );
  }
}
