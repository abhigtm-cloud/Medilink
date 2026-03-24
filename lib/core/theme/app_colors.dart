import 'package:flutter/material.dart';

/// Centralized color palette for the MEDILINK application.
/// Provides easy access to all colors used throughout the app.
class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF0066CC);
  static const Color primaryDark = Color(0xFF004999);
  static const Color primaryLight = Color(0xFF3399FF);
  static const Color primaryVeryLight = Color(0xFFE3F2FD);

  // Secondary Colors (Teal Accent)
  static const Color secondary = Color(0xFF00BCD4);
  static const Color secondaryLight = Color(0xFF80DEEA);
  static const Color secondaryVeryLight = Color(0xFFB2EBF2);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFFFC107);
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color error = Color(0xFFEF5350);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color info = Color(0xFF2196F3);
  static const Color infoLight = Color(0xFFE3F2FD);

  // Neutral Colors - Light Theme
  static const Color surfaceLight = Color(0xFFF8FBFF);
  static const Color cardLight = Colors.white;
  static const Color borderLight = Color(0xFFE0E8F0);
  static const Color dividerLight = Color(0xFFEEF2F7);
  static const Color textPrimaryLight = Color(0xFF0D1B2A);
  static const Color textSecondaryLight = Color(0xFF546E7A);
  static const Color textTertiaryLight = Color(0xFF90A4AE);

  // Neutral Colors - Dark Theme
  static const Color surfaceDark = Color(0xFF0F1419);
  static const Color cardDark = Color(0xFF1A2332);
  static const Color borderDark = Color(0xFF2C3E50);
  static const Color dividerDark = Color(0xFF36495C);
  static const Color textPrimaryDark = Colors.white;
  static const Color textSecondaryDark = Color(0xFFBDC4FF);
  static const Color textTertiaryDark = Color(0xFF9CA3AE);

  // Semantic Colors
  static const Color disabled = Color(0xFFBDBDBD);
  static const Color disabledLight = Color(0xFFF5F5F5);

  /// Get color based on brightness
  static Color getTextPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? textPrimaryLight
        : textPrimaryDark;
  }

  static Color getTextSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? textSecondaryLight
        : textSecondaryDark;
  }

  static Color getSurface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? surfaceLight
        : surfaceDark;
  }

  static Color getCard(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? cardLight
        : cardDark;
  }

  static Color getBorder(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? borderLight
        : borderDark;
  }
}
