import 'package:flutter/material.dart';

/// Palette de couleurs FONACO — accès statique uniquement.
class AppColors {
  AppColors._();

  // ============================================================
  // Couleurs principales
  // ============================================================
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color secondary = Color(0xFF10B981);
  static const Color accent = Color(0xFFF59E0B);

  // Fond
  static const Color background = Color(0xFFF9FAFB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Texte
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);

  // Statuts
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Bordures
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF3F4F6);

  // Niveaux de gris
  static const Color grey50 = Color(0xFFF9FAFB);
  static const Color grey100 = Color(0xFFF3F4F6);
  static const Color grey200 = Color(0xFFE5E7EB);
  static const Color grey300 = Color(0xFFD1D5DB);
  static const Color grey400 = Color(0xFF9CA3AF);
  static const Color grey500 = Color(0xFF6B7280);
  static const Color grey600 = Color(0xFF4B5563);
  static const Color grey700 = Color(0xFF374151);
  static const Color grey800 = Color(0xFF1F2937);
  static const Color grey900 = Color(0xFF111827);

  // Variantes par rôle
  static const Color agentPrimary = Color(0xFF6366F1);
  static const Color agentSecondary = Color(0xFF10B981);
  static const Color agentAccent = Color(0xFFF59E0B);
  static const Color clientPrimary = Color(0xFF10B981);
  static const Color clientSecondary = Color(0xFF6366F1);
  static const Color clientAccent = Color(0xFFF59E0B);

  // États
  static const Color available = Color(0xFF10B981);
  static const Color busy = Color(0xFFF59E0B);
  static const Color offline = Color(0xFF6B7280);
  static const Color inProgress = Color(0xFF3B82F6);
  static const Color completed = Color(0xFF10B981);
  static const Color cancelled = Color(0xFFEF4444);

  // Badges & ombres
  static const Color badgeBackground = Color(0xFFEFF6FF);
  static const Color badgeText = Color(0xFF1E40AF);
  static const Color shadow = Color(0x1A000000);
  static const Color shadowLight = Color(0x0D000000);

  // Aliases Material 3 (statiques) — utiles pour la cohérence visuelle
  static const Color onPrimary = Colors.white;
  static const Color onSecondary = Colors.white;
  static const Color onError = Colors.white;
  static const Color onSurface = textPrimary;
  static const Color onSurfaceVariant = textSecondary;
  static const Color outline = border;
  static const Color outlineVariant = borderLight;
  static const Color surfaceContainer = cardBackground;
  static const Color surfaceContainerLow = grey50;
  static const Color surfaceContainerLowest = surface;
  static const Color surfaceContainerHigh = grey100;
  static const Color surfaceContainerHighest = grey200;
  static const Color onPrimaryFixed = Colors.white;
  static const Color onPrimaryContainer = primaryDark;
  static const Color primaryContainer = Color(0xFFEEF2FF);
  static const Color secondaryContainer = Color(0xFFD1FAE5);
  static const Color errorContainer = Color(0xFFFEE2E2);

  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
