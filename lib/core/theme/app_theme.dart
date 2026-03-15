import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// AppTheme
// All color choices target WCAG AA compliance (4.5:1 contrast ratio minimum)
// as mandated by the PRD §6 Non-Functional & Accessibility Requirements.
// ---------------------------------------------------------------------------
class AppTheme {
  AppTheme._(); // Prevent instantiation

  // --- Shared typography scale (large fonts are a PRD hard requirement) ---
  static const _fontFamily = 'Roboto'; // Fallback; Noto Serif Bengali added later

  static TextTheme _buildTextTheme(Color baseColor) {
    return TextTheme(
      // Used for the medicine name — must be unmistakably large
      displayLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 40,
        fontWeight: FontWeight.w800,
        color: baseColor,
        height: 1.2,
      ),
      displayMedium: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: baseColor,
        height: 1.25,
      ),
      displaySmall: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: baseColor,
        height: 1.3,
      ),
      // Used for the medicine summary — readable paragraph text
      bodyLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: baseColor,
        height: 1.6,
      ),
      bodyMedium: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: baseColor,
        height: 1.6,
      ),
      // Used for labels, buttons
      labelLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: baseColor,
        letterSpacing: 0.5,
      ),
    );
  }

  // -------------------------------------------------------------------------
  // DARK THEME (Primary / Default per PRD — highest contrast for elderly users)
  // -------------------------------------------------------------------------
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      // Deep black background for maximum contrast
      surface: Color(0xFF0A0A0A),
      onSurface: Color(0xFFF5F5F5),

      // Bright amber: warm, high-visibility primary action color
      primary: Color(0xFFFFBF00),
      onPrimary: Color(0xFF1A1A00),

      // Soft teal for secondary elements
      secondary: Color(0xFF4DD0E1),
      onSecondary: Color(0xFF001A1E),

      // Error states
      error: Color(0xFFFF5252),
      onError: Color(0xFF1A0000),

      // Card/surface variants
      surfaceContainerHighest: Color(0xFF1E1E1E),
      onSurfaceVariant: Color(0xFFCCCCCC),
    ),
    textTheme: _buildTextTheme(const Color(0xFFF5F5F5)),

    // --- Global elevated button style (the "Scan Again" button, etc.) ---
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFFBF00),
        foregroundColor: const Color(0xFF1A1A00),
        minimumSize: const Size(double.infinity, 72), // Full-width, tall tap target
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
        elevation: 4,
      ),
    ),
  );

  // -------------------------------------------------------------------------
  // LIGHT THEME (Optional — user-togglable per PRD Settings requirements)
  // -------------------------------------------------------------------------
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      surface: Color(0xFFFAFAFA),
      onSurface: Color(0xFF0D0D0D),

      primary: Color(0xFF1565C0), // Deep blue — sufficient contrast on white
      onPrimary: Color(0xFFFFFFFF),

      secondary: Color(0xFF00796B),
      onSecondary: Color(0xFFFFFFFF),

      error: Color(0xFFB71C1C),
      onError: Color(0xFFFFFFFF),

      surfaceContainerHighest: Color(0xFFE8E8E8),
      onSurfaceVariant: Color(0xFF333333),
    ),
    textTheme: _buildTextTheme(const Color(0xFF0D0D0D)),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: const Color(0xFFFFFFFF),
        minimumSize: const Size(double.infinity, 72),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
        elevation: 4,
      ),
    ),
  );
}