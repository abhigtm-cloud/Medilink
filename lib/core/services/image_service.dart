import 'dart:io';
import 'dart:convert';
import 'package:image/image.dart' as img;

/// Service for image handling and validation
class ImageService {
  // Maximum file size: 2MB (Firebase Realtime DB safe limit for base64)
  static const int maxFileSizeBytes = 2 * 1024 * 1024; // 2MB
  
  // Maximum image dimensions for quality
  static const int maxWidth = 1024;
  static const int maxHeight = 1024;

  /// Validate image file size and dimensions
  static Future<ValidationResult> validateImage(File imageFile) async {
    try {
      // Check file size
      final fileSize = await imageFile.length();
      
      if (fileSize > maxFileSizeBytes) {
        final sizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(2);
        return ValidationResult(
          isValid: false,
          message: 'Image too large ($sizeMB MB). Maximum size is 2MB.',
        );
      }

      // Check image dimensions
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        return ValidationResult(
          isValid: false,
          message: 'Invalid image format. Please use JPG or PNG.',
        );
      }

      if (image.width > maxWidth || image.height > maxHeight) {
        return ValidationResult(
          isValid: false,
          message: 'Image dimensions too large (${image.width}x${image.height}). Maximum is 1024x1024.',
        );
      }

      return ValidationResult(isValid: true, message: 'Image is valid');
    } catch (e) {
      return ValidationResult(
        isValid: false,
        message: 'Error validating image: $e',
      );
    }
  }

  /// Compress and optimize image to base64
  static Future<String> imageToOptimizedBase64(File imageFile, {int quality = 80}) async {
    try {
      // Read image bytes
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('Could not decode image');
      }

      // Resize if needed
      img.Image resizedImage = image;
      if (image.width > maxWidth || image.height > maxHeight) {
        resizedImage = img.copyResize(
          image,
          width: image.width > maxWidth ? maxWidth : image.width,
          height: image.height > maxHeight ? maxHeight : image.height,
          interpolation: img.Interpolation.linear,
        );
      }

      // Compress as JPEG
      final compressedBytes = img.encodeJpg(resizedImage, quality: quality);

      print('DEBUG: Original size: ${bytes.length} bytes, Compressed: ${compressedBytes.length} bytes');

      return base64Encode(compressedBytes);
    } catch (e) {
      print('DEBUG: Error compressing image: $e');
      // Fallback: just convert to base64 without compression
      final bytes = await imageFile.readAsBytes();
      return base64Encode(bytes);
    }
  }

  /// Check if base64 size is acceptable for Firebase
  static bool isBase64SizeAcceptable(String base64String) {
    // Base64 increases size by ~33%, so account for that
    final approximateBytes = (base64String.length * 3) ~/ 4;
    return approximateBytes < maxFileSizeBytes;
  }

  /// Get human-readable file size
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

/// Result of image validation
class ValidationResult {
  final bool isValid;
  final String message;

  ValidationResult({
    required this.isValid,
    required this.message,
  });
}
