import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  // Couleurs Light Mode (Défaut - Style Fintech Clean)
  static const Color lightBackground = Color(0xFFF5F5F7); // Gris très clair doux
  static const Color lightSurface = Color(0xFFFFFFFF); // Blanc pur
  static const Color lightPrimary = Color(0xFF000000); // Noir pour textes principaux
  static const Color lightSecondary = Color(0xFF8E8E93); // Gris pour textes secondaires
  static const Color lightAccent = Color(0xFFFFD400); // Jaune FONACO
  static const Color lightSuccess = Color(0xFF32D74B); // Vert
  static const Color lightError = Color(0xFFFF4D4F); // Rouge
  static const Color lightCardBorder = Color(0xFFE5E5EA);

  // Couleurs Dark Mode (Style Premium Night)
  static const Color darkBackground = Color(0xFF0B0B0B); // Noir profond
  static const Color darkSurface = Color(0xFF1C1C1E); // Gris foncé surface
  static const Color darkPrimary = Color(0xFFFFFFFF); // Blanc pour textes
  static const Color darkSecondary = Color(0xFF8E8E93); // Gris
  static const Color darkAccent = Color(0xFFFFD400); // Jaune (identique)
  static const Color darkSuccess = Color(0xFF32D74B);
  static const Color darkError = Color(0xFFFF4D4F);
  static const Color darkCardBorder = Color(0xFF2C2C2E);

  Color get backgroundColor => _isDarkMode ? darkBackground : lightBackground;
  Color get surfaceColor => _isDarkMode ? darkSurface : lightSurface;
  Color get primaryTextColor => _isDarkMode ? darkPrimary : lightPrimary;
  Color get secondaryTextColor => _isDarkMode ? darkSecondary : lightSecondary;
  Color get accentColor => _isDarkMode ? darkAccent : lightAccent;
  Color get successColor => _isDarkMode ? darkSuccess : lightSuccess;
  Color get errorColor => _isDarkMode ? darkError : lightError;
  Color get cardBorderColor => _isDarkMode ? darkCardBorder : lightCardBorder;

  ThemeData get themeData {
    return ThemeData(
      brightness: _isDarkMode ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: backgroundColor,
      primaryColor: accentColor,
      fontFamily: 'Poppins', // Assure-toi d'avoir cette police dans pubspec.yaml
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: primaryTextColor,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: primaryTextColor,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: primaryTextColor,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: secondaryTextColor,
        ),
        labelLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white, // Toujours blanc sur boutons accent
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryTextColor),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: primaryTextColor,
        ),
      ),
      cardTheme: CardTheme(
        color: surfaceColor,
        elevation: _isDarkMode ? 0 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: cardBorderColor,
            width: 1,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _isDarkMode ? darkSurface : const Color(0xFFF2F2F7),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
          borderSide: const BorderSide(color: Color(0xFFFFD400), width: 2),
        ),
      ),
    );
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    notifyListeners();
  }
}
