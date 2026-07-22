import 'package:cloud_functions/cloud_functions.dart';

/// Thin wrapper around the `assignStaffRole` Callable Function — the only
/// client-reachable path to grant a hospital staff role (see
/// functions/src/rbac/assignStaffRole.ts). Kept as a plain service rather
/// than a full Clean Architecture repository since it's a single action
/// with no local caching or offline behavior to justify the extra layers.
class StaffRoleService {
  StaffRoleService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  static const assignableRoles = [
    'doctor',
    'ambulance_driver',
    'pharmacy',
    'emergency_staff',
  ];

  /// Throws [FirebaseFunctionsException] on failure — caller formats the
  /// message (e.g. `e.message`) for display.
  Future<void> assignStaffRole({required String email, required String role}) async {
    await _functions.httpsCallable('assignStaffRole').call<Map<String, dynamic>>({
      'email': email,
      'role': role,
    });
  }
}
