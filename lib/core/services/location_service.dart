import 'package:geolocator/geolocator.dart';
import 'package:geolocator/geolocator.dart' show placemarkFromCoordinates;
import 'package:url_launcher/url_launcher.dart';

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

  /// Get place name from coordinates using reverse geocoding
  static Future<String> getPlaceNameFromCoordinates(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        // Build a readable address from place information
        final parts = <String>[];
        
        if (place.name != null && place.name!.isNotEmpty) parts.add(place.name!);
        if (place.thoroughfare != null && place.thoroughfare!.isNotEmpty) parts.add(place.thoroughfare!);
        if (place.subLocality != null && place.subLocality!.isNotEmpty) parts.add(place.subLocality!);
        if (place.locality != null && place.locality!.isNotEmpty) parts.add(place.locality!);
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) parts.add(place.administrativeArea!);
        
        final address = parts.join(', ');
        print('DEBUG: Reverse geocoding - Got place name: $address');
        
        return address.isNotEmpty ? address : formatCoordinates(latitude, longitude);
      }
      
      // Fallback to coordinates if no place name found
      return formatCoordinates(latitude, longitude);
    } catch (e) {
      print('DEBUG: Error getting place name: $e');
      // Fallback to coordinates
      return formatCoordinates(latitude, longitude);
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

  /// Format coordinates to string
  static String formatCoordinates(double latitude, double longitude) {
    return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
  }

  /// Check if location is valid
  static bool isValidLocation(double? latitude, double? longitude) {
    return latitude != null && longitude != null && 
           latitude >= -90 && latitude <= 90 && 
           longitude >= -180 && longitude <= 180;
  }
}
