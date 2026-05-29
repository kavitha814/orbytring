import 'package:flutter/material.dart';

class AppTheme {
  // Orbytring Premium Light Palette
  static const Color lightBackground = Color(0xFFF8FAFC);  // Premium clinical soft white/grey
  static const Color cardBackground = Color(0xFFFFFFFF);   // Pure white surfaces
  static const Color accentAuricGold = Color(0xFFC5A059);  // Signature Orbyt Gold branding
  static const Color accentRoseGold = Color(0xFFD49A8F);   // Orbyt Rose Gold for vitals streams
  static const Color textStellarBlack = Color(0xFF0F172A); // Deep rich black typography
  static const Color textGunmetal = Color(0xFF64748B);     // Cool steel slate for secondary text
  static const Color borderSteelSilver = Color(0xFFE2E8F0); // Subtle metallic dividers/borders

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: accentAuricGold,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: const ColorScheme.light(
        primary: accentAuricGold,
        secondary: accentRoseGold,
        surface: cardBackground,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: cardBackground,
        elevation: 0,
        centerTitle: true,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: textStellarBlack,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
        iconTheme: IconThemeData(color: textStellarBlack),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: textStellarBlack,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        titleMedium: TextStyle(
          color: textStellarBlack,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: textStellarBlack,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: textGunmetal,
          fontSize: 14,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
            color: borderSteelSilver,
            width: 1.0,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentAuricGold,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return accentAuricGold;
          }
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return accentAuricGold.withOpacity(0.3);
          }
          return null;
        }),
      ),
    );
  }
}
