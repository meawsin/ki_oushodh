// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const _fontFamily = 'Roboto';

  static TextTheme _buildTextTheme(Color baseColor) {
    return TextTheme(
      displayLarge: TextStyle(fontFamily: _fontFamily, fontSize: 40, fontWeight: FontWeight.w800, color: baseColor, height: 1.2),
      displayMedium: TextStyle(fontFamily: _fontFamily, fontSize: 32, fontWeight: FontWeight.w700, color: baseColor, height: 1.25),
      displaySmall: TextStyle(fontFamily: _fontFamily, fontSize: 26, fontWeight: FontWeight.w700, color: baseColor, height: 1.3),
      bodyLarge: TextStyle(fontFamily: _fontFamily, fontSize: 20, fontWeight: FontWeight.w500, color: baseColor, height: 1.6),
      bodyMedium: TextStyle(fontFamily: _fontFamily, fontSize: 18, fontWeight: FontWeight.w400, color: baseColor, height: 1.6),
      labelLarge: TextStyle(fontFamily: _fontFamily, fontSize: 20, fontWeight: FontWeight.w700, color: baseColor, letterSpacing: 0.5),
    );
  }

  // ── DARK THEME ─────────────────────────────────────────────────────────────
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      surface: Color(0xFF0A0A0A),          // Main background
      surfaceContainerLow: Color(0xFF111111),   // Card background
      surfaceContainerHighest: Color(0xFF1E1E1E), // Elevated surface
      onSurface: Color(0xFFF5F5F5),        // Primary text
      onSurfaceVariant: Color(0xFF999999), // Secondary text
      primary: Color(0xFFFFBF00),          // Accent (amber)
      onPrimary: Color(0xFF1A1A00),        // Text on accent
      secondary: Color(0xFF4DD0E1),
      onSecondary: Color(0xFF001A1E),
      error: Color(0xFFFF5252),
      onError: Color(0xFF1A0000),
      outline: Color(0x0FFFFFFF),          // Subtle border (~6% white)
      outlineVariant: Color(0x1AFFFFFF),   // Stronger border (~10% white)
    ),
    textTheme: _buildTextTheme(const Color(0xFFF5F5F5)),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFFBF00),
        foregroundColor: const Color(0xFF1A1A00),
        minimumSize: const Size(double.infinity, 64),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        elevation: 0,
      ),
    ),
  );

  // ── LIGHT THEME ────────────────────────────────────────────────────────────
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      surface: Color(0xFFF5F5F0),          // Warm off-white background
      surfaceContainerLow: Color(0xFFFFFFFF),   // Card background
      surfaceContainerHighest: Color(0xFFE8E8E0), // Elevated surface
      onSurface: Color(0xFF1A1A1A),        // Primary text
      onSurfaceVariant: Color(0xFF666666), // Secondary text
      primary: Color(0xFF1A6B3C),          // Accent (deep green — readable on white)
      onPrimary: Color(0xFFFFFFFF),        // Text on accent
      secondary: Color(0xFF0F6E56),
      onSecondary: Color(0xFFFFFFFF),
      error: Color(0xFFB71C1C),
      onError: Color(0xFFFFFFFF),
      outline: Color(0x1A000000),          // Subtle border (~10% black)
      outlineVariant: Color(0x33000000),   // Stronger border (~20% black)
    ),
    textTheme: _buildTextTheme(const Color(0xFF1A1A1A)),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1A6B3C),
        foregroundColor: const Color(0xFFFFFFFF),
        minimumSize: const Size(double.infinity, 64),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        elevation: 0,
      ),
    ),
  );
}