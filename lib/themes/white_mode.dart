import 'package:flutter/material.dart';

ThemeData lightMode = ThemeData(
  brightness: Brightness.light,
  colorScheme: ColorScheme.light(
    surface: Colors.white,
    primary: const Color(0xFF003F88), // Rich government blue
    onPrimary: Colors.white,
    secondary: const Color(0xFF00509D), // Complementary blue
    onSecondary: Colors.white,
    tertiary: const Color(0xFFEEF6FF),
    error: const Color(0xFFB71C1C),
    onError: Colors.white,
    onSurface: const Color(0xFF14213D),
  ),
  scaffoldBackgroundColor: const Color(0xFFF8F9FA),
  cardTheme: const CardTheme(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(24)),
    ),
    clipBehavior: Clip.antiAlias,
  ),
  textTheme: const TextTheme(
    headlineSmall: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.5),
    titleLarge: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.15),
    titleMedium: TextStyle(fontWeight: FontWeight.w500, letterSpacing: 0.1),
    bodyLarge: TextStyle(letterSpacing: 0.5),
    bodyMedium: TextStyle(letterSpacing: 0.25),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 0,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF003F88), width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
  ),
);
