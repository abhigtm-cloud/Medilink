import 'package:firebase_auth/firebase_auth.dart';

/// Server-verified role, sourced from Firebase custom claims (set by the
/// `onUserRoleWrite` Cloud Function from `user_roles/{uid}` — never trust a
/// role the client claims). See docs/EMERGENCY_PLATFORM_ARCHITECTURE.md §3.
enum AppRole {
  patient,
  hospitalAdmin,
  doctor,
  ambulanceDriver,
  pharmacy,
  emergencyStaff,
  unknown;

  static AppRole fromClaim(String? value) {
    switch (value) {
      case 'patient':
        return AppRole.patient;
      case 'hospital_admin':
        return AppRole.hospitalAdmin;
      case 'doctor':
        return AppRole.doctor;
      case 'ambulance_driver':
        return AppRole.ambulanceDriver;
      case 'pharmacy':
        return AppRole.pharmacy;
      case 'emergency_staff':
        return AppRole.emergencyStaff;
      default:
        return AppRole.unknown;
    }
  }

  bool get isHospitalStaff => this != AppRole.patient && this != AppRole.unknown;
}

/// Reads the current user's server-verified role and hospital assignment
/// from their Firebase ID token custom claims (`role`, `hospitalId`).
///
/// Claims only reflect reality after a token refresh — call
/// [refreshClaims] right after any action that could have changed the
/// signed-in user's `user_roles` doc (e.g. an admin just added them as
/// staff) before relying on [currentRole] / [currentHospitalId].
class RbacService {
  RbacService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  AppRole _role = AppRole.unknown;
  String? _hospitalId;

  AppRole get currentRole => _role;
  String? get currentHospitalId => _hospitalId;

  /// Reads claims from the current ID token without forcing a refresh.
  Future<AppRole> loadClaims() => _readClaims(forceRefresh: false);

  /// Forces the ID token to refresh from the server, picking up any custom
  /// claims a Cloud Function just set, then re-reads them.
  Future<AppRole> refreshClaims() => _readClaims(forceRefresh: true);

  Future<AppRole> _readClaims({required bool forceRefresh}) async {
    final user = _auth.currentUser;
    if (user == null) {
      _role = AppRole.unknown;
      _hospitalId = null;
      return _role;
    }

    final tokenResult = await user.getIdTokenResult(forceRefresh);
    final claims = tokenResult.claims ?? const <String, dynamic>{};
    _role = AppRole.fromClaim(claims['role'] as String?);
    _hospitalId = claims['hospitalId'] as String?;
    return _role;
  }

  void reset() {
    _role = AppRole.unknown;
    _hospitalId = null;
  }
}
