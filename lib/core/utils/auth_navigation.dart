import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';
import '../routes/app_routes.dart';
import '../services/app_bootstrap_service.dart';

/// Redirige vers completeProfile ou le shell après préchargement des données.
Future<void> navigateAfterAuth(BuildContext context, AuthProvider auth) async {
  if (auth.needsPhoneCompletion) {
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.completeProfile);
    return;
  }

  // Préchargement en arrière-plan sans bloquer la navigation.
  AppBootstrapService.preloadSessionData(context);

  if (!context.mounted) return;

  if (auth.isAgent && auth.currentUser?.isKycLocked == true) {
    Navigator.pushReplacementNamed(context, AppRoutes.agentKycLock);
    return;
  }

  Navigator.pushReplacementNamed(context, AppRoutes.mainShell);
}
