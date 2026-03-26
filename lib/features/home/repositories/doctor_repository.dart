import 'package:firebase_database/firebase_database.dart';
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
      
      await ref.set(doctor.toJson());
      
      final createdDoctor = doctor.copyWith(id: ref.key);
      
      // Auto-generate slots for the next 30 days
      await _generateSlotsForDoctor(createdDoctor);
      
      return createdDoctor;
    } catch (e) {
      throw Exception('Failed to create doctor: $e');
    }
  }

  /// Generate time slots for a doctor for the next 30 days
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
        
        int startHour = int.parse(startParts[0]);
        int startMin = int.parse(startParts[1]);
        int endHour = int.parse(endParts[0]);
        int endMin = int.parse(endParts[1]);
        
        // Create 30-minute slots
        int currentHour = startHour;
        int currentMin = startMin;
        
        while (currentHour < endHour || (currentHour == endHour && currentMin < endMin)) {
          final hourStr = currentHour.toString().padLeft(2, '0');
          final minStr = currentMin.toString().padLeft(2, '0');
          
          int nextMin = currentMin + 30;
          int nextHour = currentHour;
          if (nextMin >= 60) {
            nextMin = 0;
            nextHour = currentHour + 1;
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
          
          currentMin += 30;
          if (currentMin >= 60) {
            currentMin = 0;
            currentHour += 1;
          }
        }
      }
      
      // Save all slots to Firebase
      if (slots.isNotEmpty && doctor.id != null) {
        for (final slot in slots) {
          final ref = _database
              .child('slots')
              .child(doctor.hospitalId)
              .child(doctor.id!)
              .child(slot.date)
              .push();
          
          await ref.set(slot.toJson());
        }
        print('DEBUG: Generated ${slots.length} slots for doctor ${doctor.name}');
      }
    } catch (e) {
      print('DEBUG: Error generating slots: $e');
      // Don't throw error here - doctor creation should succeed even if slot generation fails
    }
  }
  
  /// Get doctors for a specific hospital
  Future<List<Doctor>> getDoctorsByHospital(String hospitalId) async {
    try {
      final snapshot = await _database
          .child(_doctorsPath)
          .child(hospitalId)
          .get();
      
      if (!snapshot.exists) {
        return [];
      }
      
      final doctors = <Doctor>[];
      final data = snapshot.value as Map<dynamic, dynamic>? ?? {};
      
      data.forEach((key, value) {
        if (value is Map<dynamic, dynamic>) {
          doctors.add(
            Doctor.fromJson(
              Map<String, dynamic>.from(value),
              docId: key,
            ),
          );
        }
      });
      
      return doctors;
    } catch (e) {
      throw Exception('Failed to fetch doctors: $e');
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
