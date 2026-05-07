import 'package:flutter/material.dart';

import 'core/routes/app_routes.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/chat/chat_screen.dart';
import 'features/onboarding/getting_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'widgets/main_wrapper.dart';

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
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (context) => const GettingScreen(),
        AppRoutes.onboarding: (context) => const OnboardingScreen(),
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.register: (context) => const RegisterScreen(),
        AppRoutes.mainShell: (context) => const MainWrapper(),
        AppRoutes.chat: (context) => const ChatScreen(),
      },
    );
  }
}
