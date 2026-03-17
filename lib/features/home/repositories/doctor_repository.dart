import 'package:firebase_database/firebase_database.dart';
import 'package:medilink/features/home/models/doctor.dart';

/// Repository for doctor-related operations
class DoctorRepository {
  final _database = FirebaseDatabase.instance.ref();
  
  static const String _doctorsPath = 'doctors';
  
  /// Create a new doctor
  Future<Doctor> createDoctor(Doctor doctor) async {
    try {
      final ref = _database
          .child(_doctorsPath)
          .child(doctor.hospitalId)
          .push();
      
      await ref.set(doctor.toJson());
      
      return doctor.copyWith(id: ref.key);
    } catch (e) {
      throw Exception('Failed to create doctor: $e');
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
