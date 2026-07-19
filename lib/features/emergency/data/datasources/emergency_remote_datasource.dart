import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:medilink/core/error/exceptions.dart';
import 'package:medilink/features/emergency/data/models/emergency_request_model.dart';
import 'package:medilink/features/emergency/data/models/timeline_event_model.dart';
import 'package:medilink/features/emergency/domain/entities/emergency_request.dart';

/// Wraps the `triggerEmergencySOS` Callable Function and the Firestore
/// `emergency_requests` collection. Never lets a raw [FirebaseException] or
/// [FirebaseFunctionsException] escape past this layer — the repository maps
/// everything to a [Failure].
class EmergencyRemoteDataSource {
  EmergencyRemoteDataSource({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  CollectionReference<Map<String, dynamic>> get _requests =>
      _firestore.collection('emergency_requests');

  Future<String> triggerSos({
    required EmergencyType type,
    required GeoPointValue location,
  }) async {
    try {
      final callable = _functions.httpsCallable('triggerEmergencySOS');
      final result = await callable.call<Map<String, dynamic>>({
        'lat': location.latitude,
        'lng': location.longitude,
        'emergencyType': type.name,
      });
      final data = result.data;
      if (data['status'] == 'noHospitalFound') {
        throw NoHospitalFoundException();
      }
      return data['requestId'] as String;
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'unauthenticated' || e.code == 'permission-denied') {
        throw const PermissionException();
      }
      throw ServerException(e.message ?? 'Failed to trigger emergency SOS');
    }
  }

  Stream<EmergencyRequestModel> watchEmergency(String requestId) {
    return _requests.doc(requestId).snapshots().map(
          (doc) => EmergencyRequestModel.fromFirestore(doc),
        );
  }

  Stream<List<TimelineEventModel>> watchTimeline(String requestId) {
    return _requests
        .doc(requestId)
        .collection('timeline')
        .orderBy('timestamp')
        .snapshots()
        .map((snap) => snap.docs.map(TimelineEventModel.fromFirestore).toList());
  }

  Future<void> updateLiveLocation(String requestId, GeoPointValue location) async {
    try {
      await _requests.doc(requestId).update({
        'patientLocation': GeoPoint(location.latitude, location.longitude),
        'patientLocationUpdatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Failed to update location');
    }
  }

  /// Status transitions (including cancellation) are Cloud-Function-only —
  /// Firestore rules only let the patient touch `patientLocation` directly
  /// (see firestore.rules) — so this goes through `cancelEmergency` rather
  /// than a raw Firestore update, which also lets the function append the
  /// matching timeline audit entry.
  Future<void> cancelEmergency(String requestId, String reason) async {
    try {
      final callable = _functions.httpsCallable('cancelEmergency');
      await callable.call<Map<String, dynamic>>({
        'requestId': requestId,
        'reason': reason,
      });
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'permission-denied' || e.code == 'unauthenticated') {
        throw const PermissionException();
      }
      throw ServerException(e.message ?? 'Failed to cancel emergency');
    }
  }
}
