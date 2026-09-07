import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:medilink/core/services/cache_service.dart';
import 'package:medilink/features/home/models/doctor.dart';
import 'package:medilink/features/home/models/slot.dart';

/// Repository for doctor-related operations
class DoctorRepository {
  final _database = FirebaseDatabase.instance.ref();
  
  static const String _doctorsPath = 'doctors';
  
  /// Create a new doctor and auto-generate time slots
  Future<Doctor> createDoctor(Doctor doctor) async {
    try {
      final ref = _database
          .child(_doctorsPath)
          .child(doctor.hospitalId)
          .push();
      
      final createdDoctor = doctor.copyWith(id: ref.key);

      // 1. Update offline cache immediately so UI reflects the new doctor instantly
      try {
        final cached = CacheService.getDoctorsByHospital(doctor.hospitalId) ?? [];
        final updatedList = List<Map<String, dynamic>>.from(cached);
        updatedList.add(createdDoctor.toJson());
        await CacheService.setDoctorsByHospital(doctor.hospitalId, updatedList);
      } catch (_) {}

      // 2. Write doctor metadata to Firebase with timeout protection
      await ref.set(doctor.toJson()).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('DEBUG: Firebase doctor write timeout - continuing in background');
        },
      );
      
      // 3. Auto-generate booking slots in background (non-blocking)
      unawaited(_generateSlotsForDoctor(createdDoctor));
      
