import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:medilink/core/error/exceptions.dart';
import 'package:medilink/features/emergency/data/models/emergency_request_model.dart';

class CommandCenterRemoteDataSource {
  CommandCenterRemoteDataSource({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  Stream<List<EmergencyRequestModel>> watchHospitalEmergencies(String hospitalId) {
    return _firestore
        .collection('emergency_requests')
        .where('selectedHospitalId', isEqualTo: hospitalId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(EmergencyRequestModel.fromFirestore).toList());
  }

  Future<void> _call(String name, Map<String, dynamic> params) async {
    try {
      await _functions.httpsCallable(name).call<Map<String, dynamic>>(params);
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'permission-denied' || e.code == 'unauthenticated') {
        throw const PermissionException();
      }
      throw ServerException(e.message ?? 'Action failed');
    }
  }

  Future<void> acceptEmergency(String requestId) =>
      _call('acceptEmergency', {'requestId': requestId});

  Future<void> rejectEmergency(String requestId, String reason) =>
      _call('rejectEmergency', {'requestId': requestId, 'reason': reason});

  Future<void> assignDoctor(String requestId, String doctorId) =>
      _call('assignDoctor', {'requestId': requestId, 'doctorId': doctorId});

  Future<void> sendInstruction(String requestId, String text) =>
      _call('sendInstruction', {'requestId': requestId, 'text': text});

  Future<void> markArrived(String requestId) =>
      _call('markArrived', {'requestId': requestId});

  Future<void> closeEmergency(String requestId, String outcome) =>
      _call('closeEmergency', {'requestId': requestId, 'outcome': outcome});
}
