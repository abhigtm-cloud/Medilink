import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Professional white/clinical theme for MEDILINK.
/// Neutral grays, white backgrounds, subtle borders.
class AppTheme {
  // Neutral palette — no green; professional medical look
  static const Color _primary = Color(0xFF1A1A2E);
  static const Color _surface = Color(0xFFFAFAFA);
  static const Color _cardBg = Colors.white;
  static const Color _border = Color(0xFFE8E8E8);
  static const Color _textPrimary = Color(0xFF1A1A2E);
  static const Color _textSecondary = Color(0xFF6B7280);

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: _primary,
        onPrimary: Colors.white,
        surface: _cardBg,
        onSurface: _textPrimary,
        surfaceContainerHighest: _surface,
        outline: _border,
        error: const Color(0xFFDC2626),
      ),
      scaffoldBackgroundColor: _surface,
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        headlineMedium: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: _textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: _textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: _textSecondary,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      scaffoldBackgroundColor: _surface,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: _border, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        color: _cardBg,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _cardBg,
        foregroundColor: _textPrimary,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: _textPrimary,
        ),
        iconTheme: const IconThemeData(color: _textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _cardBg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(color: _textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _textPrimary,
          side: const BorderSide(color: _border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  static ThemeData get dark {
    const Color darkSurface = Color(0xFF121212);
    const Color darkCard = Color(0xFF1E1E1E);
    const Color darkBorder = Color(0xFF2C2C2C);

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: Colors.white,
        onPrimary: _primary,
        surface: darkCard,
        onSurface: Colors.white,
        surfaceContainerHighest: darkSurface,
        outline: darkBorder,
      ),
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      scaffoldBackgroundColor: darkSurface,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: darkBorder),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        color: darkCard,
      ),
      appBarTheme: base.appBarTheme.copyWith(
        centerTitle: true,
        elevation: 0,
        backgroundColor: darkCard,
      ),
    );
  }
}
