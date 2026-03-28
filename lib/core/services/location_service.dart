import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
export 'package:geocoding/geocoding.dart';

class LocationService {
  /// Get current location of device
  static Future<Position?> getCurrentLocation() async {
    try {
      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('DEBUG: Location permission denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('DEBUG: Location permission permanently denied');
        return null;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      print('DEBUG: Current location - Lat: ${position.latitude}, Lon: ${position.longitude}');
      return position;
    } catch (e) {
      print('DEBUG: Error getting location: $e');
      return null;
    }
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
    try {
      final List<geocoding.Placemark> placemarks = await geocoding.placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final geocoding.Placemark place = placemarks.first;
        // Try to build a readable address
        final List<String> addressParts = [];
        if (place.name != null && place.name!.isNotEmpty) addressParts.add(place.name!);
        if (place.locality != null && place.locality!.isNotEmpty) addressParts.add(place.locality!);
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) addressParts.add(place.administrativeArea!);
        if (place.country != null && place.country!.isNotEmpty) addressParts.add(place.country!);
        
        if (addressParts.isNotEmpty) {
          return addressParts.join(', ');
        }
      }
      // Fallback to coordinates if place name not found
      print('DEBUG: No place name found, using coordinates');
      return formatCoordinates(latitude, longitude);
    } catch (e) {
      print('DEBUG: Error getting place name: $e');
      return formatCoordinates(latitude, longitude);
    }
  }

  /// Format coordinates to string
  static String formatCoordinates(double latitude, double longitude) {
    return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
  }

  /// Get coordinates from place name (forward geocoding)
  static Future<({double latitude, double longitude})?> getCoordinatesFromPlace(String placeName) async {
    try {
      final locations = await geocoding.locationFromAddress(placeName);
      if (locations.isNotEmpty) {
        final location = locations.first;
        print('DEBUG: Geocoded "$placeName" to ${location.latitude}, ${location.longitude}');
        return (latitude: location.latitude, longitude: location.longitude);
      }
      print('DEBUG: No coordinates found for place: $placeName');
      return null;
    } catch (e) {
      print('DEBUG: Error geocoding place name: $e');
      return null;
    }
  }

  /// Check if location is valid
  static bool isValidLocation(double? latitude, double? longitude) {
    return latitude != null && longitude != null && 
           latitude >= -90 && latitude <= 90 && 
           longitude >= -180 && longitude <= 180;
  }
}
