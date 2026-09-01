import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:medilink/core/error/exceptions.dart';
import 'package:medilink/features/emergency/data/models/emergency_request_model.dart';
import 'package:medilink/features/emergency/domain/entities/emergency_request.dart';

class CommandCenterRemoteDataSource {
  CommandCenterRemoteDataSource({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final _database = FirebaseDatabase.instance.ref();

  Stream<List<EmergencyRequestModel>> watchHospitalEmergencies(String hospitalId) async* {
    final controller = StreamController<List<EmergencyRequestModel>>.broadcast();
    final Map<String, EmergencyRequestModel> emergencyMap = {};

    void emitList() {
      final list = emergencyMap.values.toList()
        ..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
      if (!controller.isClosed) {
        controller.add(list);
      }
    }

    // 1. Listen to Realtime Database for this specific hospital
    _database.child('emergencies').child(hospitalId).onValue.listen((event) {
      if (event.snapshot.exists && event.snapshot.value is Map) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, val) {
          if (val is Map) {
            try {
              final model = EmergencyRequestModel.fromJson(Map<String, dynamic>.from(val));
              emergencyMap[model.id] = model;
            } catch (_) {}
          }
        });
        emitList();
      }
    }, onError: (err) {
      print('DEBUG: RTDB hospital emergency stream note: $err');
    });

    // 2. Listen to Realtime Database 'all' emergencies as a global sync
    _database.child('emergencies').child('all').onValue.listen((event) {
      if (event.snapshot.exists && event.snapshot.value is Map) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, val) {
          if (val is Map) {
            try {
              final model = EmergencyRequestModel.fromJson(Map<String, dynamic>.from(val));
              if (model.selectedHospitalId == hospitalId || hospitalId == 'all' || hospitalId.isEmpty) {
                emergencyMap[model.id] = model;
              }
            } catch (_) {}
          }
        });
        emitList();
      }
    }, onError: (err) {
      print('DEBUG: RTDB all emergency stream note: $err');
    });

    // 3. Listen to Firestore collection
    try {
      _firestore.collection('emergency_requests').snapshots().listen((snap) {
        for (final doc in snap.docs) {
          try {
            final model = EmergencyRequestModel.fromFirestore(doc);
            if (model.selectedHospitalId == hospitalId || hospitalId == 'all' || hospitalId.isEmpty) {
              emergencyMap[model.id] = model;
            }
          } catch (_) {}
        }
        emitList();
      });
    } catch (_) {}

    yield* controller.stream;
  }

  Future<void> _call(String name, Map<String, dynamic> params) async {
    try {
      await _functions.httpsCallable(name).call<Map<String, dynamic>>(params);
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'permission-denied' || e.code == 'unauthenticated') {
        throw const PermissionException();
      }
      throw ServerException(e.message ?? 'Action failed');
    } catch (e) {
      print('DEBUG: Cloud function $name failed ($e), falling back to direct DB updates');
    }
  }

  Future<void> _updateEmergencyState({
    required String requestId,
    required String status,
    Map<String, dynamic>? extraData,
    String? timelineLabel,
  }) async {
    final updatePayload = {
      'status': status,
      'updatedAt': DateTime.now().toIso8601String(),
      if (extraData != null) ...extraData,
    };

    // Update in RTDB
    try {
      await _database.child('emergencies').child('all').child(requestId).update(updatePayload);
      if (timelineLabel != null) {
        final evtKey = 'evt_${DateTime.now().millisecondsSinceEpoch}';
        await _database.child('emergency_timelines').child(requestId).child(evtKey).set({
          'id': evtKey,
          'status': status,
          'label': timelineLabel,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    } catch (_) {}

    // Update in Firestore
    try {
      await _firestore.collection('emergency_requests').doc(requestId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
        if (extraData != null) ...extraData,
      });
      if (timelineLabel != null) {
        await _firestore.collection('emergency_requests').doc(requestId).collection('timeline').add({
          'status': status,
          'label': timelineLabel,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {}
  }

  Future<void> acceptEmergency(String requestId) async {
    await _call('acceptEmergency', {'requestId': requestId});
    await _updateEmergencyState(
      requestId: requestId,
      status: 'hospitalAccepted',
      extraData: {'acceptedAt': DateTime.now().toIso8601String()},
      timelineLabel: 'Hospital Accepted: Emergency medical team mobilized and standing by.',
    );
  }

  Future<void> rejectEmergency(String requestId, String reason) async {
    await _call('rejectEmergency', {'requestId': requestId, 'reason': reason});
    await _updateEmergencyState(
      requestId: requestId,
      status: 'rejected',
      extraData: {'rejectReason': reason},
      timelineLabel: 'Emergency Request Declined: $reason',
    );
  }

  Future<void> assignDoctor(String requestId, String doctorId) async {
    await _call('assignDoctor', {'requestId': requestId, 'doctorId': doctorId});
    await _updateEmergencyState(
      requestId: requestId,
      status: 'hospitalAccepted',
      extraData: {'assignedDoctorId': doctorId},
      timelineLabel: 'Doctor Assigned: Dedicated medical specialist prepared for arrival.',
    );
  }

  Future<void> sendInstruction(String requestId, String text) async {
    await _call('sendInstruction', {'requestId': requestId, 'text': text});
    try {
      final key = 'inst_${DateTime.now().millisecondsSinceEpoch}';
      await _database.child('emergencies').child('all').child(requestId).child('staffInstructions').child(key).set(text);
      await _firestore.collection('emergency_requests').doc(requestId).update({
        'staffInstructions': FieldValue.arrayUnion([
          {'text': text, 'timestamp': Timestamp.now()}
        ]),
      });
    } catch (_) {}
  }

  Future<void> markArrived(String requestId) async {
    await _call('markArrived', {'requestId': requestId});
    await _updateEmergencyState(
      requestId: requestId,
      status: 'arrived',
      extraData: {'arrivedAt': DateTime.now().toIso8601String()},
      timelineLabel: 'Patient Arrived: Admitted to emergency trauma unit.',
    );
  }

  Future<void> closeEmergency(String requestId, String outcome) async {
    await _call('closeEmergency', {'requestId': requestId, 'outcome': outcome});
    await _updateEmergencyState(
      requestId: requestId,
      status: 'completed',
      extraData: {'completedAt': DateTime.now().toIso8601String(), 'outcome': outcome},
      timelineLabel: 'Emergency Case Closed: $outcome',
    );
  }
}
