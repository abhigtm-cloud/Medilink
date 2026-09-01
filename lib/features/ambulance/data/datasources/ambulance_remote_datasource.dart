import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:medilink/core/error/exceptions.dart';
import 'package:medilink/features/ambulance/data/models/ambulance_model.dart';
import 'package:medilink/features/ambulance/data/models/ambulance_trip_model.dart';
import 'package:medilink/features/emergency/domain/entities/emergency_request.dart';

class AmbulanceRemoteDataSource {
  AmbulanceRemoteDataSource({FirebaseFirestore? firestore, FirebaseFunctions? functions})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  Stream<List<AmbulanceModel>> watchHospitalFleet(String hospitalId) {
    return _firestore
        .collection('ambulances')
        .where('hospitalId', isEqualTo: hospitalId)
        .snapshots()
        .map((snap) => snap.docs.map(AmbulanceModel.fromFirestore).toList());
  }

  Stream<AmbulanceModel?> watchDriverAmbulance(String driverUid) {
    return _firestore
        .collection('ambulances')
        .where('driverUid', isEqualTo: driverUid)
        .limit(1)
        .snapshots()
        .map((snap) => snap.docs.isEmpty ? null : AmbulanceModel.fromFirestore(snap.docs.first));
  }

  Stream<AmbulanceModel?> watchAmbulanceById(String ambulanceId) {
    return _firestore
        .collection('ambulances')
        .doc(ambulanceId)
        .snapshots()
        .map((doc) => doc.exists ? AmbulanceModel.fromFirestore(doc) : null);
  }

  Stream<AmbulanceTripModel?> watchTripForEmergency(String emergencyRequestId) {
    return _firestore
        .collection('ambulance_trips')
        .where('emergencyRequestId', isEqualTo: emergencyRequestId)
        .orderBy('dispatchedAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) =>
            snap.docs.isEmpty ? null : AmbulanceTripModel.fromFirestore(snap.docs.first));
  }

  Future<void> updateAmbulanceLocation(String ambulanceId, GeoPointValue location) async {
    try {
      await _firestore.collection('ambulances').doc(ambulanceId).update({
        'currentLocation': GeoPoint(location.latitude, location.longitude),
        'currentLocationUpdatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') throw const PermissionException();
      throw ServerException(e.message ?? 'Failed to update location');
    }
  }

  Future<Map<String, dynamic>> _call(String name, Map<String, dynamic> params) async {
    try {
      final result = await _functions.httpsCallable(name).call<Map<String, dynamic>>(params);
      return result.data;
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'permission-denied' || e.code == 'unauthenticated') {
        throw const PermissionException();
      }
      throw ServerException(e.message ?? 'Action failed');
    }
  }

  Future<String> registerAmbulance({
    required String vehicleNumber,
    required String driverName,
    required String driverPhone,
    String? driverEmail,
    String? hospitalId,
  }) async {
    try {
      final result = await _call('registerAmbulance', {
        'vehicleNumber': vehicleNumber,
        'driverName': driverName,
        'driverPhone': driverPhone,
        if (driverEmail != null) 'driverEmail': driverEmail,
      });
      if (result['ambulanceId'] != null) return result['ambulanceId'] as String;
    } catch (_) {}

    // Direct Firestore fallback
    final docRef = _firestore.collection('ambulances').doc();
    await docRef.set({
      'vehicleNumber': vehicleNumber,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'driverEmail': driverEmail,
      'hospitalId': hospitalId ?? '',
      'status': 'available',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  Future<void> setAvailability(String ambulanceId, String status) async {
    try {
      await _call('setAmbulanceAvailability', {'ambulanceId': ambulanceId, 'status': status});
      return;
    } catch (_) {}

    await _firestore.collection('ambulances').doc(ambulanceId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> dispatchAmbulance(String requestId, String ambulanceId) =>
      _call('dispatchAmbulance', {'requestId': requestId, 'ambulanceId': ambulanceId});

  Future<void> completeTrip(String tripId) => _call('completeTrip', {'tripId': tripId});
}
