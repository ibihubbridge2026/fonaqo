import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../routes/app_routes.dart';
import '../services/app_bootstrap_service.dart';
import '../services/session_bootstrap_monitor.dart';

/// Redirige vers completeProfile ou le shell après préchargement des données.
Future<void> navigateAfterAuth(BuildContext context, AuthProvider auth) async {
  if (auth.needsPhoneCompletion) {
    if (!context.mounted) return;
    context.replace(AppRoutes.completeProfile);
    return;
  }

  if (!context.mounted) return;

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const SessionBootstrapOverlay(),
  );

  try {
    SessionBootstrapMonitor.instance.mark('bootstrap_dialog_shown');
    await AppBootstrapService.preloadSessionData(context);
    SessionBootstrapMonitor.instance.mark('session_data_loaded');
  } finally {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  if (!context.mounted) return;

  if (auth.isAgent && auth.currentUser?.isKycLocked == true) {
    context.replace(AppRoutes.agentKycLock);
    SessionBootstrapMonitor.instance.finish();
    return;
  }

  context.replace(AppRoutes.mainShell);
  SessionBootstrapMonitor.instance.finish();
}
