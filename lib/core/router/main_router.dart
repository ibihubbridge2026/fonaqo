import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../../widgets/main_wrapper.dart';

/// Routeur principal - Interface Client uniquement
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

        // Interface Client uniquement
        return const MainWrapper();
      },
    );
  }
}
