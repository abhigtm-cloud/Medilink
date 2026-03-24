import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Professional modern theme for MEDILINK Healthcare Platform.
/// Features modern medical blue, clean design, and professional aesthetics.
class AppTheme {
  // Modern Professional Color Palette
  // Primary: Medical Blue
  static const Color _primary = Color(0xFF0066CC);
  static const Color _primaryDark = Color(0xFF004999);
  static const Color _primaryLight = Color(0xFF3399FF);
  
  // Secondary: Teal Accent
  static const Color _secondary = Color(0xFF00BCD4);
  static const Color _secondaryLight = Color(0xFF80DEEA);
  
  // Error
  static const Color _error = Color(0xFFEF5350);
  
  // Surfaces
  static const Color _surface = Color(0xFFF8FBFF);
  static const Color _cardBg = Colors.white;
  static const Color _border = Color(0xFFE0E8F0);
  static const Color _divider = Color(0xFFEEF2F7);
  
  // Text Colors
  static const Color _textPrimary = Color(0xFF0D1B2A);
  static const Color _textSecondary = Color(0xFF546E7A);
  static const Color _textTertiary = Color(0xFF90A4AE);

  // Spacing constants
  static const double _borderRadius = 16;
  static const double _smallBorderRadius = 8;

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: _primary,
        onPrimary: Colors.white,
        primaryContainer: _primaryLight,
        onPrimaryContainer: _primary,
        secondary: _secondary,
        onSecondary: Colors.white,
        tertiary: const Color(0xFF667BFF),
        surface: _cardBg,
        onSurface: _textPrimary,
        surfaceContainerHighest: _surface,
        outline: _border,
        error: _error,
        errorContainer: const Color(0xFFEF5350).withOpacity(0.1),
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: _surface,
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        // Display Styles
        displayLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: _textPrimary,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: _textPrimary,
          letterSpacing: -0.3,
        ),
        displaySmall: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: _textPrimary,
        ),
        // Headline Styles
        headlineMedium: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: _textPrimary,
          letterSpacing: -0.2,
        ),
        headlineSmall: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: _textPrimary,
        ),
        // Title Styles
        titleLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: _textPrimary,
          letterSpacing: 0.1,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: _textPrimary,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _textSecondary,
        ),
        // Body Styles
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: _textPrimary,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: _textSecondary,
          height: 1.43,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: _textTertiary,
          height: 1.33,
        ),
        // Label Styles
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.1,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _primary,
          letterSpacing: 0.5,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      scaffoldBackgroundColor: _surface,
      // Card Theme
      cardTheme: CardThemeData(
        color: _cardBg,
        elevation: 2,
        shadowColor: _primary.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          side: const BorderSide(color: _border, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      ),
      // AppBar Theme
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 1,
        scrolledUnderElevation: 0,
        backgroundColor: _cardBg,
        foregroundColor: _textPrimary,
        surfaceTintColor: Colors.transparent,
        shadowColor: _primary.withOpacity(0.05),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: _textPrimary,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: _primary, size: 24),
      ),
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _cardBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_smallBorderRadius),
          borderSide: const BorderSide(color: _border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_smallBorderRadius),
          borderSide: const BorderSide(color: _border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_smallBorderRadius),
          borderSide: const BorderSide(color: _primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_smallBorderRadius),
          borderSide: const BorderSide(color: _error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_smallBorderRadius),
          borderSide: const BorderSide(color: _error, width: 2),
        ),
        hintStyle: const TextStyle(color: _textTertiary, fontSize: 14),
        labelStyle: const TextStyle(color: _textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
        floatingLabelStyle: const TextStyle(
          color: _primary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: _primary.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_smallBorderRadius),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primary,
          side: const BorderSide(color: _primary, width: 2),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_smallBorderRadius),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primary,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
      // Icon Button Theme
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: _primary,
        ),
      ),
      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: _primaryLight.withOpacity(0.1),
        selectedColor: _primary,
        disabledColor: _border.withOpacity(0.5),
        labelStyle: const TextStyle(
          color: _textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _border),
        ),
      ),
      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: _divider,
        space: 24,
        thickness: 1,
      ),
      // Lists
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textColor: _textPrimary,
        iconColor: _primary,
      ),
      // Progress Indicators
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: _primary,
        linearTrackColor: _divider,
        circularTrackColor: _divider,
      ),
      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _textPrimary,
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        actionTextColor: _secondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_smallBorderRadius),
        ),
        elevation: 4,
      ),
    );
  }

  static ThemeData get dark {
    const Color darkSurface = Color(0xFF0F1419);
    const Color darkCard = Color(0xFF1A2332);
    const Color darkBorder = Color(0xFF2C3E50);
    const Color darkDivider = Color(0xFF36495C);

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: _primaryLight,
        onPrimary: _primary,
        primaryContainer: _primary,
        onPrimaryContainer: _primaryLight,
        secondary: _secondaryLight,
        onSecondary: _primary,
        tertiary: const Color(0xFF9CA3FF),
        surface: darkCard,
        onSurface: Colors.white,
        surfaceContainerHighest: darkSurface,
        outline: darkBorder,
        error: _error,
        errorContainer: _error.withOpacity(0.2),
      ),
      scaffoldBackgroundColor: darkSurface,
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: -0.3,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: -0.2,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.1,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: const Color(0xFFE0E7FF),
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: const Color(0xFFBDC4FF),
          height: 1.43,
        ),
      ),
      scaffoldBackgroundColor: darkSurface,
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 1,
        scrolledUnderElevation: 0,
        backgroundColor: darkCard,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withOpacity(0.3),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: _primaryLight, size: 24),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_smallBorderRadius),
          borderSide: const BorderSide(color: darkBorder, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_smallBorderRadius),
          borderSide: const BorderSide(color: darkBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_smallBorderRadius),
          borderSide: const BorderSide(color: _primaryLight, width: 2),
        ),
        hintStyle: const TextStyle(color: _textTertiary, fontSize: 14),
        labelStyle: const TextStyle(
          color: Color(0xFFBDC4FF),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: _primary.withOpacity(0.4),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_smallBorderRadius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryLight,
          side: const BorderSide(color: _primaryLight, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_smallBorderRadius),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _primary.withOpacity(0.1),
        selectedColor: _primary,
        disabledColor: darkBorder.withOpacity(0.5),
        labelStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: darkBorder),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: darkDivider,
        space: 24,
        thickness: 1,
      ),
    );
  }

  // ============ UTILITY METHODS ============

  /// Professional shadow suitable for elevated components
  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: _primary.withOpacity(0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: _primary.withOpacity(0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  /// Soft shadow for cards
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 12,
      offset: const Offset(0, 2),
    ),
  ];

  /// Gradient from primary to secondary
  static LinearGradient get primaryGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_primary, _primaryDark],
  );

  /// Healthcare-themed gradient
  static LinearGradient get healthcareGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_primary, _secondary],
  );

  /// Subtle background gradient
  static LinearGradient get subtleGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_surface, _surface.withOpacity(0.8)],
  );
}
