import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:medilink/features/home/models/doctor.dart';
import 'package:medilink/features/home/models/slot.dart';

/// Repository for slot-related operations
class SlotRepository {
  final _database = FirebaseDatabase.instance.ref();
  
  static const String _slotsPath = 'slots';
  static const String _doctorsPath = 'doctors';
  
  /// Helper to generate slots for a single date based on doctor's schedule
  List<Slot> generateSlotsForDate(Doctor doctor, String dateStr) {
    try {
      final parsedDate = DateTime.parse(dateStr);
      // Sundays (weekday == 7) are strictly closed
      if (parsedDate.weekday == 7) return [];
    } catch (_) {}

    final slots = <Slot>[];
    final startParts = doctor.startTime.split(':');
    final endParts = doctor.endTime.split(':');
    
    int startHour = int.tryParse(startParts[0]) ?? 9;
    int startMin = int.tryParse(startParts.length > 1 ? startParts[1] : '0') ?? 0;
    int endHour = int.tryParse(endParts[0]) ?? 17;
    int endMin = int.tryParse(endParts.length > 1 ? endParts[1] : '0') ?? 0;
    
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
    return slots;
  }

  /// Ensures slots exist for the given date. If the doctor was created long ago,
  /// this automatically generates permanent slots on demand using the doctor's schedule!
  Future<void> ensureSlotsExistForDate(String hospitalId, String doctorId, String date) async {
    try {
      final parsedDate = DateTime.parse(date);
      if (parsedDate.weekday == 7) return; // Closed on Sundays

      final snap = await _database
          .child(_slotsPath)
          .child(hospitalId)
          .child(doctorId)
          .child(date)
          .get();

      if (snap.exists && snap.value is Map && (snap.value as Map).isNotEmpty) {
        return; // Slots already exist
      }

      // Fetch doctor working hours from RTDB
      final docSnap = await _database
          .child(_doctorsPath)
          .child(hospitalId)
          .child(doctorId)
          .get();

      if (!docSnap.exists || docSnap.value == null) return;
      final docData = Map<String, dynamic>.from(docSnap.value as Map);
      final doctor = Doctor.fromJson(docData, docId: doctorId);

      final generatedSlots = generateSlotsForDate(doctor, date);
      if (generatedSlots.isNotEmpty) {
        final Map<String, dynamic> dateSlots = {};
        for (final slot in generatedSlots) {
          final slotKey = _database.child(_slotsPath).push().key ??
              DateTime.now().microsecondsSinceEpoch.toString();
          dateSlots[slotKey] = slot.toJson();
        }
        await _database
            .child(_slotsPath)
            .child(hospitalId)
            .child(doctorId)
            .child(date)
            .set(dateSlots);
      }
    } catch (e) {
      print('DEBUG: ensureSlotsExistForDate note: $e');
    }
  }

