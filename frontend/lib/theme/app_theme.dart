import 'package:flutter/material.dart';

class AppTheme {
  // Couleurs principales de l'application
  static const Color kPrimaryBlue = Color(0xFF0D47A1); // Bleu profond
  static const Color kSecondaryGreen = Color(0xFF00796B); // Vert forêt
  static const Color kAccentPurple =
      Color.fromARGB(255, 0, 0, 0); // Violet royal
  static const Color kHighlightYellow = Color(0xFFFFC107); // Jaune ambre
  static const Color kBackgroundWhite = Color(0xFFF8F9FA); // Blanc cassé
  static const Color kErrorRed = Color(0xFFB00020); // Rouge erreur

  static const Color lightGray = Color(0xFFEDEDF1);
  static const Color skyBlue = Color(0xFF81C9F3);
  static const Color paleBlue = Color(0xFFD8EFF5);
  static const Color turquoise = Color(0xFF35C5CF);

  static final cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(15),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static final dialogDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.2),
        blurRadius: 15,
        offset: const Offset(0, 5),
      ),
    ],
  );

  static final buttonStyle = ElevatedButton.styleFrom(
    backgroundColor: turquoise,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  );

  static final inputDecoration = InputDecoration(
    filled: true,
    fillColor: lightGray,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: turquoise),
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
  );

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: kPrimaryBlue,
          secondary: kSecondaryGreen,
          tertiary: kAccentPurple,
          error: kErrorRed,
          surface: Colors.white,
        ),

        // AppBar Theme
        appBarTheme: const AppBarTheme(
          backgroundColor: kPrimaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
          ),
        ),

        // Scaffold Theme
        scaffoldBackgroundColor: kBackgroundWhite,

        // Card Theme
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.white,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),

        // Input Decoration Theme
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: kPrimaryBlue.withOpacity(0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kPrimaryBlue, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kErrorRed),
          ),
          prefixIconColor: kPrimaryBlue,
          suffixIconColor: kPrimaryBlue,
          labelStyle: TextStyle(color: Colors.grey[600]),
        ),

        // Elevated Button Theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryBlue,
            foregroundColor: Colors.white,
            elevation: 4,
            shadowColor: kPrimaryBlue.withOpacity(0.4),
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),

        // Text Button Theme
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: kPrimaryBlue,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),

        // Bottom Navigation Bar Theme
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: kPrimaryBlue,
          unselectedItemColor: Colors.grey[400],
          selectedIconTheme: const IconThemeData(size: 28),
          unselectedIconTheme: const IconThemeData(size: 24),
          elevation: 8,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.normal,
          ),
        ),

        // Text Theme
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: kPrimaryBlue,
          ),
          displayMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: kPrimaryBlue,
          ),
          titleLarge: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          titleMedium: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),

        // Dialog Theme
        dialogTheme: DialogTheme(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
        ),

        // Snackbar Theme
        snackBarTheme: SnackBarThemeData(
          backgroundColor: kPrimaryBlue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

  // Light Theme
  static final ThemeData customLightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: turquoise,
    scaffoldBackgroundColor: Colors.white,
    colorScheme: const ColorScheme.light(
      primary: turquoise,
      secondary: paleBlue,
      error: kErrorRed,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: turquoise,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: turquoise,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(vertical: 15),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: turquoise,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade100,
      contentPadding: const EdgeInsets.all(16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: turquoise),
      ),
    ),
    dividerTheme: const DividerThemeData(
      thickness: 1,
      color: Colors.black12,
    ),
  );

  // Dark Theme
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: turquoise,
    scaffoldBackgroundColor: Colors.grey[900],
    colorScheme: const ColorScheme.dark(
      primary: turquoise,
      secondary: paleBlue,
      error: kErrorRed,
      surface: Color(0xFF303030),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.grey[850],
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      color: Colors.grey[850],
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: turquoise,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(vertical: 15),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: paleBlue,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[800],
      contentPadding: const EdgeInsets.all(16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: turquoise),
      ),
    ),
    dividerTheme: const DividerThemeData(
      thickness: 1,
      color: Colors.white24,
    ),
  );
}
