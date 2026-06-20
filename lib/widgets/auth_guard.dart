import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/splash_config.dart';
import '../core/providers/auth_provider.dart';
import '../core/routes/app_routes.dart';
import '../core/utils/auth_navigation.dart';
import '../features/onboarding/getting_screen.dart';
import 'package:go_router/go_router.dart';

/// Auth Guard Widget - Gère le flux d'authentification au démarrage
///
/// Logique:
/// - Si isFirstTime: Affiche SplashScreen -> Onboarding
/// - Sinon: Vérifie AuthProvider.checkAuthStatus()
///   - Loading: Reste sur SplashScreen
///   - Unauthenticated: Navigation vers Login
///   - Authenticated: Navigation vers MainShell
class AuthGuard extends StatefulWidget {
  final bool isFirstTime;

  const AuthGuard({
    super.key,
    required this.isFirstTime,
  });

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final authProvider = context.read<AuthProvider>();

    if (widget.isFirstTime) {
      // Premier lancement: afficher le splash puis onboarding
      await Future.delayed(const Duration(milliseconds: 2500));
      await SplashConfig.removeSplash();

      if (mounted) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isFirstTime', false);

        context.replace(AppRoutes.onboarding);
      }
    } else {
      // Lancement normal: vérifier l'auth
      await authProvider.checkAuth();

      if (mounted) {
        await SplashConfig.removeSplash();

        if (authProvider.accountSuspended) {
          context.replace(AppRoutes.accountSuspended);
        } else if (authProvider.isAuthenticated) {
          await navigateAfterAuth(context, authProvider);
        } else {
          context.replace(AppRoutes.login);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GettingScreen(
      onAuthChecked: () {}, // Handled internally
    );
  }
}
