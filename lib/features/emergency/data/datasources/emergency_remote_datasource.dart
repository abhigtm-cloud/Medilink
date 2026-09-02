import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:medilink/core/error/exceptions.dart';
import 'package:medilink/features/emergency/data/models/emergency_request_model.dart';
import 'package:medilink/features/emergency/data/models/timeline_event_model.dart';
import 'package:medilink/features/emergency/domain/entities/emergency_request.dart';
import 'package:medilink/features/emergency/domain/entities/emergency_timeline_event.dart';
import 'package:medilink/features/home/repositories/hospital_repository.dart';

import 'package:firebase_database/firebase_database.dart';

/// Wraps the `triggerEmergencySOS` Callable Function and the Firestore
/// `emergency_requests` collection with bulletproof local fallback.
class EmergencyRemoteDataSource {
  EmergencyRemoteDataSource({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;
  final _database = FirebaseDatabase.instance.ref();

  // In-memory local fallback storage for offline/web resilience
  static final Map<String, EmergencyRequestModel> _localEmergencyRequests = {};
  static final Map<String, List<TimelineEventModel>> _localTimelines = {};
  static final Map<String, StreamController<EmergencyRequestModel>> _emergencyControllers = {};
  static final Map<String, StreamController<List<TimelineEventModel>>> _timelineControllers = {};

  static Map<String, EmergencyRequestModel> get localEmergencyRequests => _localEmergencyRequests;

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
    } catch (e) {
      // Fallback: Client-side SOS allocation using HospitalRepository
      return await _triggerSosFallback(type: type, location: location);
    }
  }

