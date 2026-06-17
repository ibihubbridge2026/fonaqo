import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../routes/app_routes.dart';
import '../services/app_bootstrap_service.dart';
import '../services/session_bootstrap_monitor.dart';

/// Redirige vers completeProfile ou le shell après authentification.
Future<void> navigateAfterAuth(BuildContext context, AuthProvider auth) async {
  if (auth.needsPhoneCompletion) {
    if (!context.mounted) return;
    context.replace(AppRoutes.completeProfile);
    return;
  }

  if (!context.mounted) return;

  // Préchargement silencieux sans modal intrusif
  unawaited(AppBootstrapService.preloadSessionData(context));

  if (auth.isAgent && auth.currentUser?.isKycLocked == true) {
    context.replace(AppRoutes.agentKycLock);
    SessionBootstrapMonitor.instance.finish();
    return;
  }

  context.replace(AppRoutes.mainShell);
  SessionBootstrapMonitor.instance.finish();
}
