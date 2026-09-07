import 'dart:async';
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
    String? name,
    String? hospitalId,
  }) async {
    final cleanEmailKey = email.replaceAll('.', '_').replaceAll('@', '_at_');
    final staffName = (name != null && name.trim().isNotEmpty) ? name.trim() : email.split('@').first;
    final staffData = {
      'email': email,
      'name': staffName,
      'role': role,
      'hospitalId': hospitalId ?? '',
      'assignedAt': DateTime.now().toIso8601String(),
    };

    // 1. Try Cloud Function
    try {
      await _functions.httpsCallable('assignStaffRole').call<Map<String, dynamic>>({
        'email': email,
        'role': role,
      });
    } catch (_) {}

    // 2. Direct RTDB (under /hospitals/{hospitalId}/staff)
    if (hospitalId != null && hospitalId.isNotEmpty) {
      try {
        await _database.child('hospitals').child(hospitalId).child('staff').child(cleanEmailKey).set(staffData);
      } catch (_) {}
    }

    try {
      await _database.child('staff').child(hospitalId ?? 'general').child(cleanEmailKey).set(staffData);
    } catch (_) {}

    // 3. Cross-sync: If role is Doctor, register in Doctor Repository so they appear in doctor roster & booking
    if (role == 'doctor') {
      try {
        final docId = 'doc_$cleanEmailKey';
        final doctorData = {
          'id': docId,
          'name': staffName.startsWith('Dr.') ? staffName : 'Dr. $staffName',
          'specialization': 'General Physician / Specialist',
          'qualification': 'MBBS, MD',
          'experience': 5,
          'fees': 500,
          'availableDays': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
          'email': email,
          'isAbsent': false,
          'hospitalId': hospitalId ?? '',
          'slotDurationMinutes': 30,
        };
        if (hospitalId != null && hospitalId.isNotEmpty) {
          await _database.child('doctors').child(hospitalId).child(docId).set(doctorData);
        }
        await _database.child('doctors').child('general').child(docId).set(doctorData);
      } catch (_) {}
    }

    // 4. Cross-sync: If role is Ambulance Driver, register in Ambulance Fleet
    if (role == 'ambulance_driver') {
      try {
        final ambId = 'amb_$cleanEmailKey';
        final ambData = {
          'id': ambId,
          'vehicleNumber': 'AMB-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
          'driverName': staffName,
          'driverPhone': 'Emergency Driver',
          'driverEmail': email,
          'hospitalId': hospitalId ?? '',
          'status': 'available',
          'createdAt': DateTime.now().toIso8601String(),
        };
        if (hospitalId != null && hospitalId.isNotEmpty) {
          await _database.child('hospitals').child(hospitalId).child('ambulances').child(ambId).set(ambData);
        }
        await _database.child('ambulances').child(ambId).set(ambData);
      } catch (_) {}
    }

    try {
      await _firestore.collection('staff').doc(cleanEmailKey).set(staffData, SetOptions(merge: true));
    } catch (_) {}
  }

  /// Watch or fetch staff list for a hospital
  Stream<List<StaffMember>> watchHospitalStaff(String hospitalId) {
    late StreamController<List<StaffMember>> controller;
    final Map<String, StaffMember> staffMap = {};

    void emitList() {
      if (controller.isClosed) return;
      controller.add(staffMap.values.toList());
    }

    controller = StreamController<List<StaffMember>>(
      onListen: () {
        emitList();

        // 1. Listen under /hospitals/{hospitalId}/staff
        if (hospitalId.isNotEmpty && hospitalId != 'general') {
          _database.child('hospitals').child(hospitalId).child('staff').onValue.listen((event) {
            if (event.snapshot.exists && event.snapshot.value is Map) {
              final data = event.snapshot.value as Map<dynamic, dynamic>;
              data.forEach((key, value) {
                if (value is Map) {
                  try {
                    staffMap[key.toString()] = StaffMember.fromJson(Map<String, dynamic>.from(value), key.toString());
                  } catch (_) {}
                }
              });
            }
            emitList();
          }, onError: (_) => emitList());
        }

        // 2. Listen under /staff/{hospitalId}
        _database.child('staff').child(hospitalId).onValue.listen((event) {
          if (event.snapshot.exists && event.snapshot.value is Map) {
            final data = event.snapshot.value as Map<dynamic, dynamic>;
            data.forEach((key, value) {
              if (value is Map) {
                try {
                  staffMap[key.toString()] = StaffMember.fromJson(Map<String, dynamic>.from(value), key.toString());
                } catch (_) {}
              }
            });
          }
          emitList();
        }, onError: (_) => emitList());
      },
    );

    return controller.stream;
  }

  /// Remove a staff member
  Future<void> removeStaffMember(String hospitalId, String staffKey) async {
    try {
      await _database.child('hospitals').child(hospitalId).child('staff').child(staffKey).remove();
    } catch (_) {}
    try {
      await _database.child('staff').child(hospitalId).child(staffKey).remove();
    } catch (_) {}
    try {
      await _firestore.collection('staff').doc(staffKey).delete();
    } catch (_) {}
  }
}
