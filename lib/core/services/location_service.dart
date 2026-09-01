import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
export 'package:geocoding/geocoding.dart';

class LocationService {
  /// Get current location of device with fallback safety for web & desktop browsers
  static Future<Position?> getCurrentLocation() async {
    try {
      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        print('DEBUG: Location permission denied, using default fallback position');
        return _fallbackPosition();
      }

      // Get current position with a 5-second timeout
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      
      print('DEBUG: Current location - Lat: ${position.latitude}, Lon: ${position.longitude}');
      return position;
    } catch (e) {
      print('DEBUG: Location unavailable or timed out ($e), using fallback position');
      return _fallbackPosition();
    }
  }

  /// Default fallback position when GPS is unavailable, blocked, or timing out (e.g. desktop browsers)
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

  /// Open Google Maps for a specific location
  static Future<void> openGoogleMaps({
    required double latitude,
    required double longitude,
    required String locationName,
  }) async {
    try {
      final String googleMapsUrl =
          'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
      
      if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
        await launchUrl(
          Uri.parse(googleMapsUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        print('DEBUG: Could not launch Google Maps');
      }
    } catch (e) {
      print('DEBUG: Error opening Google Maps: $e');
    }
  }

  /// Get place name from coordinates (reverse geocoding)
  static Future<String> getPlaceName(double latitude, double longitude) async {
    // 1. Check known area bounding coordinates
    if (latitude >= 30.70 && latitude <= 30.78 && longitude >= 76.60 && longitude <= 76.70) {
      return 'Kharar, Mohali, Punjab';
    }
    if (latitude >= 30.68 && latitude <= 30.79 && longitude >= 76.70 && longitude <= 76.84) {
      return 'Chandigarh, India';
    }
    if (latitude >= 28.50 && latitude <= 28.75 && longitude >= 77.00 && longitude <= 77.35) {
      return 'New Delhi, India';
    }

    // 2. Try REST reverse geocoding via OpenStreetMap Nominatim (Works everywhere on Web)
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
        },
      );
      if (response.data is Map && response.data['display_name'] != null) {
        return response.data['display_name'].toString();
      }
    } catch (_) {}

    // 3. Fallback to native geocoding on mobile
    if (!kIsWeb) {
      try {
        final List<geocoding.Placemark> placemarks =
            await geocoding.placemarkFromCoordinates(latitude, longitude);
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final parts = <String>[];
          if (place.name?.isNotEmpty == true) parts.add(place.name!);
          if (place.locality?.isNotEmpty == true) parts.add(place.locality!);
          if (place.administrativeArea?.isNotEmpty == true) parts.add(place.administrativeArea!);
          if (parts.isNotEmpty) return parts.join(', ');
        }
      } catch (_) {}
    }

    return formatCoordinates(latitude, longitude);
  }

  /// Format coordinates to string
  static String formatCoordinates(double latitude, double longitude) {
    return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
  }

  /// Get coordinates from place name (forward geocoding - web & mobile safe)
  static Future<({double latitude, double longitude})?> getCoordinatesFromPlace(String placeName) async {
    final clean = placeName.trim().toLowerCase();
    if (clean.isEmpty) return null;

    // 1. Fast, offline dictionary for commonly searched hospital areas
    if (clean.contains('kharar')) return (latitude: 30.7441, longitude: 76.6471);
    if (clean.contains('chandigarh')) return (latitude: 30.7333, longitude: 76.7794);
    if (clean.contains('mohali')) return (latitude: 30.7046, longitude: 76.7179);
    if (clean.contains('panchkula')) return (latitude: 30.6942, longitude: 76.8606);
    if (clean.contains('delhi')) return (latitude: 28.6139, longitude: 77.2090);
    if (clean.contains('mumbai')) return (latitude: 19.0760, longitude: 72.8777);
    if (clean.contains('bangalore') || clean.contains('bengaluru')) return (latitude: 12.9716, longitude: 77.5946);
    if (clean.contains('lahore')) return (latitude: 31.5204, longitude: 74.3587);
    if (clean.contains('islamabad')) return (latitude: 33.6844, longitude: 73.0479);
    if (clean.contains('karachi')) return (latitude: 24.8607, longitude: 67.0011);

    // 2. OpenStreetMap Nominatim REST Geocoder (Works universally across Web, Mobile & Desktop)
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
          print('DEBUG: Geocoded "$placeName" to $lat, $lon via Nominatim');
          return (latitude: lat, longitude: lon);
        }
      }
    } catch (e) {
      print('DEBUG: Nominatim forward geocoding fallback error: $e');
    }

    // 3. Fallback to native plugin on mobile platforms
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
