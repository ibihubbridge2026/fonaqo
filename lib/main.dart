import 'package:flutter/material.dart';

import 'features/onboarding/onboarding_screen.dart';
import 'features/onboarding/getting_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/home/requester_dashboard.dart';
import 'features/chat/chat_screen.dart';

void main() {
  runApp(const FonacoApp());
}

class FonacoApp extends StatelessWidget {
  const FonacoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FONACO',

      // 2. UTILISE initialRoute pour définir par quelle page l'app commence
      home: const GettingScreen(),

      routes: {
        // La route '/' correspond maintenant à ton Splash (GettingScreen)
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/dashboard': (context) => const RequesterDashboard(),
        '/chat': (context) => const ChatScreen(), // AJOUTE CETTE LIGNE
      },
    );
  }
}