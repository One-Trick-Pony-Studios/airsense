import 'package:flutter/material.dart';

/// Centralized design system, color tokens, and theme configuration for AirSense.
class AppTheme {
  AppTheme._();

  // ── Primary Green Palette ────────────────────────────────────────────────
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color primaryGreenDark = Color(0xFF1B5E20);
  static const Color primaryGreenLight = Color(0xFF4CAF50);

  // ── Secondary Sky Blue Palette ───────────────────────────────────────────
  static const Color secondarySkyBlue = Color(0xFF0288D1);
  static const Color secondarySkyBlueLight = Color(0xFF03A9F4);

  // ── Sky Gradient Colors ──────────────────────────────────────────────────
  static const Color skyBlueTop = Color(0xFFB3E5FC);
  static const Color skyBlueMid = Color(0xFFE1F5FE);
  static const Color skyGreenBottom = Color(0xFFE8F5E9);

  // ── Surface & Card Colors ────────────────────────────────────────────────
  static const Color surfaceMint = Color(0xFFF4FBF7);
  static const Color cardBackground = Color(0xEBFFFFFF); // 92% opaque white
  static const Color navBarForeground = Colors.white;

  // ── Sensor Accent Colors ─────────────────────────────────────────────────
  static const Color novaAccent = Colors.blue;
  static const Color dhtAccent = Colors.deepOrange;

  // ── Reusable Sky Background Gradient ──────────────────────────────────────
  static const BoxDecoration skyGradientDecoration = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        skyBlueTop,
        skyBlueMid,
        skyGreenBottom,
      ],
    ),
  );

  // ── Application ThemeData Definition ─────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        primary: primaryGreen,
        secondary: secondarySkyBlue,
        surface: surfaceMint,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryGreen,
        foregroundColor: navBarForeground,
        elevation: 2,
        iconTheme: IconThemeData(color: navBarForeground),
        actionsIconTheme: IconThemeData(color: navBarForeground),
        titleTextStyle: TextStyle(
          color: navBarForeground,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
