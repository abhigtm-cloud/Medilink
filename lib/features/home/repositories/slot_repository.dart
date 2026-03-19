import 'package:firebase_database/firebase_database.dart';
import 'package:medilink/features/home/models/slot.dart';

/// Repository for slot-related operations
class SlotRepository {
  final _database = FirebaseDatabase.instance.ref();
  
  static const String _slotsPath = 'slots';
  
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
              docId: key,
            ),
          );
        }
      });
      
      return slots;
    } catch (e) {
      throw Exception('Failed to fetch slots: $e');
    }
  }
  
  /// Update a slot (mark as booked)
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
  
  /// Book a slot
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
