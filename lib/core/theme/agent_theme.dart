import 'package:flutter/material.dart';

/// Thème spécifique pour l'interface Agent
/// Mode Light forcé avec prédominance du Jaune FONACO #FFD400
class AgentTheme {
  // Couleurs principales FONACO
  static const Color primaryYellow = Color(0xFFFFD400);
  static const Color darkYellow = Color(0xFFE5C200);
  static const Color lightYellow = Color(0xFFFFE066);

  // Couleurs de fond (mode Light forcé)
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color surfaceColor = Colors.white;
  static const Color cardColor = Colors.white;

  // Couleurs de texte
  static const Color primaryTextColor = Color(0xFF1A1C1C);
  static const Color secondaryTextColor = Color(0xFF6C757D);
  static const Color hintTextColor = Color(0xFFADB5BD);

  // Couleurs de statut
  static const Color successColor = Color(0xFF28A745);
  static const Color warningColor = Color(0xFFFFC107);
  static const Color errorColor = Color(0xFFDC3545);
  static const Color infoColor = Color(0xFF17A2B8);

  // Couleurs pour l'interface Agent
  static const Color onlineColor = Color(0xFF28A745);
  static const Color offlineColor = Color(0xFF6C757D);
  static const Color balanceColor = Color(0xFF28A745);
  static const Color missionAvailableColor = primaryYellow;

  /// Thème Light complet pour l'interface Agent
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Palette de couleurs
      colorScheme: const ColorScheme.light(
        primary: primaryYellow,
        secondary: darkYellow,
        surface: surfaceColor,
        background: backgroundColor,
        error: errorColor,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: primaryTextColor,
        onBackground: primaryTextColor,
        onError: Colors.white,
      ),

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryYellow,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(
          color: Colors.black,
          size: 24,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        shadowColor: Colors.black.withOpacity(0.1),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryYellow,
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryYellow,
          side: const BorderSide(color: primaryYellow),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryYellow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryYellow,
        foregroundColor: Colors.black,
        elevation: 4,
        shape: CircleBorder(),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryYellow,
        unselectedItemColor: secondaryTextColor,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: hintTextColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: hintTextColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryYellow, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        labelStyle: const TextStyle(color: secondaryTextColor),
        hintStyle: const TextStyle(color: hintTextColor),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: primaryTextColor,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          color: primaryTextColor,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: TextStyle(
          color: primaryTextColor,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        headlineLarge: TextStyle(
          color: primaryTextColor,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: primaryTextColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        headlineSmall: TextStyle(
          color: primaryTextColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(
          color: primaryTextColor,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: TextStyle(
          color: primaryTextColor,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
        titleSmall: TextStyle(
          color: primaryTextColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(
          color: primaryTextColor,
          fontSize: 16,
          fontWeight: FontWeight.normal,
        ),
        bodyMedium: TextStyle(
          color: primaryTextColor,
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
        bodySmall: TextStyle(
          color: secondaryTextColor,
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
        labelLarge: TextStyle(
          color: primaryTextColor,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
        labelMedium: TextStyle(
          color: secondaryTextColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        labelSmall: TextStyle(
          color: hintTextColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: primaryTextColor,
        size: 24,
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: hintTextColor.withOpacity(0.3),
        thickness: 1,
        space: 1,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: surfaceColor,
        selectedColor: lightYellow,
        disabledColor: hintTextColor.withOpacity(0.2),
        labelStyle: const TextStyle(color: primaryTextColor),
        side: BorderSide(color: hintTextColor.withOpacity(0.3)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryYellow,
        linearTrackColor: hintTextColor,
        circularTrackColor: hintTextColor,
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryYellow;
          }
          return hintTextColor;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return lightYellow;
          }
          return hintTextColor.withOpacity(0.3);
        }),
      ),

      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryYellow;
          }
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all(Colors.black),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),

      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryYellow;
          }
          return hintTextColor;
        }),
      ),

      // Slider Theme
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryYellow,
        inactiveTrackColor: hintTextColor.withOpacity(0.3),
        thumbColor: primaryYellow,
        overlayColor: primaryYellow.withOpacity(0.2),
        valueIndicatorColor: primaryTextColor,
        valueIndicatorTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Constantes de style spécifiques à l'Agent
  static const double cardBorderRadius = 12.0;
  static const double buttonBorderRadius = 8.0;
  static const double chipBorderRadius = 16.0;
  static const double defaultPadding = 16.0;
  static const double defaultSpacing = 16.0;
  static const double smallSpacing = 8.0;
  static const double largeSpacing = 24.0;

  /// Styles de texte réutilisables
  static const TextStyle cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: primaryTextColor,
  );

  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 14,
    color: secondaryTextColor,
  );

  static const TextStyle balanceAmount = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: balanceColor,
  );

  static const TextStyle missionTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: primaryTextColor,
  );

  static const TextStyle missionPrice = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: missionAvailableColor,
  );

  static const TextStyle statusOnline = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: onlineColor,
  );

  static const TextStyle statusOffline = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: offlineColor,
  );
}
