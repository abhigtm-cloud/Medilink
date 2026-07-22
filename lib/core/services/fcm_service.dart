import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:medilink/core/services/rbac_service.dart';

/// Registers/refreshes the current user's FCM token into RTDB
/// `users/{uid}/fcmTokens/{token}` (reusing the existing `users` path rather
/// than a new Firestore collection — see architecture doc §16), and manages
/// hospital-staff topic subscriptions (`hospital_{hospitalId}_emergency`).
///
/// Push delivery itself is best-effort (OS can throttle/kill it); the
/// Firestore `notifications/{uid}/items` collection written by
/// `sendFcm.ts`'s `notifyUser`/`notifyHospitalStaff` is the reliable
/// fallback — this service only owns token/topic bookkeeping, not delivery.
class FcmService {
  FcmService({
    FirebaseMessaging? messaging,
    FirebaseAuth? auth,
    DatabaseReference? usersRef,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _usersRef = usersRef ?? FirebaseDatabase.instance.ref('users');

  final FirebaseMessaging _messaging;
  final FirebaseAuth _auth;
  final DatabaseReference _usersRef;

  StreamSubscription<String>? _tokenRefreshSub;
  String? _subscribedHospitalTopic;

  /// Registers/refreshes the token for the current user and, for hospital
  /// staff, subscribes to their hospital's emergency topic. Safe to call
  /// repeatedly (e.g. every time claims resolve) — subscribing to the same
  /// topic twice is a no-op.
  Future<void> syncForRole(AppRole role, String? hospitalId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    final token = await _messaging.getToken();
    if (token != null) await _saveToken(user.uid, token);

    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = _messaging.onTokenRefresh.listen((newToken) {
      final current = _auth.currentUser;
      if (current != null) _saveToken(current.uid, newToken);
    });

    if (role.isHospitalStaff && hospitalId != null) {
      await _subscribeToHospitalTopic(hospitalId);
    }
  }

  Future<void> _saveToken(String uid, String token) async {
    await _usersRef.child(uid).child('fcmTokens').child(token).set(true);
  }

  Future<void> _subscribeToHospitalTopic(String hospitalId) async {
    final topic = 'hospital_${hospitalId}_emergency';
    if (_subscribedHospitalTopic == topic) return;
    if (_subscribedHospitalTopic != null) {
      await _messaging.unsubscribeFromTopic(_subscribedHospitalTopic!);
    }
    await _messaging.subscribeToTopic(topic);
    _subscribedHospitalTopic = topic;
  }

  /// Removes this device's token and topic subscription. Call before
  /// signing out — needs the still-authenticated uid to find the RTDB path.
  Future<void> clearToken() async {
    final user = _auth.currentUser;
    final token = await _messaging.getToken();
    if (user != null && token != null) {
      await _usersRef.child(user.uid).child('fcmTokens').child(token).remove();
    }
    if (_subscribedHospitalTopic != null) {
      await _messaging.unsubscribeFromTopic(_subscribedHospitalTopic!);
      _subscribedHospitalTopic = null;
    }
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
  }
}
