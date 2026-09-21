import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Main brand colors from the Grails website (unchanged).
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

  /*
   * Two typefaces with clear roles:
   *
   * - JetBrains Mono for headings, buttons, labels, plates and prices.
   *   The website uses Geist Mono and falls back to JetBrains Mono,
   *   so the app keeps the same technical character.
   *
   * - IBM Plex Sans for paragraphs and descriptions, because long
   *   sentences in a monospaced face are tiring to read on a phone.
   */
  static TextStyle mono({
    required double fontSize,
    FontWeight fontWeight = FontWeight.w700,
    Color color = darkColor,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextStyle sans({
    required double fontSize,
    FontWeight fontWeight = FontWeight.w400,
    Color color = textColor,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.ibmPlexSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

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

      // Sans is the default, so any text that is not styled
      // explicitly stays comfortable to read.
      textTheme: TextTheme(
        displayLarge: mono(
          fontSize: 38,
          letterSpacing: -1.5,
          height: 1.1,
        ),
        displayMedium: mono(
          fontSize: 32,
          letterSpacing: -1.2,
          height: 1.1,
        ),
        headlineLarge: mono(
          fontSize: 27,
          letterSpacing: -1,
          height: 1.15,
        ),
        headlineMedium: mono(
          fontSize: 23,
          letterSpacing: -0.6,
          height: 1.2,
        ),
        titleLarge: mono(
          fontSize: 19,
          height: 1.25,
        ),
        titleMedium: mono(
          fontSize: 16,
          height: 1.3,
        ),
        titleSmall: mono(
          fontSize: 12,
          color: primaryBlueDark,
          letterSpacing: 1.2,
        ),
        bodyLarge: sans(
          fontSize: 16,
          height: 1.55,
        ),
        bodyMedium: sans(
          fontSize: 14,
          height: 1.5,
        ),
        bodySmall: sans(
          fontSize: 12.5,
          color: mutedColor,
          height: 1.45,
        ),
        labelLarge: mono(
          fontSize: 15,
        ),
        labelMedium: mono(
          fontSize: 12,
          color: darkSoft,
          letterSpacing: 0.6,
        ),
        labelSmall: mono(
          fontSize: 11,
          color: mutedColor,
          letterSpacing: 0.6,
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: borderSoft,
        thickness: 1,
        space: 1,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: cardColor,
        foregroundColor: darkColor,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        toolbarHeight: 66,
        shape: const Border(
          bottom: BorderSide(
            color: borderSoft,
            width: 1,
          ),
        ),
        titleTextStyle: mono(
          fontSize: 18,
          letterSpacing: -0.4,
        ),
        iconTheme: const IconThemeData(
          color: primaryBlue,
          size: 23,
        ),
      ),

      cardTheme: CardThemeData(
        color: cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          side: const BorderSide(
            color: borderSoft,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(largeRadius),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        labelStyle: mono(
          fontSize: 13,
          color: darkSoft,
        ),
        floatingLabelStyle: mono(
          fontSize: 13,
          color: primaryBlueDark,
        ),
        hintStyle: sans(
          fontSize: 14,
          color: mutedColor,
        ),
        helperStyle: sans(
          fontSize: 12,
          color: mutedColor,
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
        errorStyle: sans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: errorDark,
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
          textStyle: mono(
            fontSize: 15,
            letterSpacing: 0.2,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(defaultRadius),
          ),
          textStyle: mono(fontSize: 15),
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
          textStyle: mono(fontSize: 14),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBlueDark,
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          textStyle: mono(fontSize: 14),
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

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryYellow,
        foregroundColor: darkColor,
        elevation: 2,
        highlightElevation: 2,
        extendedTextStyle: mono(fontSize: 14),
        shape: RoundedRectangleBorder(
          side: const BorderSide(
            color: primaryYellowStrong,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(defaultRadius),
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
        labelStyle: mono(
          fontSize: 12,
          color: primaryBlueDark,
        ),
      ),

      listTileTheme: ListTileThemeData(
        titleTextStyle: mono(fontSize: 15),
        subtitleTextStyle: sans(fontSize: 13, color: mutedColor),
        iconColor: primaryBlue,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>(
              (Set<WidgetState> states) {
            return states.contains(WidgetState.selected)
                ? primaryBlue
                : cardColor;
          },
        ),
        trackColor: WidgetStateProperty.resolveWith<Color>(
              (Set<WidgetState> states) {
            return states.contains(WidgetState.selected)
                ? primaryBlueSoft
                : borderSoft;
          },
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkColor,
        contentTextStyle: sans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(defaultRadius),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: borderSoft),
          borderRadius: BorderRadius.circular(largeRadius),
        ),
        titleTextStyle: mono(
          fontSize: 19,
          letterSpacing: -0.4,
        ),
        contentTextStyle: sans(
          fontSize: 14,
          height: 1.55,
        ),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryBlue,
        linearTrackColor: primaryBlueSoft,
        circularTrackColor: primaryBlueSoft,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: cardColor,
        selectedItemColor: primaryBlue,
        unselectedItemColor: mutedColor,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: mono(fontSize: 11),
        unselectedLabelStyle: mono(
          fontSize: 11,
          fontWeight: FontWeight.w500,
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
            final bool selected = states.contains(WidgetState.selected);

            return mono(
              fontSize: 11,
              color: selected ? darkColor : mutedColor,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            );
          },
        ),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
              (Set<WidgetState> states) {
            return IconThemeData(
              size: 23,
              color: states.contains(WidgetState.selected)
                  ? darkColor
                  : mutedColor,
            );
          },
        ),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: darkColor,
        unselectedLabelColor: mutedColor,
        indicatorColor: primaryBlue,
        labelStyle: mono(fontSize: 13),
        unselectedLabelStyle: mono(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),

      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: sans(fontSize: 14, color: darkColor),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(largeRadius),
          ),
        ),
      ),
    );
  }
}
