import 'package:flutter/material.dart';

/// Moonlight Village Design System
class AppTheme {
  // Color Palette
  static const Color primaryPurple = Color(0xFF2D1B4E);
  static const Color bloodRed = Color(0xFF8B0000);
  static const Color moonlitSilver = Color(0xFFC0C0D8);
  static const Color midnightBlue = Color(0xFF0F0A1E);
  static const Color darkPurple = Color(0xFF1A0F2E);
  static const Color gold = Color(0xFFD4AF37);
  static const Color aliveGreen = Color(0xFF2E7D32);
  static const Color deadGray = Color(0xFF424242);
  
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: midnightBlue,
      primaryColor: primaryPurple,
      colorScheme: ColorScheme.dark(
        primary: primaryPurple,
        secondary: bloodRed,
        surface: darkPurple,
        onPrimary: moonlitSilver,
        onSecondary: Colors.white,
        onSurface: moonlitSilver,
      ),
      
      // Typography
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Cinzel',
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: moonlitSilver,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Cinzel',
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: moonlitSilver,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Cinzel',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: moonlitSilver,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Lora',
          fontSize: 16,
          color: moonlitSilver.withOpacity(0.9),
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Lora',
          fontSize: 14,
          color: moonlitSilver.withOpacity(0.8),
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: darkPurple,
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPurple,
          foregroundColor: moonlitSilver,
          elevation: 6,
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: TextStyle(
            fontFamily: 'Cinzel',
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
  
  // Custom Gradients
  static const Gradient moonlightGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0F0A1E),
      Color(0xFF2D1B4E),
      Color(0xFF1A0F2E),
    ],
  );
  
  static const Gradient dayGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF87CEEB),
      Color(0xFFFFE4B5),
      Color(0xFFFFDAB9),
    ],
  );
  
  // Shadows
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.3),
      blurRadius: 12,
      offset: Offset(0, 6),
    ),
  ];
  
  static List<BoxShadow> get glowShadow => [
    BoxShadow(
      color: moonlitSilver.withOpacity(0.3),
      blurRadius: 20,
      spreadRadius: 2,
    ),
  ];
}