import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'package:medilink/features/home/models/hospital.dart';

/// Repository for hospital-related operations
class HospitalRepository {
  final _database = FirebaseDatabase.instance.ref();
  
  static const String _hospitalsPath = 'hospitals';
  static const int _maxRetries = 3;
  static const Duration _queryTimeout = Duration(seconds: 30);

  /// Retry helper for Firebase operations
  Future<T> _withRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        attempts++;
        print('DEBUG: Firebase query attempt $attempts/$maxRetries');
        
        final result = await operation().timeout(
          timeout,
          onTimeout: () {
            throw TimeoutException('Firebase operation timed out after ${timeout.inSeconds}s');
          },
        );
        
        print('DEBUG: Firebase query successful on attempt $attempts');
        return result;
      } catch (e) {
        print('DEBUG: Firebase query failed on attempt $attempts: $e');
        
        if (attempts >= maxRetries) {
          throw Exception('Failed after $maxRetries attempts: $e');
        }
        
        // Wait before retrying (exponential backoff)
        await Future.delayed(Duration(seconds: attempts));
      }
    }
    
    throw Exception('Max retries exceeded');
  }
  
  /// Create a new hospital
  Future<Hospital> createHospital(Hospital hospital, String userId) async {
    try {
      final hospitalWithAdmin = hospital.copyWith(adminId: userId);
      final ref = _database.child(_hospitalsPath).push();
      
      await ref.set(hospitalWithAdmin.toJson());
      
      return hospitalWithAdmin.copyWith(id: ref.key);
    } catch (e) {
      throw Exception('Failed to create hospital: $e');
    }
  }
  
  /// Get all hospitals
  Future<List<Hospital>> getAllHospitals() async {
    return _withRetry(() async {
      final snapshot = await _database.child(_hospitalsPath).get();
      
      if (!snapshot.exists) {
        return [];
      }
      
      final hospitals = <Hospital>[];
      final data = snapshot.value as Map<dynamic, dynamic>? ?? {};
      
      data.forEach((key, value) {
        if (value is Map<dynamic, dynamic>) {
          hospitals.add(
            Hospital.fromJson(
              Map<String, dynamic>.from(value),
              docId: key,
            ),
          );
        }
      });
      
      return hospitals;
    }, maxRetries: _maxRetries, timeout: _queryTimeout);
  }
  
  /// Get hospitals by admin ID
  Future<List<Hospital>> getHospitalsByAdmin(String adminId) async {
    return _withRetry(() async {
      // Fetch all hospitals and filter in code (avoid Firebase index requirement)
      final snapshot = await _database.child(_hospitalsPath).get();
      
      if (!snapshot.exists) {
        return [];
      }
      
      final hospitals = <Hospital>[];
      final data = snapshot.value as Map<dynamic, dynamic>? ?? {};
      
      data.forEach((key, value) {
        if (value is Map<dynamic, dynamic>) {
          final hospital = Hospital.fromJson(
            Map<String, dynamic>.from(value),
            docId: key,
          );
          // Filter by admin ID in code
          if (hospital.adminId == adminId) {
            hospitals.add(hospital);
          }
        }
      });
      
      return hospitals;
    }, maxRetries: _maxRetries, timeout: _queryTimeout);
  }
  
  /// Get a specific hospital by ID
  Future<Hospital?> getHospitalById(String hospitalId) async {
    try {
      final snapshot = await _database.child(_hospitalsPath).child(hospitalId).get();
      
      if (!snapshot.exists) {
        return null;
      }
      
      final data = snapshot.value as Map<dynamic, dynamic>;
      return Hospital.fromJson(
        Map<String, dynamic>.from(data),
        docId: hospitalId,
      );
    } catch (e) {
      throw Exception('Failed to fetch hospital: $e');
    }
  }
  
  /// Update a hospital
  Future<void> updateHospital(Hospital hospital) async {
    try {
      if (hospital.id == null) {
        throw Exception('Hospital ID is required for update');
      }
      
      await _database
          .child(_hospitalsPath)
          .child(hospital.id!)
          .update(hospital.toJson());
    } catch (e) {
      throw Exception('Failed to update hospital: $e');
    }
  }
  
  /// Check if admin already has a hospital created
  Future<bool> adminHasHospital(String adminId) async {
    try {
      final hospitals = await getHospitalsByAdmin(adminId);
      return hospitals.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check hospital count: $e');
    }
  }

  /// Delete a hospital
  Future<void> deleteHospital(String hospitalId) async {
    try {
      await _database.child(_hospitalsPath).child(hospitalId).remove();
    } catch (e) {
      throw Exception('Failed to delete hospital: $e');
    }
  }
}