      return createdDoctor;
    } catch (e) {
      throw Exception('Failed to create doctor: $e');
    }
  }

  /// Generate time slots for a doctor for the next 30 days (atomic multi-set)
  Future<void> _generateSlotsForDoctor(Doctor doctor) async {
    try {
      final now = DateTime.now();
      final slots = <Slot>[];
      
      // Generate slots for next 30 days (excluding Sundays)
      for (int i = 0; i < 30; i++) {
        final date = now.add(Duration(days: i));
        
        // Skip Sundays (day 7)
        if (date.weekday == 7) continue;
        
        // Skip past dates
        if (date.isBefore(now) && date.day != now.day) continue;
        
        final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        
        // Parse doctor's working hours
        final startParts = doctor.startTime.split(':');
        final endParts = doctor.endTime.split(':');
        
        int startHour = int.tryParse(startParts[0]) ?? 9;
        int startMin = int.tryParse(startParts[1]) ?? 0;
        int endHour = int.tryParse(endParts[0]) ?? 17;
        int endMin = int.tryParse(endParts[1]) ?? 0;
        
        // Create slots based on duration
        int currentHour = startHour;
        int currentMin = startMin;
        final slotDuration = doctor.slotDurationMinutes > 0 ? doctor.slotDurationMinutes : 30;
        
        while (currentHour < endHour || (currentHour == endHour && currentMin < endMin)) {
          final hourStr = currentHour.toString().padLeft(2, '0');
          final minStr = currentMin.toString().padLeft(2, '0');
          
          int nextMin = currentMin + slotDuration;
          int nextHour = currentHour;
          while (nextMin >= 60) {
            nextMin -= 60;
            nextHour += 1;
          }
          
          final nextHourStr = nextHour.toString().padLeft(2, '0');
          final nextMinStr = nextMin.toString().padLeft(2, '0');
          
          final timeSlot = '$hourStr:$minStr - $nextHourStr:$nextMinStr';
          
          slots.add(Slot(
            doctorId: doctor.id ?? '',
            hospitalId: doctor.hospitalId,
            date: dateStr,
            time: timeSlot,
            createdAt: DateTime.now(),
          ));
          
          currentMin += slotDuration;
          while (currentMin >= 60) {
            currentMin -= 60;
            currentHour += 1;
          }
        }
      }
      
      // Save all slots to Firebase in ONE atomic batch write
      if (slots.isNotEmpty && doctor.id != null) {
        final Map<String, dynamic> dateGroups = {};
        for (final slot in slots) {
          if (!dateGroups.containsKey(slot.date)) {
            dateGroups[slot.date] = <String, dynamic>{};
          }
          final slotKey = _database.child('slots').push().key ?? DateTime.now().microsecondsSinceEpoch.toString();
          dateGroups[slot.date][slotKey] = slot.toJson();
        }

        await _database
            .child('slots')
            .child(doctor.hospitalId)
            .child(doctor.id!)
            .set(dateGroups);
      }
    } catch (e) {
      debugPrint('ERROR: Slot generation failed for doctor ${doctor.id}: $e');
    }
  }
  
  /// Get doctors for a specific hospital (Cache-First + Multi-source DB lookup)
  Future<List<Doctor>> getDoctorsByHospital(String hospitalId) async {
    final doctorMap = <String, Doctor>{};

    // Try cache first - supports offline mode
    final cachedDoctors = CacheService.getDoctorsByHospital(hospitalId);
    if (cachedDoctors != null && cachedDoctors.isNotEmpty) {
      for (final item in cachedDoctors) {
        try {
          final doc = Doctor.fromJson(
            Map<String, dynamic>.from(item as Map),
            docId: (item)['id']?.toString(),
          );
          if (doc.id != null) doctorMap[doc.id!] = doc;
        } catch (_) {}
      }
    }

    // Query Realtime Database paths
    try {
      // 1. Primary: /doctors/{hospitalId}
      final snap1 = await _database.child(_doctorsPath).child(hospitalId).get();
      if (snap1.exists && snap1.value is Map) {
        final data = snap1.value as Map<dynamic, dynamic>;
        data.forEach((k, v) {
          if (v is Map) {
            try {
              final doc = Doctor.fromJson(Map<String, dynamic>.from(v), docId: k.toString());
              if (doc.id != null) doctorMap[doc.id!] = doc;
            } catch (_) {}
          }
        });
      }

      // 2. Secondary: /hospitals/{hospitalId}/doctors
      final snap2 = await _database.child('hospitals').child(hospitalId).child('doctors').get();
      if (snap2.exists && snap2.value is Map) {
        final data = snap2.value as Map<dynamic, dynamic>;
        data.forEach((k, v) {
          if (v is Map) {
            try {
              final doc = Doctor.fromJson(Map<String, dynamic>.from(v), docId: k.toString());
              if (doc.id != null) doctorMap[doc.id!] = doc;
            } catch (_) {}
          }
        });
      }

      // 3. Staff roster: /hospitals/{hospitalId}/staff (where role == doctor)
      final snap3 = await _database.child('hospitals').child(hospitalId).child('staff').get();
      if (snap3.exists && snap3.value is Map) {
        final data = snap3.value as Map<dynamic, dynamic>;
        data.forEach((k, v) {
          if (v is Map && v['role']?.toString().toLowerCase() == 'doctor') {
            try {
              final doc = Doctor.fromJson(Map<String, dynamic>.from(v), docId: k.toString());
              if (doc.id != null && !doctorMap.containsKey(doc.id)) {
                doctorMap[doc.id!] = doc;
              }
            } catch (_) {}
          }
        });
      }

      // 4. If still empty, check all /doctors
      if (doctorMap.isEmpty) {
        final snapAll = await _database.child(_doctorsPath).get();
        if (snapAll.exists && snapAll.value is Map) {
          final data = snapAll.value as Map<dynamic, dynamic>;
          data.forEach((k, v) {
            if (v is Map) {
              if (v.containsKey('name') && v.containsKey('specialization')) {
                final doc = Doctor.fromJson(Map<String, dynamic>.from(v), docId: k.toString());
                if (doc.id != null) doctorMap[doc.id!] = doc;
              } else {
                v.forEach((docKey, docVal) {
                  if (docVal is Map) {
                    try {
                      final doc = Doctor.fromJson(Map<String, dynamic>.from(docVal), docId: docKey.toString());
                      if (doc.id != null) doctorMap[doc.id!] = doc;
                    } catch (_) {}
                  }
                });
              }
            }
          });
        }
      }

      final list = doctorMap.values.toList();
      if (list.isNotEmpty) {
        await CacheService.setDoctorsByHospital(hospitalId, list.map((d) => d.toJson()).toList());
      }
      return list;
    } catch (e) {
      print('DEBUG: Note fetching doctors from Firebase: $e');
      return doctorMap.values.toList();
    }
  }
  
  /// Get a specific doctor by ID
  Future<Doctor?> getDoctorById(String hospitalId, String doctorId) async {
    try {
      final snapshot = await _database
          .child(_doctorsPath)
          .child(hospitalId)
          .child(doctorId)
          .get();
      
      if (!snapshot.exists) {
        return null;
      }
      
      final data = snapshot.value as Map<dynamic, dynamic>;
      return Doctor.fromJson(
        Map<String, dynamic>.from(data),
        docId: doctorId,
      );
    } catch (e) {
      throw Exception('Failed to fetch doctor: $e');
    }
  }
  
  /// Update a doctor
  Future<void> updateDoctor(Doctor doctor) async {
    try {
      if (doctor.id == null) {
        throw Exception('Doctor ID is required for update');
      }
      
      await _database
          .child(_doctorsPath)
          .child(doctor.hospitalId)
          .child(doctor.id!)
          .update(doctor.toJson());
    } catch (e) {
      throw Exception('Failed to update doctor: $e');
    }
  }
  
  /// Update doctor's attendance / absence status in real time
  Future<void> updateDoctorAbsentStatus({
    required String hospitalId,
    required String doctorId,
    required bool isAbsent,
    String? reason,
  }) async {
    try {
      await _database
          .child(_doctorsPath)
          .child(hospitalId)
          .child(doctorId)
          .update({
        'isAbsent': isAbsent,
        'absentReason': reason ?? (isAbsent ? 'On Leave / Absent' : null),
      });

      // Also update in offline cache
      try {
        final cached = CacheService.getDoctorsByHospital(hospitalId);
        if (cached != null) {
          final updated = cached.map((d) {
            if (d['id'] == doctorId) {
              final copy = Map<String, dynamic>.from(d);
              copy['isAbsent'] = isAbsent;
              copy['absentReason'] = reason;
              return copy;
            }
            return d;
          }).toList();
          await CacheService.setDoctorsByHospital(hospitalId, updated);
        }
      } catch (_) {}
    } catch (e) {
      throw Exception('Failed to update doctor attendance: $e');
    }
  }

  /// Watch a specific doctor live
  Stream<Doctor?> watchDoctor(String hospitalId, String doctorId) {
    return _database
        .child(_doctorsPath)
        .child(hospitalId)
        .child(doctorId)
        .onValue
        .map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) return null;
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      return Doctor.fromJson(data, docId: doctorId);
    });
  }

  /// Watch all doctors for a hospital live
  Stream<List<Doctor>> watchDoctorsByHospital(String hospitalId) {
    late StreamController<List<Doctor>> controller;
    final Map<String, Doctor> doctorMap = {};

    void emitDoctors() {
      if (!controller.isClosed) {
        controller.add(doctorMap.values.toList());
      }
    }

    controller = StreamController<List<Doctor>>.broadcast(
      onListen: () {
        // 1. Initial multi-source fetch
        getDoctorsByHospital(hospitalId).then((docs) {
          for (final d in docs) {
            if (d.id != null) doctorMap[d.id!] = d;
          }
          emitDoctors();
        }).catchError((_) {});

        // 2. Realtime listener on /doctors/{hospitalId}
        _database.child(_doctorsPath).child(hospitalId).onValue.listen((event) {
          if (event.snapshot.exists && event.snapshot.value is Map) {
            final data = event.snapshot.value as Map<dynamic, dynamic>;
            data.forEach((k, v) {
              if (v is Map) {
                try {
                  final doc = Doctor.fromJson(Map<String, dynamic>.from(v), docId: k.toString());
                  if (doc.id != null) doctorMap[doc.id!] = doc;
                } catch (_) {}
              }
            });
            emitDoctors();
          }
        }, onError: (_) {});

        // 3. Realtime listener on /hospitals/{hospitalId}/staff
        _database.child('hospitals').child(hospitalId).child('staff').onValue.listen((event) {
          if (event.snapshot.exists && event.snapshot.value is Map) {
            final data = event.snapshot.value as Map<dynamic, dynamic>;
            data.forEach((k, v) {
              if (v is Map && v['role']?.toString().toLowerCase() == 'doctor') {
                try {
                  final doc = Doctor.fromJson(Map<String, dynamic>.from(v), docId: k.toString());
                  if (doc.id != null && !doctorMap.containsKey(doc.id)) {
                    doctorMap[doc.id!] = doc;
                  }
                } catch (_) {}
              }
            });
            emitDoctors();
          }
        }, onError: (_) {});
      },
    );

    return controller.stream;
  }

  /// Delete a doctor
  Future<void> deleteDoctor(String hospitalId, String doctorId) async {
    try {
      await _database
          .child(_doctorsPath)
          .child(hospitalId)
          .child(doctorId)
          .remove();
    } catch (e) {
      throw Exception('Failed to delete doctor: $e');
    }
  }
}
