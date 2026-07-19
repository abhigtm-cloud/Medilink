/// Single source of truth for every Cloud Firestore collection/document path
/// used by the emergency platform. Firestore is additive to the existing
/// Realtime Database (see docs/EMERGENCY_PLATFORM_ARCHITECTURE.md §0) — none
/// of the paths here overlap with RTDB paths used by `auth`/`home` features.
class FirestorePaths {
  FirestorePaths._();

  /// `user_roles/{uid}` — server-verified RBAC source of truth.
  static const String userRoles = 'user_roles';

  /// `hospital_directory/{hospitalId}` — geo-queryable mirror of RTDB
  /// hospital identity, written only by `mirrorHospitalToFirestore`.
  static const String hospitalDirectory = 'hospital_directory';

  /// `hospital_status/{hospitalId}` — live operational state (beds, ICU,
  /// ambulances, queue) used by scoring and the Command Center.
  static const String hospitalStatus = 'hospital_status';

  static String userRoleDoc(String uid) => '$userRoles/$uid';

  static String hospitalDirectoryDoc(String hospitalId) =>
      '$hospitalDirectory/$hospitalId';

  static String hospitalStatusDoc(String hospitalId) =>
      '$hospitalStatus/$hospitalId';
}
