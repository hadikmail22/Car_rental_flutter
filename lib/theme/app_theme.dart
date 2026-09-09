import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryYellow = Color(0xFFF7DC6F);
  static const Color primaryBlue = Color(0xFF3178C6);
  static const Color darkColor = Color(0xFF171717);
  static const Color backgroundColor = Color(0xFFF7F7F7);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundColor,

      colorScheme: const ColorScheme.light(
        primary: primaryYellow,
        onPrimary: darkColor,
        secondary: primaryBlue,
        onSecondary: Colors.white,
        surface: Colors.white,
        onSurface: darkColor,
        error: Color(0xFFFF3737),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: darkColor,
        centerTitle: true,
        elevation: 0,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryYellow,
          foregroundColor: darkColor,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
