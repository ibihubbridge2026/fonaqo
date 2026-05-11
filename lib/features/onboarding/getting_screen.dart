import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/providers/auth_provider.dart';

class GettingScreen extends StatefulWidget {
  final VoidCallback onAuthChecked;

  const GettingScreen({super.key, required this.onAuthChecked});

  @override
  State<GettingScreen> createState() => _GettingScreenState();
}

class _GettingScreenState extends State<GettingScreen> {
  @override
  void initState() {
    super.initState();

    // Pour s'assurer que Flutter a fini de dessiner la première frame
    // et que l'écran jaune soit visible avant de déclencher le chronomètre.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startTimer();
    });
  }

  void _startTimer() async {
    print('DEBUG: GettingScreen timer démarré, attente 2.5 secondes...');

    // Laisse l'écran jaune affiché pendant 2.5 secondes
    Timer(const Duration(milliseconds: 2500), () async {
      if (mounted) {
        print('DEBUG: GettingScreen timer terminé, vérification auth...');

        // Vérifier l'authentification
        final authProvider = context.read<AuthProvider>();
        await authProvider.checkAuth();

        print('DEBUG: Auth vérifiée, appel du callback onAuthChecked');

        // Appeler le callback pour gérer la navigation
        widget.onAuthChecked();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Forcer le jaune FONAQO sur tout l'écran dès le départ
      backgroundColor: const Color(0xFFFFD400),
      body: Stack(
        children: [
          // Contenu principal au centre
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo central noir (Carré noir arrondi + favicon)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Image.asset(
                    'assets/icon/fonaco.png',
                    width: 80,
                    height: 80,
                    color: Colors.white,
                    errorBuilder: (_, _, _) {
                      return const Icon(
                        Icons.bolt,
                        color: Colors.white,
                        size: 72,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                // Titre principal
                const Text(
                  "FONAQO",
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.5,
                    color: Colors.black,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 48),
                // Loader de chargement
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.black,
                    strokeWidth: 2.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
