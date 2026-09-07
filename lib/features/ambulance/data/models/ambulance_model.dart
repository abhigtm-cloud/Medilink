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

  factory AmbulanceModel.fromJson(Map<dynamic, dynamic> data, String id) {
    GeoPointValue? loc;
    if (data['currentLocation'] is Map) {
      final locMap = data['currentLocation'] as Map;
      final lat = (locMap['latitude'] as num?)?.toDouble() ?? (locMap['lat'] as num?)?.toDouble();
      final lng = (locMap['longitude'] as num?)?.toDouble() ?? (locMap['lng'] as num?)?.toDouble();
      if (lat != null && lng != null) {
        loc = GeoPointValue(latitude: lat, longitude: lng);
      }
    }

    return AmbulanceModel(
      id: id,
      hospitalId: data['hospitalId']?.toString() ?? '',
      vehicleNumber: data['vehicleNumber']?.toString() ?? '',
      driverName: data['driverName']?.toString() ?? 'Driver',
      driverPhone: data['driverPhone']?.toString() ?? '',
      driverUid: data['driverUid']?.toString(),
      status: AmbulanceStatus.fromValue(data['status']?.toString()),
      activeTripId: data['activeTripId']?.toString(),
      currentLocation: loc,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'hospitalId': hospitalId,
    'vehicleNumber': vehicleNumber,
    'driverName': driverName,
    'driverPhone': driverPhone,
    if (driverUid != null) 'driverUid': driverUid,
    'status': status.name,
    if (activeTripId != null) 'activeTripId': activeTripId,
    if (currentLocation != null)
      'currentLocation': {
        'latitude': currentLocation!.latitude,
        'longitude': currentLocation!.longitude,
      },
  };
}
