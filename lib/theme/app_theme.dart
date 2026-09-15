import 'package:flutter/material.dart';

class AppTheme {
  // Main brand colors from the Grails website.
  static const Color primaryYellow = Color(0xFFF7DC6F);
  static const Color primaryYellowStrong = Color(0xFFE3C54F);
  static const Color primaryYellowSoft = Color(0xFFFFF8D8);

  static const Color primaryBlue = Color(0xFF3178C6);
  static const Color primaryBlueDark = Color(0xFF245D9D);
  static const Color primaryBlueSoft = Color(0xFFE7F0FA);

  // Neutral colors.
  static const Color darkColor = Color(0xFF171717);
  static const Color darkSoft = Color(0xFF303030);
  static const Color textColor = Color(0xFF505050);
  static const Color mutedColor = Color(0xFF777777);
  static const Color borderColor = Color(0xFFCCCCCC);
  static const Color borderSoft = Color(0xFFE5E5E5);
  static const Color backgroundColor = Color(0xFFF7F7F7);
  static const Color cardColor = Color(0xFFFFFFFF);

  // Status colors.
  static const Color successColor = Color(0xFF278659);
  static const Color successSoft = Color(0xFFE6F4EC);
  static const Color errorColor = Color(0xFFFF3737);
  static const Color errorDark = Color(0xFFD92828);
  static const Color errorSoft = Color(0xFFFFE8E8);

  static const double smallRadius = 8;
  static const double defaultRadius = 10;
  static const double largeRadius = 14;

  static ThemeData get lightTheme {
    const ColorScheme colorScheme = ColorScheme.light(
      primary: primaryYellow,
      onPrimary: darkColor,
      secondary: primaryBlue,
      onSecondary: Colors.white,
      error: errorColor,
      onError: Colors.white,
      surface: cardColor,
      onSurface: darkColor,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundColor,
      fontFamily: 'monospace',

      dividerColor: borderSoft,

      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: darkColor,
          fontSize: 38,
          fontWeight: FontWeight.w700,
          height: 1.1,
          letterSpacing: -1.5,
        ),
        displayMedium: TextStyle(
          color: darkColor,
          fontSize: 32,
          fontWeight: FontWeight.w700,
          height: 1.1,
          letterSpacing: -1.2,
        ),
        headlineLarge: TextStyle(
          color: darkColor,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          height: 1.15,
          letterSpacing: -1,
        ),
        headlineMedium: TextStyle(
          color: darkColor,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          height: 1.2,
          letterSpacing: -0.7,
        ),
        titleLarge: TextStyle(
          color: darkColor,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          height: 1.25,
        ),
        titleMedium: TextStyle(
          color: darkColor,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
        titleSmall: TextStyle(
          color: primaryBlueDark,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
        bodyLarge: TextStyle(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          color: textColor,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.45,
        ),
        bodySmall: TextStyle(
          color: mutedColor,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          color: darkColor,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
        labelMedium: TextStyle(
          color: darkSoft,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: cardColor,
        foregroundColor: darkColor,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        toolbarHeight: 68,
        shape: Border(
          bottom: BorderSide(
            color: borderSoft,
            width: 1,
          ),
        ),
        titleTextStyle: TextStyle(
          color: darkColor,
          fontFamily: 'monospace',
          fontSize: 19,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(
          color: primaryBlue,
          size: 24,
        ),
      ),

      cardTheme: CardThemeData(
        color: cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          side: const BorderSide(
            color: borderColor,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(defaultRadius),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        labelStyle: const TextStyle(
          color: darkSoft,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        hintStyle: const TextStyle(
          color: mutedColor,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        prefixIconColor: primaryBlue,
        suffixIconColor: primaryBlue,
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(
            color: borderColor,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(defaultRadius),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(
            color: primaryBlue,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(defaultRadius),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(
            color: errorColor,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(defaultRadius),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(
            color: errorColor,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(defaultRadius),
        ),
        errorStyle: const TextStyle(
          color: errorDark,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryYellow,
          foregroundColor: darkColor,
          disabledBackgroundColor: borderSoft,
          disabledForegroundColor: mutedColor,
          minimumSize: const Size.fromHeight(54),
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 15,
          ),
          shape: RoundedRectangleBorder(
            side: const BorderSide(
              color: primaryYellowStrong,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(defaultRadius),
          ),
          textStyle: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlueDark,
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
          side: const BorderSide(
            color: primaryBlue,
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(defaultRadius),
          ),
          textStyle: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBlueDark,
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          textStyle: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: primaryBlue,
          backgroundColor: cardColor,
          highlightColor: primaryBlueSoft,
          shape: RoundedRectangleBorder(
            side: const BorderSide(
              color: borderSoft,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(defaultRadius),
          ),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: primaryBlueSoft,
        selectedColor: primaryYellow,
        disabledColor: borderSoft,
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 7,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(smallRadius),
        ),
        labelStyle: const TextStyle(
          color: primaryBlueDark,
          fontFamily: 'monospace',
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkColor,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontFamily: 'monospace',
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(defaultRadius),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: borderColor),
          borderRadius: BorderRadius.circular(largeRadius),
        ),
        titleTextStyle: const TextStyle(
          color: darkColor,
          fontFamily: 'monospace',
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: const TextStyle(
          color: textColor,
          fontFamily: 'monospace',
          fontSize: 14,
          height: 1.5,
        ),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryBlue,
        linearTrackColor: primaryBlueSoft,
        circularTrackColor: primaryBlueSoft,
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: cardColor,
        selectedItemColor: primaryBlue,
        unselectedItemColor: mutedColor,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(
          fontFamily: 'monospace',
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'monospace',
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        indicatorColor: primaryYellow,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
              (Set<WidgetState> states) {
            return TextStyle(
              color: states.contains(WidgetState.selected)
                  ? darkColor
                  : mutedColor,
              fontFamily: 'monospace',
              fontSize: 11,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w600,
            );
          },
        ),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
              (Set<WidgetState> states) {
            return IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? primaryBlueDark
                  : mutedColor,
              size: 23,
            );
          },
        ),
      ),
    );
  }
}