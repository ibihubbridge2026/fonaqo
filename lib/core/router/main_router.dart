import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../../features/agent/screens/agent_main_shell.dart';
import '../../widgets/main_wrapper.dart';

/// Routeur principal qui gère la bascule entre les shells Client et Agent
class MainRouter extends StatelessWidget {
  const MainRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Si l'utilisateur n'est pas authentifié, afficher l'écran de login
        if (!authProvider.isAuthenticated) {
          return const MainWrapper(); // MainWrapper gère déjà la redirection vers login
        }

        // Si l'utilisateur est authentifié, basculer selon le mode
        if (authProvider.isAgentMode) {
          // Mode Agent - afficher l'interface Agent
          return const AgentMainShell();
        } else {
          // Mode Client - afficher l'interface Client
          return const MainWrapper();
        }
      },
    );
  }
}

/// Widget pour basculer entre les modes avec animation
class ModeSwitcher extends StatefulWidget {
  final Widget child;
  const ModeSwitcher({super.key, required this.child});

  @override
  State<ModeSwitcher> createState() => _ModeSwitcherState();
}

class _ModeSwitcherState extends State<ModeSwitcher>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Démarrer l'animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: widget.child,
    );
  }
}
