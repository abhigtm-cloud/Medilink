import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'package:medilink/core/services/cache_service.dart';
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
        
        final result = await operation().timeout(
          timeout,
          onTimeout: () {
            throw TimeoutException('Firebase operation timed out after ${timeout.inSeconds}s');
          },
        );
        
        return result;
      } catch (e) {
        
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
      
      // Invalidate cache so fresh data is fetched next time
      await CacheService.clearHospitals();
      
      return hospitalWithAdmin.copyWith(id: ref.key);
    } catch (e) {
      throw Exception('Failed to create hospital: $e');
    }
  }
  
  /// Get all hospitals (Cache-First Strategy for offline support)
  Future<List<Hospital>> getAllHospitals() async {
    // Try cache first - CRITICAL for offline mode
    final cachedData = CacheService.getHospitals();
    if (cachedData != null && cachedData.isNotEmpty) {
      print('DEBUG: 📦 Using offline cache for hospitals (${cachedData.length} items)');
      try {
        return (cachedData)
            .map((item) => Hospital.fromJson(
                  Map<String, dynamic>.from(item as Map),
                  docId: (item)['id'],
                ))
            .toList();
      } catch (e) {
        print('DEBUG: Error parsing cached hospitals: $e');
        // Fall through to Firebase
      }
    }

    // Cache miss or invalid, fetch from Firebase
    print('DEBUG: 🔄 Fetching fresh hospitals from Firebase...');
    try {
      return _withRetry(() async {
        try {
          print('DEBUG: Reading from Firebase path: hospitals');
          final snapshot = await _database.child(_hospitalsPath).get();
          
          print('DEBUG: ✅ Firebase response received');
          
          if (!snapshot.exists) {
            print('DEBUG: ⚠️ No hospitals in Firebase');
            // Return cached data as fallback if available
            final fallbackCache = CacheService.getHospitals();
            if (fallbackCache != null) {
              return (fallbackCache)
                  .map((item) => Hospital.fromJson(
                        Map<String, dynamic>.from(item as Map),
                        docId: (item)['id'],
                      ))
                  .toList();
            }
            return [];
          }
          
          final hospitals = <Hospital>[];
          final data = snapshot.value as Map<dynamic, dynamic>? ?? {};
          final cacheData = <Map<String, dynamic>>[];
          
          print('DEBUG: Processing ${data.length} hospital records');
          
          data.forEach((key, value) {
            if (value is Map<dynamic, dynamic>) {
              try {
                final hospital = Hospital.fromJson(
                  Map<String, dynamic>.from(value),
                  docId: key,
                );
                hospitals.add(hospital);
                cacheData.add(hospital.toJson());
                print('DEBUG: ✓ Parsed hospital: ${hospital.name}');
              } catch (e) {
                print('DEBUG: ✗ Error parsing hospital $key: $e');
              }
            }
          });
          
          print('DEBUG: Successfully parsed ${hospitals.length} hospitals');
          
          // Store in cache for offline access
          if (hospitals.isNotEmpty) {
            await CacheService.setHospitals(cacheData);
            print('DEBUG: ✅ Cached ${hospitals.length} hospitals');
          }

          return hospitals;
        } catch (e, st) {
          print('DEBUG: 🔥 Firebase read error: $e');
          print('DEBUG: Stack trace: $st');
          rethrow;
        }
      }, maxRetries: _maxRetries, timeout: _queryTimeout);
    } catch (e) {
      print('DEBUG: Firebase failed, attempting offline cache fallback...');
      // If Firebase completely fails, return cached data
      final fallbackCache = CacheService.getHospitals();
      if (fallbackCache != null && fallbackCache.isNotEmpty) {
        print('DEBUG: ⚠️ Using offline cache as emergency fallback');
        return (fallbackCache)
            .map((item) => Hospital.fromJson(
                  Map<String, dynamic>.from(item as Map),
                  docId: (item)['id'],
                ))
            .toList();
      }
      throw Exception('No hospitals available (Firebase offline and cache empty): $e');
    }
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
      
      // Invalidate cache
      await CacheService.clearHospitals();
    } catch (e) {
      throw Exception('Failed to delete hospital: $e');
    }
  }
}
