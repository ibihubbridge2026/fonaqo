import 'package:flutter/material.dart';

/// Thème dédié pour les écrans client
class ClientTheme {
  // Couleurs principales
  static const Color primaryColor = Color(0xFFFFD400);
  static const Color backgroundColor = Color(0xFFF5F7FB);
  static const Color surfaceColor = Colors.white;

  // Couleurs de texte
  static const Color primaryTextColor = Colors.black;
  static const Color secondaryTextColor = Colors.grey;
  static const Color hintTextColor = Color(0xFF9E9E9E);

  // Couleurs de bordure
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color focusBorderColor =
      Color(0xFFE0E0E0); // Remplacé par gris au lieu du jaune

  // Couleurs d'état
  static const Color successColor = Colors.green;
  static const Color errorColor = Colors.red;
  static const Color warningColor = Colors.orange;

  // Styles de texte
  static TextStyle get headline1 => const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w900,
        color: primaryTextColor,
      );

  static TextStyle get headline2 => const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: primaryTextColor,
      );

  static TextStyle get headline3 => const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: primaryTextColor,
      );

  static TextStyle get bodyText1 => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: primaryTextColor,
      );

  static TextStyle get bodyText2 => const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: primaryTextColor,
      );

  static TextStyle get caption => const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: secondaryTextColor,
      );

  // Styles de cartes
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      );

  static BoxDecoration get cardDecorationElevated => BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      );

  // Styles de boutons
  static BoxDecoration get primaryButtonDecoration => BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(12),
      );

  static BoxDecoration get secondaryButtonDecoration => BoxDecoration(
        color: surfaceColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(12),
      );

  // Styles de champs de saisie
  static InputDecoration get inputDecoration => InputDecoration(
        hintText: '',
        hintStyle: const TextStyle(color: hintTextColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: focusBorderColor, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor),
        ),
        filled: false,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      );

  // Thème MaterialApp
  static ThemeData get themeData => ThemeData(
        primaryColor: primaryColor,
        backgroundColor: backgroundColor,
        scaffoldBackgroundColor: backgroundColor,
        cardColor: surfaceColor,
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: primaryTextColor,
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: primaryTextColor,
          ),
          headlineSmall: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: primaryTextColor,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: primaryTextColor,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: primaryTextColor,
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: secondaryTextColor,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryTextColor,
            side: const BorderSide(color: borderColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        inputDecorationTheme: InputDecoration(
          hintStyle: const TextStyle(color: hintTextColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: focusBorderColor, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: borderColor),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: errorColor),
          ),
          filled: true,
          fillColor: surfaceColor,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      );
}