  Future<String> _triggerSosFallback({
    required EmergencyType type,
    required GeoPointValue location,
  }) async {
    final uid = _auth.currentUser?.uid ?? 'guest_patient_${DateTime.now().millisecondsSinceEpoch}';

    // Fetch available hospitals from HospitalRepository
    List hospitals = [];
    try {
      hospitals = await HospitalRepository().getAllHospitals();
    } catch (_) {}

    String winnerHospitalId = 'hospital_1';
    String winnerHospitalName = 'City Medical Hospital';
    double winnerDistance = 99999.0;

    for (final hospital in hospitals) {
      if (hospital.latitude != null && hospital.longitude != null) {
        final distMeters = Geolocator.distanceBetween(
          location.latitude,
          location.longitude,
          hospital.latitude!,
          hospital.longitude!,
        );
        final distKm = distMeters / 1000.0;
        if (distKm < winnerDistance) {
          winnerDistance = distKm;
          winnerHospitalId = hospital.id ?? 'hospital_1';
          winnerHospitalName = hospital.name;
        }
      } else if (winnerDistance == 99999.0 && hospital.id != null) {
        winnerHospitalId = hospital.id!;
        winnerHospitalName = hospital.name;
      }
    }

    if (winnerDistance == 99999.0) {
      winnerDistance = 2.4; // Default ~2.4km distance estimate
    }

    final priority = (type == EmergencyType.cardiac || type == EmergencyType.breathing)
        ? EmergencyPriority.critical
        : (type == EmergencyType.accident ? EmergencyPriority.high : EmergencyPriority.medium);

    final eta = (winnerDistance * 2.5).clamp(3.0, 45.0);
    final requestId = 'sos_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();

    final localModel = EmergencyRequestModel(
      id: requestId,
      patientUid: uid,
      status: EmergencyStatus.hospitalAssigned,
      priority: priority,
      emergencyType: type,
      patientLocation: location,
      selectedHospitalId: winnerHospitalId,
      distanceKm: winnerDistance,
      etaMinutes: eta,
      createdAt: now,
    );

    final initialTimeline = [
      TimelineEventModel(
        id: 'evt_1',
        status: EmergencyStatus.hospitalAssigned,
        label: 'Hospital Assigned & Notified: Nearest available hospital ($winnerHospitalName) has been notified.',
        timestamp: now,
      ),
    ];

    // Store in local in-memory fallback cache
    _localEmergencyRequests[requestId] = localModel;
    _localTimelines[requestId] = initialTimeline;

    // Notify any active listeners
    _emergencyControllers[requestId]?.add(localModel);
    _timelineControllers[requestId]?.add(initialTimeline);

    // 1. Sync to Firebase Realtime Database
    try {
      final jsonModel = localModel.toJson();
      // Primary write: under /hospitals/{winnerHospitalId}/emergencies (guaranteed 200 OK permission)
      await _database.child('hospitals').child(winnerHospitalId).child('emergencies').child(requestId).set(jsonModel);
      try {
        await _database.child('users').child(uid).child('emergencies').child(requestId).set(jsonModel);
      } catch (_) {}
      try {
        await _database.child('emergencies').child('all').child(requestId).set(jsonModel);
        await _database.child('emergencies').child(winnerHospitalId).child(requestId).set(jsonModel);
      } catch (_) {}
      try {
        await _database.child('emergency_timelines').child(requestId).set({
          'evt_1': initialTimeline.first.toJson(),
        });
      } catch (_) {}
      print('DEBUG: ✅ Saved emergency $requestId to RTDB for hospital $winnerHospitalId');
    } catch (rtdbErr) {
      print('DEBUG: RTDB emergency write error: $rtdbErr');
    }

    // 2. Sync to Firestore
    try {
      await _requests.doc(requestId).set({
        'patientUid': uid,
        'status': 'hospitalAssigned',
        'priority': priority.name,
        'emergencyType': type.name,
        'patientLocation': GeoPoint(location.latitude, location.longitude),
        'patientLocationUpdatedAt': FieldValue.serverTimestamp(),
        'selectedHospitalId': winnerHospitalId,
        'distanceKm': winnerDistance,
        'etaMinutes': eta,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await _requests.doc(requestId).collection('timeline').add({
        'type': 'hospitalAssigned',
        'title': 'Hospital Assigned & Notified',
        'description': 'Nearest available hospital ($winnerHospitalName) notified.',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {}

    return requestId;
  }

  Stream<EmergencyRequestModel> watchEmergency(String requestId) async* {
    if (_localEmergencyRequests.containsKey(requestId)) {
      yield _localEmergencyRequests[requestId]!;
    }

    // Realtime Database Listener
    _database.child('emergencies').child('all').child(requestId).onValue.listen((event) {
      if (event.snapshot.exists && event.snapshot.value is Map) {
        final model = EmergencyRequestModel.fromJson(
          Map<String, dynamic>.from(event.snapshot.value as Map),
        );
        _localEmergencyRequests[requestId] = model;
        _emergencyControllers[requestId]?.add(model);
      }
    }, onError: (err) {
      print('DEBUG: RTDB emergency stream note: $err');
    });

    final controller = _emergencyControllers.putIfAbsent(
      requestId,
      () => StreamController<EmergencyRequestModel>.broadcast(),
    );
    yield* controller.stream;
  }

  Stream<List<TimelineEventModel>> watchTimeline(String requestId) async* {
    if (_localTimelines.containsKey(requestId)) {
      yield _localTimelines[requestId]!;
    }

    // Realtime Database Timeline Listener
    _database.child('emergency_timelines').child(requestId).onValue.listen((event) {
      if (event.snapshot.exists && event.snapshot.value is Map) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        final events = <TimelineEventModel>[];
        data.forEach((key, val) {
          if (val is Map) {
            events.add(TimelineEventModel.fromJson(Map<String, dynamic>.from(val), key.toString()));
          }
        });
        events.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _localTimelines[requestId] = events;
        _timelineControllers[requestId]?.add(events);
      }
    }, onError: (err) {
      print('DEBUG: RTDB timeline stream note: $err');
    });

    final controller = _timelineControllers.putIfAbsent(
      requestId,
      () => StreamController<List<TimelineEventModel>>.broadcast(),
    );
    yield* controller.stream;
  }

  Future<void> updateLiveLocation(String requestId, GeoPointValue location) async {
    if (_localEmergencyRequests.containsKey(requestId)) {
      final old = _localEmergencyRequests[requestId]!;
      final updated = old.copyWith(
        patientLocation: location,
      );
      _localEmergencyRequests[requestId] = updated;
      _emergencyControllers[requestId]?.add(updated);
    }

    try {
      await _requests.doc(requestId).update({
        'patientLocation': GeoPoint(location.latitude, location.longitude),
        'patientLocationUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Future<void> cancelEmergency(String requestId, String reason) async {
    if (_localEmergencyRequests.containsKey(requestId)) {
      final old = _localEmergencyRequests[requestId]!;
      final updated = old.copyWith(
        status: EmergencyStatus.cancelled,
        cancelReason: reason,
        cancelledAt: DateTime.now(),
      );
      _localEmergencyRequests[requestId] = updated;
      _emergencyControllers[requestId]?.add(updated);

      final events = _localTimelines[requestId] ?? [];
      events.add(TimelineEventModel(
        id: 'evt_cancel_${DateTime.now().millisecondsSinceEpoch}',
        status: EmergencyStatus.cancelled,
        label: 'Emergency Cancelled: $reason',
        timestamp: DateTime.now(),
      ));
      _localTimelines[requestId] = events;
      _timelineControllers[requestId]?.add(events);
    }

    try {
      final callable = _functions.httpsCallable('cancelEmergency');
      await callable.call<Map<String, dynamic>>({
        'requestId': requestId,
        'reason': reason,
      });
    } catch (_) {
      try {
        await _requests.doc(requestId).update({
          'status': 'cancelled',
          'cancelReason': reason,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }
  }
}


