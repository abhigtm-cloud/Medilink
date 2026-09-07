import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
export 'package:geocoding/geocoding.dart';

class LocationService {
  // In-memory cache for resolved place names to prevent redundant geocoding queries
  static final Map<String, String> _placeNameCache = {};

  /// Get current location of device with bulletproof GPS detection & fast fallback
  static Future<Position?> getCurrentLocation() async {
    try {
      // 1. Check if location services are enabled on device
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        final lastPos = await Geolocator.getLastKnownPosition();
        if (lastPos != null) return lastPos;
      }

      // 2. Check and request location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        print('DEBUG: Location permission denied, attempting last known position');
        final lastPos = await Geolocator.getLastKnownPosition();
        if (lastPos != null) return lastPos;
        return _fallbackPosition();
      }

      // 3. Fast path: If last known position is fresh, keep as instantaneous backup
      final lastPos = await Geolocator.getLastKnownPosition();

      // 4. Request fresh GPS fix with realistic accuracy and timeout
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 7),
        );
        print('DEBUG: ✅ GPS fix obtained: Lat: ${position.latitude}, Lon: ${position.longitude}');
        return position;
      } catch (gpsErr) {
        print('DEBUG: High-accuracy GPS timed out ($gpsErr), using last known or network fix');
        if (lastPos != null) return lastPos;
        return _fallbackPosition();
      }
    } catch (e) {
      print('DEBUG: Location error: $e, using default fallback position');
      return _fallbackPosition();
    }
  }

  /// Default fallback position when GPS is disabled or unavailable
  static Position _fallbackPosition() {
    return Position(
      latitude: 30.7441,
      longitude: 76.6471,
      timestamp: DateTime.now(),
      accuracy: 100,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
  }

  /// Open Google Maps navigation to a specific location
  static Future<void> openGoogleMaps({
    required double latitude,
    required double longitude,
    required String locationName,
  }) async {
    try {
      final String encodedName = Uri.encodeComponent(locationName);
      final String googleMapsUrl =
          'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude&query_place_id=$encodedName';
      
      final uri = Uri.parse(googleMapsUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        final fallbackUri = Uri.parse('https://maps.google.com/?q=$latitude,$longitude');
        await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('DEBUG: Error opening Google Maps: $e');
    }
  }

  /// Get a clean, human-readable place name from coordinates (Never returns raw numbers)
  static Future<String> getPlaceName(double latitude, double longitude) async {
    final cacheKey = '${latitude.toStringAsFixed(3)}_${longitude.toStringAsFixed(3)}';
    if (_placeNameCache.containsKey(cacheKey)) {
      return _placeNameCache[cacheKey]!;
    }

    // 1. Native platform reverse geocoder (Primary on Mobile/Android)
    if (!kIsWeb) {
      try {
        final placemarks = await geocoding.placemarkFromCoordinates(latitude, longitude).timeout(const Duration(seconds: 4));
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = <String>[];

          // Sub-locality / Area / Street
          if (p.subLocality != null && p.subLocality!.trim().isNotEmpty) {
            parts.add(p.subLocality!.trim());
          } else if (p.street != null && p.street!.trim().isNotEmpty && !p.street!.contains('+') && p.street != p.name) {
            parts.add(p.street!.trim());
          } else if (p.name != null && p.name!.trim().isNotEmpty && !p.name!.contains('+')) {
            parts.add(p.name!.trim());
          }

          // Locality / City / Town
          if (p.locality != null && p.locality!.trim().isNotEmpty) {
            if (!parts.contains(p.locality!.trim())) parts.add(p.locality!.trim());
          } else if (p.subAdministrativeArea != null && p.subAdministrativeArea!.trim().isNotEmpty) {
            if (!parts.contains(p.subAdministrativeArea!.trim())) parts.add(p.subAdministrativeArea!.trim());
          }

          // State / Administrative Area
          if (p.administrativeArea != null && p.administrativeArea!.trim().isNotEmpty) {
            if (!parts.contains(p.administrativeArea!.trim())) parts.add(p.administrativeArea!.trim());
          }

          if (parts.isNotEmpty) {
            final place = parts.join(', ');
            _placeNameCache[cacheKey] = place;
            return place;
          }
        }
      } catch (nativeErr) {
        print('DEBUG: Native geocoding note: $nativeErr');
      }
    }

    // 2. OpenStreetMap Nominatim Reverse Geocoding (Web + Fallback)
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 4),
        receiveTimeout: const Duration(seconds: 4),
        headers: {'User-Agent': 'MediLinkApp/1.0 (contact@medilink.app)'},
      ));
      final response = await dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'lat': latitude,
          'lon': longitude,
          'format': 'json',
          'addressdetails': '1',
        },
      );
      if (response.data is Map) {
        final data = response.data as Map;
        final addr = data['address'] as Map?;
        if (addr != null) {
          final sub = addr['suburb'] ?? addr['neighbourhood'] ?? addr['residential'] ?? addr['road'] ?? addr['quarter'];
          final city = addr['city'] ?? addr['town'] ?? addr['village'] ?? addr['county'] ?? addr['municipality'];
          final state = addr['state'];

          final parts = <String>[];
          if (sub != null && sub.toString().isNotEmpty) parts.add(sub.toString());
          if (city != null && city.toString().isNotEmpty && !parts.contains(city.toString())) parts.add(city.toString());
          if (state != null && state.toString().isNotEmpty && !parts.contains(state.toString())) parts.add(state.toString());

          if (parts.isNotEmpty) {
            final result = parts.join(', ');
            _placeNameCache[cacheKey] = result;
            return result;
          }
        }
        if (data['display_name'] != null) {
          final split = data['display_name'].toString().split(', ');
          if (split.length >= 3) {
            final clean = '${split[0]}, ${split[1]}, ${split[2]}';
            _placeNameCache[cacheKey] = clean;
            return clean;
          }
          return data['display_name'].toString();
        }
      }
    } catch (_) {}

    // 3. Proximity-based City Recognition Dictionary (Works 100% Offline)
    final recognized = _resolveKnownCityByProximity(latitude, longitude);
    if (recognized != null) {
      _placeNameCache[cacheKey] = recognized;
      return recognized;
    }

    return 'Current Device Location';
  }

  /// Resolve closest major city/hub if offline
  static String? _resolveKnownCityByProximity(double lat, double lon) {
    final hubs = <String, ({double lat, double lon})>{
      'Kharar, Mohali, Punjab': (lat: 30.7441, lon: 76.6471),
      'Chandigarh, India': (lat: 30.7333, lon: 76.7794),
      'Mohali, Punjab': (lat: 30.7046, lon: 76.7179),
      'Panchkula, Haryana': (lat: 30.6942, lon: 76.8606),
      'Zirakpur, Punjab': (lat: 30.6425, lon: 76.8173),
      'Patiala, Punjab': (lat: 30.3398, lon: 76.3869),
      'Ludhiana, Punjab': (lat: 30.9010, lon: 75.8573),
      'Jalandhar, Punjab': (lat: 31.3260, lon: 75.5762),
      'Amritsar, Punjab': (lat: 31.6340, lon: 74.8723),
      'New Delhi, NCR': (lat: 28.6139, lon: 77.2090),
      'Noida, Uttar Pradesh': (lat: 28.5355, lon: 77.3910),
      'Gurugram, Haryana': (lat: 28.4595, lon: 77.0266),
      'Mumbai, Maharashtra': (lat: 19.0760, lon: 72.8777),
      'Pune, Maharashtra': (lat: 18.5204, lon: 73.8567),
      'Bengaluru, Karnataka': (lat: 12.9716, lon: 77.5946),
      'Hyderabad, Telangana': (lat: 17.3850, lon: 78.4867),
      'Chennai, Tamil Nadu': (lat: 13.0827, lon: 80.2707),
      'Kolkata, West Bengal': (lat: 22.5726, lon: 88.3639),
      'Jaipur, Rajasthan': (lat: 26.9124, lon: 75.7873),
      'Lucknow, Uttar Pradesh': (lat: 26.8467, lon: 80.9462),
      'Ahmedabad, Gujarat': (lat: 23.0225, lon: 72.5714),
      'Dehradun, Uttarakhand': (lat: 30.3165, lon: 78.0322),
      'Shimla, Himachal Pradesh': (lat: 31.1048, lon: 77.1734),
    };

    String? closestName;
    double closestDist = 999999;

    for (final entry in hubs.entries) {
      final distMeters = Geolocator.distanceBetween(lat, lon, entry.value.lat, entry.value.lon);
      final distKm = distMeters / 1000.0;
      if (distKm < closestDist && distKm <= 35.0) {
        closestDist = distKm;
        closestName = entry.key;
      }
    }

    return closestName;
  }

  /// Format distance into clean human-readable unit
  static String formatDistance(double? distKm) {
    if (distKm == null) return 'Distance unavailable';
    if (distKm < 0.05) return 'Here (< 50m)';
    if (distKm < 1.0) return '${(distKm * 1000).round()} m away';
    return '${distKm.toStringAsFixed(1)} km away';
  }

  /// Get coordinates from place name (forward geocoding - web & mobile safe)
  static Future<({double latitude, double longitude})?> getCoordinatesFromPlace(String placeName) async {
    final clean = placeName.trim().toLowerCase();
    if (clean.isEmpty) return null;

    // 1. Fast offline dictionary for common hospital cities
    if (clean.contains('kharar')) return (latitude: 30.7441, longitude: 76.6471);
    if (clean.contains('chandigarh')) return (latitude: 30.7333, longitude: 76.7794);
    if (clean.contains('mohali') || clean.contains('sas nagar')) return (latitude: 30.7046, longitude: 76.7179);
    if (clean.contains('panchkula')) return (latitude: 30.6942, longitude: 76.8606);
    if (clean.contains('zirakpur')) return (latitude: 30.6425, longitude: 76.8173);
    if (clean.contains('ludhiana')) return (latitude: 30.9010, longitude: 75.8573);
    if (clean.contains('jalandhar')) return (latitude: 31.3260, longitude: 75.5762);
    if (clean.contains('amritsar')) return (latitude: 31.6340, longitude: 74.8723);
    if (clean.contains('patiala')) return (latitude: 30.3398, longitude: 76.3869);
    if (clean.contains('delhi') || clean.contains('ncr')) return (latitude: 28.6139, longitude: 77.2090);
    if (clean.contains('noida')) return (latitude: 28.5355, longitude: 77.3910);
    if (clean.contains('gurugram') || clean.contains('gurgaon')) return (latitude: 28.4595, longitude: 77.0266);
    if (clean.contains('mumbai')) return (latitude: 19.0760, longitude: 72.8777);
    if (clean.contains('pune')) return (latitude: 18.5204, longitude: 73.8567);
    if (clean.contains('bangalore') || clean.contains('bengaluru')) return (latitude: 12.9716, longitude: 77.5946);
    if (clean.contains('hyderabad')) return (latitude: 17.3850, longitude: 78.4867);
    if (clean.contains('chennai')) return (latitude: 13.0827, longitude: 80.2707);
    if (clean.contains('kolkata')) return (latitude: 22.5726, longitude: 88.3639);
    if (clean.contains('jaipur')) return (latitude: 26.9124, longitude: 75.7873);
    if (clean.contains('lucknow')) return (latitude: 26.8467, longitude: 80.9462);
    if (clean.contains('ahmedabad')) return (latitude: 23.0225, longitude: 72.5714);

    // 2. OpenStreetMap Nominatim REST Geocoder
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 4),
        receiveTimeout: const Duration(seconds: 4),
        headers: {'User-Agent': 'MediLinkApp/1.0 (contact@medilink.app)'},
      ));
      final response = await dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': placeName,
          'format': 'json',
          'limit': 1,
        },
      );
      if (response.data is List && (response.data as List).isNotEmpty) {
        final item = (response.data as List)[0] as Map;
        final lat = double.tryParse(item['lat']?.toString() ?? '');
        final lon = double.tryParse(item['lon']?.toString() ?? '');
        if (lat != null && lon != null) {
          return (latitude: lat, longitude: lon);
        }
      }
    } catch (_) {}

    // 3. Native forward geocoder on mobile
    if (!kIsWeb) {
      try {
        final locations = await geocoding.locationFromAddress(placeName);
        if (locations.isNotEmpty) {
          final location = locations.first;
          return (latitude: location.latitude, longitude: location.longitude);
        }
      } catch (_) {}
    }

    return null;
  }

  /// Check if location is valid
  static bool isValidLocation(double? latitude, double? longitude) {
    return latitude != null && longitude != null && 
           latitude >= -90 && latitude <= 90 && 
           longitude >= -180 && longitude <= 180;
  }
}