  /// Real-time stream of slots for a doctor on a specific date (live "Doctor Busy" updates!)
  Stream<List<Slot>> watchSlotsByDoctorAndDate(
    String hospitalId,
    String doctorId,
    String date,
  ) {
    try {
      final parsedDate = DateTime.parse(date);
      if (parsedDate.weekday == 7) {
        return Stream.value(<Slot>[]);
      }
    } catch (_) {}

    // Auto-generate slots on demand if this date has none yet
    ensureSlotsExistForDate(hospitalId, doctorId, date);

    return _database
        .child(_slotsPath)
        .child(hospitalId)
        .child(doctorId)
        .child(date)
        .onValue
        .map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return <Slot>[];
      }
      final slots = <Slot>[];
      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};

      data.forEach((key, value) {
        if (value is Map<dynamic, dynamic>) {
          try {
            slots.add(
              Slot.fromJson(
                Map<String, dynamic>.from(value),
                docId: key.toString(),
              ),
            );
          } catch (_) {}
        }
      });

      // Sort chronological by slot start time
      slots.sort((a, b) => a.time.compareTo(b.time));
      return slots;
    }).handleError((err) {
      print('DEBUG: RTDB watchSlots note: $err');
      return <Slot>[];
    });
  }

  /// Create multiple slots at once
  Future<void> createSlots(List<Slot> slots) async {
    try {
      for (final slot in slots) {
        final ref = _database
            .child(_slotsPath)
            .child(slot.hospitalId)
            .child(slot.doctorId)
            .child(slot.date)
            .push();
        
        await ref.set(slot.toJson());
      }
    } catch (e) {
      throw Exception('Failed to create slots: $e');
    }
  }
  
  /// Get slots for a doctor on a specific date
  Future<List<Slot>> getSlotsByDoctorAndDate(
    String hospitalId,
    String doctorId,
    String date,
  ) async {
    try {
      final parsedDate = DateTime.parse(date);
      if (parsedDate.weekday == 7) return []; // Sunday closed
    } catch (_) {}

    await ensureSlotsExistForDate(hospitalId, doctorId, date);

    try {
      final snapshot = await _database
          .child(_slotsPath)
          .child(hospitalId)
          .child(doctorId)
          .child(date)
          .get();
      
      if (!snapshot.exists) {
        return [];
      }
      
      final slots = <Slot>[];
      final data = snapshot.value as Map<dynamic, dynamic>? ?? {};
      
      data.forEach((key, value) {
        if (value is Map<dynamic, dynamic>) {
          slots.add(
            Slot.fromJson(
              Map<String, dynamic>.from(value),
              docId: key.toString(),
            ),
          );
        }
      });
      
      slots.sort((a, b) => a.time.compareTo(b.time));
      return slots;
    } catch (e) {
      throw Exception('Failed to fetch slots: $e');
    }
  }
  
  /// Update a slot
  Future<void> updateSlot(String slotId, Slot slot) async {
    try {
      await _database
          .child(_slotsPath)
          .child(slot.hospitalId)
          .child(slot.doctorId)
          .child(slot.date)
          .child(slotId)
          .update(slot.toJson());
    } catch (e) {
      throw Exception('Failed to update slot: $e');
    }
  }
  
  /// Book a slot (patient books)
  Future<void> bookSlot(
    String slotId,
    String hospitalId,
    String doctorId,
    String date,
    String userId,
  ) async {
    try {
      await _database
          .child(_slotsPath)
          .child(hospitalId)
          .child(doctorId)
          .child(date)
          .child(slotId)
          .update({'bookedBy': userId});
    } catch (e) {
      throw Exception('Failed to book slot: $e');
    }
  }

  /// Delete a single slot (by hospital admin)
  Future<void> deleteSlot({
    required String hospitalId,
    required String doctorId,
    required String date,
    required String slotId,
  }) async {
    try {
      await _database
          .child(_slotsPath)
          .child(hospitalId)
          .child(doctorId)
          .child(date)
          .child(slotId)
          .remove();
    } catch (e) {
      throw Exception('Failed to delete slot: $e');
    }
  }

  /// Delete all slots for a specific date (e.g. Doctor is taking the day off)
  Future<void> deleteSlotsForDate({
    required String hospitalId,
    required String doctorId,
    required String date,
  }) async {
    try {
      await _database
          .child(_slotsPath)
          .child(hospitalId)
          .child(doctorId)
          .child(date)
          .remove();
    } catch (e) {
      throw Exception('Failed to delete date slots: $e');
    }
  }

  /// Toggle slot busy / available by hospital admin
  Future<void> toggleSlotBusy({
    required String hospitalId,
    required String doctorId,
    required String date,
    required String slotId,
    required bool markBusy,
  }) async {
    try {
      await _database
          .child(_slotsPath)
          .child(hospitalId)
          .child(doctorId)
          .child(date)
          .child(slotId)
          .update({
        'bookedBy': markBusy ? 'BLOCKED_BY_ADMIN' : null,
      });
    } catch (e) {
      throw Exception('Failed to update slot status: $e');
    }
  }

  /// Regenerate / reset all slots for a date according to doctor's working hours
  Future<void> regenerateDateSlots(Doctor doctor, String dateStr) async {
    try {
      final parsedDate = DateTime.parse(dateStr);
      if (parsedDate.weekday == 7) return; // No slots on Sunday

      final newSlots = generateSlotsForDate(doctor, dateStr);
      final Map<String, dynamic> dateSlots = {};
      for (final slot in newSlots) {
        final slotKey = _database.child(_slotsPath).push().key ??
            DateTime.now().microsecondsSinceEpoch.toString();
        dateSlots[slotKey] = slot.toJson();
      }

      await _database
          .child(_slotsPath)
          .child(doctor.hospitalId)
          .child(doctor.id!)
          .child(dateStr)
          .set(dateSlots);
    } catch (e) {
      throw Exception('Failed to regenerate date slots: $e');
    }
  }

  /// Delete all slots for a doctor
  Future<void> deleteSlotsByDoctor(String hospitalId, String doctorId) async {
    try {
      await _database
          .child(_slotsPath)
          .child(hospitalId)
          .child(doctorId)
          .remove();
    } catch (e) {
      throw Exception('Failed to delete doctor slots: $e');
    }
  }

  /// Delete all slots for a hospital
  Future<void> deleteSlotsByHospital(String hospitalId) async {
    try {
      await _database
          .child(_slotsPath)
          .child(hospitalId)
          .remove();
    } catch (e) {
      throw Exception('Failed to delete hospital slots: $e');
    }
  }
}
