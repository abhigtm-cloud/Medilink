import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_database/firebase_database.dart';
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
  final _database = FirebaseDatabase.instance.ref();

  Stream<List<AmbulanceModel>> watchHospitalFleet(String hospitalId) {
    late StreamController<List<AmbulanceModel>> controller;
    final Map<String, AmbulanceModel> fleetMap = {};

    void emitList() {
      if (controller.isClosed) return;
      controller.add(fleetMap.values.toList());
    }

    controller = StreamController<List<AmbulanceModel>>(
      onListen: () {
        emitList();

        // 1. Listen to RTDB under /hospitals/{hospitalId}/ambulances
        if (hospitalId.isNotEmpty && hospitalId != 'all') {
          _database.child('hospitals').child(hospitalId).child('ambulances').onValue.listen((event) {
            if (event.snapshot.exists && event.snapshot.value is Map) {
              final data = event.snapshot.value as Map<dynamic, dynamic>;
              data.forEach((key, val) {
                if (val is Map) {
                  try {
                    fleetMap[key.toString()] = AmbulanceModel.fromJson(val, key.toString());
                  } catch (_) {}
                }
              });
            }
            emitList();
          }, onError: (_) => emitList());
        }

        // 2. Listen to RTDB under /ambulances
        _database.child('ambulances').onValue.listen((event) {
          if (event.snapshot.exists && event.snapshot.value is Map) {
            final data = event.snapshot.value as Map<dynamic, dynamic>;
            data.forEach((key, val) {
              if (val is Map) {
                try {
                  final amb = AmbulanceModel.fromJson(val, key.toString());
                  if (amb.hospitalId == hospitalId || hospitalId == 'all' || hospitalId.isEmpty || amb.hospitalId.isEmpty) {
                    fleetMap[key.toString()] = amb;
                  }
                } catch (_) {}
              }
            });
          }
          emitList();
        }, onError: (_) => emitList());

        // 3. Listen to Firestore
        try {
          _firestore
              .collection('ambulances')
              .where('hospitalId', isEqualTo: hospitalId)
              .snapshots()
              .listen((snap) {
            for (final doc in snap.docs) {
              fleetMap[doc.id] = AmbulanceModel.fromFirestore(doc);
            }
            emitList();
          }, onError: (_) => emitList());
        } catch (_) {}
      },
    );

    return controller.stream;
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
    final ambId = 'amb_${DateTime.now().millisecondsSinceEpoch}';
    final ambData = {
      'id': ambId,
      'vehicleNumber': vehicleNumber,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'driverEmail': driverEmail,
      'hospitalId': hospitalId ?? '',
      'status': 'available',
      'createdAt': DateTime.now().toIso8601String(),
    };

    // 1. Primary write to RTDB (always authorized and instant)
    try {
      if (hospitalId != null && hospitalId.isNotEmpty) {
        await _database.child('hospitals').child(hospitalId).child('ambulances').child(ambId).set(ambData);
      }
      await _database.child('ambulances').child(ambId).set(ambData);
    } catch (_) {}

    // 2. Call Cloud function or Firestore
    try {
      final result = await _call('registerAmbulance', {
        'vehicleNumber': vehicleNumber,
        'driverName': driverName,
        'driverPhone': driverPhone,
        if (driverEmail != null) 'driverEmail': driverEmail,
      });
      if (result['ambulanceId'] != null) return result['ambulanceId'] as String;
    } catch (_) {}

    try {
      await _firestore.collection('ambulances').doc(ambId).set({
        ...ambData,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}

    return ambId;
  }

  Future<void> setAvailability(String ambulanceId, String status) async {
    try {
      await _database.child('ambulances').child(ambulanceId).update({'status': status});
      final snap = await _database.child('ambulances').child(ambulanceId).child('hospitalId').get();
      if (snap.exists && snap.value != null) {
        final hId = snap.value.toString();
        await _database.child('hospitals').child(hId).child('ambulances').child(ambulanceId).update({'status': status});
      }
    } catch (_) {}

    try {
      await _call('setAmbulanceAvailability', {'ambulanceId': ambulanceId, 'status': status});
      return;
    } catch (_) {}

    try {
      await _firestore.collection('ambulances').doc(ambulanceId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Future<void> dispatchAmbulance(String requestId, String ambulanceId) =>
      _call('dispatchAmbulance', {'requestId': requestId, 'ambulanceId': ambulanceId});

  Future<void> completeTrip(String tripId) => _call('completeTrip', {'tripId': tripId});
}
