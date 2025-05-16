import 'package:flutter/material.dart';

// Government-focused dark theme with accessible contrast ratios
ThemeData darkMode = ThemeData(
  brightness: Brightness.dark,
  useMaterial3: true,
  fontFamily: 'Roboto',
  
  // Color scheme based on government design systems
  colorScheme: ColorScheme.dark(
    primary: const Color(0xFF4D97FF), // Bright blue for primary actions
    onPrimary: Colors.black,
    primaryContainer: const Color(0xFF173A6C), // Darker blue for containers
    onPrimaryContainer: const Color(0xFFD9E8F6), // Light blue text
    
    secondary: const Color(0xFF5EBF74), // Lighter green for success/confirmation
    onSecondary: Colors.black,
    secondaryContainer: const Color(0xFF1E5E2F), // Dark green container
    onSecondaryContainer: const Color(0xFFE7F4E4), // Light green text
    
    surface: const Color(0xFF1F1F1F), // Dark surface
    onSurface: const Color(0xFFF5F5F5), // Light text for dark backgrounds
    
    surfaceContainerLowest: const Color(0xFF121212), // Very dark background (replacing background)
    
    error: const Color(0xFFFF8A85), // Lighter red for errors
    onError: Colors.black,
    
    tertiary: const Color(0xFF42D9FF), // Bright blue for accents
    tertiaryContainer: const Color(0xFF025E73), // Darker blue container
    onTertiaryContainer: const Color(0xFFE1F3FC), // Light blue text
    
    outline: const Color(0xFF9A9FA5), // Light gray for borders
    outlineVariant: const Color(0xFF2E3133), // Darker gray for dividers
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
    fillColor: const Color(0xFF2A2A2A),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(width: 1, color: Color(0xFF3A3A3A)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(width: 1, color: Color(0xFF3A3A3A)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(width: 2, color: Color(0xFF4D97FF)),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(width: 1, color: Color(0xFFFF8A85)),
    ),
    hintStyle: const TextStyle(color: Color(0xFF9A9FA5)),
  ),
  
  // Card theme for consistent card styling
  cardTheme: CardTheme(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    elevation: 1,
    margin: const EdgeInsets.all(0),
    color: const Color(0xFF2A2A2A),
  ),
  
  // App bar theme
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF173A6C),
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: false,
  ),
  
  // Dialog theme
  dialogTheme: DialogTheme(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    elevation: 4,
    backgroundColor: const Color(0xFF2A2A2A),
  ),
);
