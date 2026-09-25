import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color primary = Color(0xFF0B6B75);
  static const Color secondary = Color(0xFF2E7D6E);
  static const Color accent = Color(0xFF4B6CB7);
  static const Color surface = Color(0xFFF7F9FB);
  static const Color danger = Color(0xFFB42318);

  // Backwards-compatible aliases used by older screens while they are migrated.
  static const Color kPrimaryBlue = primary;
  static const Color kSecondaryGreen = secondary;
  static const Color kAccentPurple = accent;
  static const Color kHighlightYellow = Color(0xFFF4B740);
  static const Color kBackgroundWhite = surface;
  static const Color kErrorRed = danger;
  static const Color primaryColor = primary;
  static const Color lightBlue = Color(0xFFE6F2F4);
  static const Color darkBlue = Color(0xFF084D55);
  static const Color backgroundColor = surface;
  static const Color cardColor = Colors.white;
  static const Color textColor = Color(0xFF182230);
  static const Color lightGray = Color(0xFFF0F3F6);
  static const Color skyBlue = Color(0xFF8AC6D1);
  static const Color paleBlue = Color(0xFFDFF2F3);
  static const Color turquoise = primary;

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF064E59), Color(0xFF0B6B75), Color(0xFF258F87)],
  );

  static final cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: const Color(0xFFE4E7EC)),
  );

  static final dialogDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(24),
  );

  static final buttonStyle = ElevatedButton.styleFrom(
    backgroundColor: primary,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  );

  static final inputDecoration = InputDecoration(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: primary, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );

  static ThemeData get lightTheme => _theme(Brightness.light);

  static ThemeData get darkTheme => _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      primary: primary,
      secondary: secondary,
      surface: dark ? const Color(0xFF111827) : Colors.white,
      error: danger,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: 'Poppins',
      scaffoldBackgroundColor:
          dark ? const Color(0xFF0B1018) : const Color(0xFFF7F9FB),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor:
            dark ? const Color(0xFF0B1018) : const Color(0xFFF7F9FB),
        foregroundColor: dark ? Colors.white : const Color(0xFF182230),
        centerTitle: false,
      ),
      cardTheme: CardTheme(
        elevation: 0,
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: dark ? const Color(0xFF273142) : const Color(0xFFE4E7EC),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor:
            dark ? const Color(0xFF182230) : const Color(0xFFFFFFFF),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: dark ? const Color(0xFF344054) : const Color(0xFFD0D5DD),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        indicatorColor: primary.withValues(alpha: 0.14),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
