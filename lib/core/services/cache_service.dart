import 'package:hive_flutter/hive_flutter.dart';

/// CacheService implements indefinite offline-first caching.
/// Data persists on device until user logs out or cache is explicitly cleared.
/// This ensures the app works even when system is turned off or on different networks.
class CacheService {
  static const String _hospitalsBoxName = 'hospitals_cache';
  static const String _doctorsBoxName = 'doctors_cache';
  static const String _usersBoxName = 'users_cache';
  static const String _bookingsBoxName = 'bookings_cache';

  static late Box _hospitalsBox;
  static late Box _doctorsBox;
  static late Box _usersBox;
  static late Box _bookingsBox;

  /// Initialize Hive and open boxes for offline persistence
  static Future<void> initialize() async {
    try {
      await Hive.initFlutter();
      
      _hospitalsBox = await Hive.openBox(_hospitalsBoxName);
      _doctorsBox = await Hive.openBox(_doctorsBoxName);
      _usersBox = await Hive.openBox(_usersBoxName);
      _bookingsBox = await Hive.openBox(_bookingsBoxName);
      
      print('DEBUG: 📱 CacheService initialized for offline persistence');
    } catch (e) {
      print('DEBUG: Error initializing CacheService: $e');
      rethrow;
    }
  }

  /// Check if cache has data (no expiration - indefinite persistence)
  static bool _hasCacheData(String key) {
    try {
      final cached = _hospitalsBox.get(key);
      return cached != null;
    } catch (e) {
      print('DEBUG: Error checking cache data: $e');
      return false;
    }
  }

  // ========== Hospital Caching (Indefinite) ==========

  /// Get hospitals from cache (indefinite persistence - no expiry)
  static List<dynamic>? getHospitals() {
    try {
      final cached = _hospitalsBox.get('hospitals');
      if (cached != null) {
        print('DEBUG: 📦 Using offline cache for hospitals');
        return cached as List<dynamic>;
      }
      return null;
    } catch (e) {
      print('DEBUG: Error getting cached hospitals: $e');
      return null;
    }
  }

  /// Save hospitals to cache indefinitely
  static Future<void> setHospitals(List<dynamic> hospitals) async {
    try {
      await _hospitalsBox.put('hospitals', hospitals);
      print('DEBUG: ✅ Hospitals saved to offline cache');
    } catch (e) {
      print('DEBUG: Error caching hospitals: $e');
    }
  }

  /// Clear hospitals cache
  static Future<void> clearHospitals() async {
    try {
      await _hospitalsBox.delete('hospitals');
      print('DEBUG: CacheService - Hospital cache cleared');
    } catch (e) {
      print('DEBUG: Error clearing hospital cache: $e');
    }
  }

  // ========== Doctor Caching (Indefinite) ==========

  /// Get doctors by hospital from cache (indefinite persistence)
  static List<dynamic>? getDoctorsByHospital(String hospitalId) {
    try {
      final cached = _doctorsBox.get('doctors_$hospitalId');
      if (cached != null) {
        print('DEBUG: 📦 Using offline cache for doctors in $hospitalId');
        return cached as List<dynamic>;
      }
      return null;
    } catch (e) {
      print('DEBUG: Error getting cached doctors: $e');
      return null;
    }
  }

  /// Save doctors to cache indefinitely
  static Future<void> setDoctorsByHospital(
    String hospitalId,
    List<dynamic> doctors,
  ) async {
    try {
      await _doctorsBox.put('doctors_$hospitalId', doctors);
      print('DEBUG: ✅ Doctors for $hospitalId saved to offline cache');
    } catch (e) {
      print('DEBUG: Error caching doctors: $e');
    }
  }

  /// Clear doctor cache for specific hospital
  static Future<void> clearDoctorsByHospital(String hospitalId) async {
    try {
      await _doctorsBox.delete('doctors_$hospitalId');
      print('DEBUG: CacheService - Doctor cache for $hospitalId cleared');
    } catch (e) {
      print('DEBUG: Error clearing doctor cache: $e');
    }
  }

  /// Clear all offline caches (called on user logout)
  static Future<void> clearAllCache() async {
    try {
      await _hospitalsBox.clear();
      await _doctorsBox.clear();
      await _usersBox.clear();
      await _bookingsBox.clear();
      print('DEBUG: 🗑️ All offline caches cleared on logout');
    } catch (e) {
      print('DEBUG: Error clearing all caches: $e');
    }
  }

  /// Get offline cache stats for debugging
  static Map<String, String> getCacheStats() {
    return {
      'hospitals_cached': _hasCacheData('hospitals') ? 'Yes' : 'No',
      'hospitals_count': _hospitalsBox.length.toString(),
      'doctors_count': _doctorsBox.length.toString(),
      'cache_mode': 'Indefinite Offline Persistence',
      'status': '✅ Ready for offline (mobile-first)',
    };
  }
}
