import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_database/firebase_database.dart';

class StaffMember {
  final String id;
  final String email;
  final String role;
  final String? name;
  final DateTime? assignedAt;

  StaffMember({
    required this.id,
    required this.email,
    required this.role,
    this.name,
    this.assignedAt,
  });

  factory StaffMember.fromJson(Map<String, dynamic> json, String id) {
    return StaffMember(
      id: id,
      email: json['email'] ?? '',
      role: json['role'] ?? 'doctor',
      name: json['name'] ?? json['displayName'],
      assignedAt: json['assignedAt'] != null
          ? DateTime.tryParse(json['assignedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'email': email,
    'role': role,
    'name': name,
    'assignedAt': (assignedAt ?? DateTime.now()).toIso8601String(),
  };
}

/// Service to grant hospital staff roles and query registered staff.
class StaffRoleService {
  StaffRoleService({FirebaseFunctions? functions, FirebaseFirestore? firestore})
      : _functions = functions ?? FirebaseFunctions.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;
  final _database = FirebaseDatabase.instance.ref();

  static const assignableRoles = [
    'doctor',
    'ambulance_driver',
    'pharmacy',
    'emergency_staff',
  ];

  /// Assign a staff role to a user
  Future<void> assignStaffRole({
    required String email,
    required String role,
    String? hospitalId,
  }) async {
    // 1. Try Cloud Function
    try {
      await _functions.httpsCallable('assignStaffRole').call<Map<String, dynamic>>({
        'email': email,
        'role': role,
      });
    } catch (_) {}

    // 2. Direct RTDB and Firestore fallback
    final cleanEmailKey = email.replaceAll('.', '_').replaceAll('@', '_at_');
    final staffData = {
      'email': email,
      'role': role,
      'hospitalId': hospitalId ?? '',
      'assignedAt': DateTime.now().toIso8601String(),
    };

    try {
      await _database.child('staff').child(hospitalId ?? 'general').child(cleanEmailKey).set(staffData);
    } catch (_) {}

    try {
      await _firestore.collection('staff').doc(cleanEmailKey).set(staffData, SetOptions(merge: true));
    } catch (_) {}
  }

  /// Watch or fetch staff list for a hospital
  Stream<List<StaffMember>> watchHospitalStaff(String hospitalId) {
    return _database.child('staff').child(hospitalId).onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return <StaffMember>[];
      }
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      final list = <StaffMember>[];
      data.forEach((key, value) {
        if (value is Map) {
          list.add(StaffMember.fromJson(Map<String, dynamic>.from(value), key.toString()));
        }
      });
      return list;
    });
  }

  /// Remove a staff member
  Future<void> removeStaffMember(String hospitalId, String staffKey) async {
    try {
      await _database.child('staff').child(hospitalId).child(staffKey).remove();
    } catch (_) {}
    try {
      await _firestore.collection('staff').doc(staffKey).delete();
    } catch (_) {}
  }
}
