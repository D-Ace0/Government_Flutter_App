import 'package:flutter/material.dart';

// Government-focused color palette with accessible contrast ratios
ThemeData lightMode = ThemeData(
  brightness: Brightness.light,
  useMaterial3: true,
  fontFamily: 'Roboto',
  
  // Color scheme based on government design systems
  colorScheme: ColorScheme.light(
    primary: const Color(0xFF1A4480), // Deep navy blue - primary action color
    onPrimary: Colors.white,
    primaryContainer: const Color(0xFFD9E8F6), // Light blue for containers/backgrounds
    onPrimaryContainer: const Color(0xFF0A2240), // Dark blue for text on light blue
    
    secondary: const Color(0xFF2E8540), // Green for success/confirmation
    onSecondary: Colors.white,
    secondaryContainer: const Color(0xFFE7F4E4), // Light green container
    onSecondaryContainer: const Color(0xFF1B5E20), // Dark green for text
    
    surface: Colors.white,
    onSurface: const Color(0xFF1B1B1B), // Near black text for content
    
    surfaceContainerLowest: const Color(0xFFF5F5F5), // Light gray background (replacing background)
    
    error: const Color(0xFFD83933), // Red for errors
    onError: Colors.white,
    
    tertiary: const Color(0xFF02BFE7), // Bright blue for accents
    tertiaryContainer: const Color(0xFFE1F3FC),
    
    outline: const Color(0xFF71767A), // Medium gray for borders
    outlineVariant: const Color(0xFFDFE1E2), // Light gray for dividers
  ),
  
  // Button themes
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
  ),
  
  // Text themes for consistent typography hierarchy
  textTheme: const TextTheme(
    headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5),
    headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
    headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
    titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    titleSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(fontSize: 16, height: 1.5),
    bodyMedium: TextStyle(fontSize: 14, height: 1.5),
    bodySmall: TextStyle(fontSize: 12, height: 1.5),
  ),
  
  // Input decoration for consistent form fields
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(width: 1, color: Color(0xFFDFE1E2)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(width: 1, color: Color(0xFFDFE1E2)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(width: 2, color: Color(0xFF1A4480)),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(width: 1, color: Color(0xFFD83933)),
    ),
    hintStyle: const TextStyle(color: Color(0xFF71767A)),
  ),
  
  // Card theme for consistent card styling
  cardTheme: CardTheme(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    elevation: 1,
    margin: const EdgeInsets.all(0),
  ),
  
  // App bar theme
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF1A4480),
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: false,
  ),
  
  // Dialog theme
  dialogTheme: DialogTheme(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    elevation: 4,
  ),
);

