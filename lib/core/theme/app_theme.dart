import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors
  static const Color bgColor = Color(0xFF0F172A); // Slate 900
  static const Color cardColor = Color(0xFF1E293B); // Slate 800
  static const Color accentColor = Color(0xFF0EA5E9); // Sky 500 (Neon Cyan)
  static const Color dangerColor = Color(0xFFEF4444); // Red 500
  static const Color successColor = Color(0xFF10B981); // Emerald 500
  static const Color warningColor = Color(0xFFF59E0B); // Amber 500
  
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF94A3B8); // Slate 400

  // ThemeData
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgColor,
      primaryColor: accentColor,
      colorScheme: const ColorScheme.dark(
        primary: accentColor,
        secondary: accentColor,
        surface: cardColor,
        background: bgColor,
        error: dangerColor,
      ),
      cardTheme: CardThemeData(
         color: cardColor,
         elevation: 4,
         shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withOpacity(0.05))
         ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20, 
          fontWeight: FontWeight.bold, 
          letterSpacing: 1.2
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 1),
        )
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        labelStyle: const TextStyle(color: textSecondary),
        enabledBorder: OutlineInputBorder(
           borderRadius: BorderRadius.circular(12), 
           borderSide: BorderSide(color: Colors.white.withOpacity(0.1))
        ),
        focusedBorder: OutlineInputBorder(
           borderRadius: BorderRadius.circular(12), 
           borderSide: const BorderSide(color: accentColor, width: 2)
        ),
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
    );
  }
}
