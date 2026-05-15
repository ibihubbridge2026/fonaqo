import 'package:flutter/material.dart';

/// Design System FONACO Agent - Version LIGHT (Défaut)
/// Style: Fintech moderne, clean, professionnel
class AgentDesignSystem {
  // ==================== COULEURS LIGHT MODE ====================
  static const Color background = Color(0xFFF5F5F7); // Gris très clair doux
  static const Color surface = Color(0xFFFFFFFF); // Blanc pur
  static const Color surfaceVariant = Color(0xFFF8F9FA); // Gris très léger pour cartes
  
  static const Color primaryText = Color(0xFF111111); // Noir presque pur
  static const Color secondaryText = Color(0xFF8E8E93); // Gris moyen
  static const Color tertiaryText = Color(0xFFA1A1AA); // Gris clair
  
  static const Color accent = Color(0xFFFFD400); // Jaune FONACO
  static const Color accentDark = Color(0xFFE5BD00); // Jaune foncé pour hover
  
  static const Color success = Color(0xFF32D74B); // Vert succès
  static const Color error = Color(0xFFFF4D4F); // Rouge erreur
  static const Color warning = Color(0xFFFF9500); // Orange warning
  static const Color info = Color(0xFF007AFF); // Bleu info
  
  static const Color border = Color(0xFFE5E5EA); // Bordures subtiles
  static const Color divider = Color(0xFFEAEAEA); // Séparateurs
  
  // ==================== COULEURS DARK MODE ====================
  static const Color darkBackground = Color(0xFF0B0B0B); // Noir profond
  static const Color darkSurface = Color(0xFF1C1C1E); // Gris foncé surface
  static const Color darkSurfaceVariant = Color(0xFF2C2C2E); // Gris foncé variant
  
  static const Color darkPrimaryText = Color(0xFFFFFFFF); // Blanc pur
  static const Color darkSecondaryText = Color(0xFF8E8E93); // Gris moyen
  static const Color darkTertiaryText = Color(0xFF636366); // Gris foncé
  
  static const Color darkBorder = Color(0xFF2C2C2E); // Bordures sombres
  static const Color darkDivider = Color(0xFF3A3A3C); // Séparateurs sombres
  
  // ==================== TYPOGRAPHIE ====================
  static const String fontFamily = 'Poppins';
  
  // Styles de texte réutilisables
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: primaryText,
    letterSpacing: -0.5,
  );
  
  static const TextStyle displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: primaryText,
    letterSpacing: -0.5,
  );
  
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: primaryText,
    letterSpacing: -0.25,
  );
  
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: primaryText,
  );
  
  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: primaryText,
  );
  
  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: primaryText,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: primaryText,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: secondaryText,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: tertiaryText,
  );
  
  static const TextStyle labelLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white, // Toujours blanc sur boutons accent
  );
  
  static const TextStyle labelMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
  
  // ==================== SPACING ====================
  static const double spacingXS = 4;
  static const double spacingSM = 8;
  static const double spacingMD = 12;
  static const double spacingLG = 16;
  static const double spacingXL = 20;
  static const double spacingXXL = 24;
  static const double spacingXXXL = 32;
  
  // ==================== BORDER RADIUS ====================
  static const double radiusSM = 8;
  static const double radiusMD = 12;
  static const double radiusLG = 16;
  static const double radiusXL = 20;
  static const double radiusXXL = 24;
  static const double radiusXXXL = 32;
  
  // ==================== SHADOWS ====================
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity( 0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];
  
  static List<BoxShadow> get cardShadowLight => [
        BoxShadow(
          color: Colors.black.withOpacity( 0.02),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];
  
  static List<BoxShadow> get floatingShadow => [
        BoxShadow(
          color: Colors.black.withOpacity( 0.08),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ];
  
  // ==================== DECORATIONS ====================
  static BoxDecoration cardDecoration({
    Color? color,
    double borderRadius = radiusXL,
    Border? border,
  }) {
    return BoxDecoration(
      color: color ?? surface,
      borderRadius: BorderRadius.circular(borderRadius),
      border: border ?? Border.all(color: border, width: 1),
      boxShadow: cardShadow,
    );
  }
  
  static BoxDecoration cardDecorationDark({
    Color? color,
    double borderRadius = radiusXL,
  }) {
    return BoxDecoration(
      color: color ?? darkSurface,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: darkBorder, width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity( 0.2),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
  
  static BoxDecoration inputDecoration({
    Color? fillColor,
    bool isDark = false,
  }) {
    return BoxDecoration(
      color: fillColor ?? (isDark ? darkSurface : const Color(0xFFF2F2F7)),
      borderRadius: BorderRadius.circular(radiusMD),
    );
  }
  
  // ==================== BUTTON STYLES ====================
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: accent,
    foregroundColor: Colors.black,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusLG),
    ),
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      fontFamily: fontFamily,
    ),
  );
  
  static ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryText,
    foregroundColor: Colors.white,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusLG),
    ),
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      fontFamily: fontFamily,
    ),
  );
  
  static ButtonStyle outlineButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: accent,
    side: const BorderSide(color: accent, width: 2),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusLG),
    ),
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      fontFamily: fontFamily,
    ),
  );
  
  static ButtonStyle textButtonStyle = TextButton.styleFrom(
    foregroundColor: accent,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusMD),
    ),
    textStyle: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      fontFamily: fontFamily,
    ),
  );
  
  // ==================== ANIMATIONS ====================
  static const Duration fastAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);
  
  // ==================== HELPERS ====================
  static Color getTextColor(bool isDark) => isDark ? darkPrimaryText : primaryText;
  static Color getSecondaryTextColor(bool isDark) => isDark ? darkSecondaryText : secondaryText;
  static Color getSurfaceColor(bool isDark) => isDark ? darkSurface : surface;
  static Color getBackgroundColor(bool isDark) => isDark ? darkBackground : background;
  static Color getBorderColor(bool isDark) => isDark ? darkBorder : border;
}
