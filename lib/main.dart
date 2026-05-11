import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/config/splash_config.dart';
import 'core/routes/app_routes.dart';
import 'core/providers/auth_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/chat/chat_screen.dart';
import 'features/events/event_detail_screen.dart';
import 'features/litiges/litige_screen.dart';
import 'features/missions/mission_detail_screen.dart';
import 'features/notifications/notifications_screen.dart';
import 'features/onboarding/getting_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/auth/forgot_password_screen.dart';
import 'features/profile/screens/help_center_screen.dart';
import 'features/profile/screens/language_screen.dart';
import 'features/profile/screens/notifications_settings_screen.dart';
import 'features/profile/screens/personal_info_screen.dart';
import 'features/profile/screens/security_settings_screen.dart';
import 'features/rating/rating_screen.dart';
import 'widgets/main_wrapper.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Initialiser le splash natif
  SplashConfig.initializeSplash(widgetsBinding);

  // Nettoyage manuel en mode debug
  if (const bool.fromEnvironment('dart.vm.product') == false) {
    print('DEBUG MODE: Nettoyage SharedPreferences pour tests');
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Forcer les valeurs de test
    await prefs.setBool('isFirstTime', true);
    await prefs.remove('token');
  }

  // Vérifier l'état de l'utilisateur
  final prefs = await SharedPreferences.getInstance();
  final isFirstTime = prefs.getBool('isFirstTime') ?? true;
  final isLoggedIn = prefs.getString('token') != null;

  print('DEBUG MAIN: isFirstTime = $isFirstTime, isLoggedIn = $isLoggedIn');

  runApp(FonacoApp(isFirstTime: isFirstTime, isLoggedIn: isLoggedIn));
}

class FonacoApp extends StatelessWidget {
  final bool isFirstTime;
  final bool isLoggedIn;

  const FonacoApp({
    super.key,
    required this.isFirstTime,
    required this.isLoggedIn,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          // Sécurisation des accès à l'utilisateur
          final user = authProvider.currentUser;
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'FONACO',
            initialRoute: _getInitialRoute(),
            routes: {
              AppRoutes.splash: (context) => GettingScreen(
                onAuthChecked: () async {
                  // Supprimer le splash natif après vérification
                  await SplashConfig.removeSplash();

                  // Marquer que ce n'est plus la première fois
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('isFirstTime', false);

                  // Attendre que AuthProvider soit initialisé
                  await authProvider.checkAuth();

                  if (authProvider.isAuthenticated) {
                    Navigator.pushReplacementNamed(
                      context,
                      AppRoutes.mainShell,
                    );
                  } else {
                    Navigator.pushReplacementNamed(context, AppRoutes.login);
                  }
                },
              ),
              AppRoutes.login: (context) => const LoginScreen(),
              AppRoutes.register: (context) => const RegisterScreen(),
              AppRoutes.forgotPassword: (context) =>
                  const ForgotPasswordScreen(),
              AppRoutes.onboarding: (context) => const OnboardingScreen(),
              AppRoutes.mainShell: (context) => const MainWrapper(),
              AppRoutes.missionDetail: (context) => const MissionDetailScreen(),
              AppRoutes.eventDetail: (context) => const EventDetailScreen(),
              AppRoutes.litige: (context) => const LitigeScreen(),
              AppRoutes.notifications: (context) => const NotificationsScreen(),
              AppRoutes.helpCenter: (context) => const HelpCenterScreen(),
              AppRoutes.language: (context) => const LanguageScreen(),
              AppRoutes.notificationsSettings: (context) =>
                  const NotificationsSettingsScreen(),
              AppRoutes.personalInfo: (context) => const PersonalInfoScreen(),
              AppRoutes.securitySettings: (context) =>
                  const SecuritySettingsScreen(),
              AppRoutes.rating: (context) => const RatingScreen(),
              AppRoutes.chat: (context) => const ChatScreen(),
            },
          );
        },
      ),
    );
  }

  String _getInitialRoute() {
    // Debug SharedPreferences
    print('DEBUG INIT: isFirstTime = $isFirstTime, isLoggedIn = $isLoggedIn');

    // Forcer le Onboarding si isFirstTime est null
    if (isFirstTime == null || isFirstTime == true) {
      print('DEBUG: Redirection vers splash/onboarding');
      return AppRoutes.splash;
    } else if (isLoggedIn == true) {
      print('DEBUG: Redirection vers main shell');
      return AppRoutes.mainShell;
    } else {
      print('DEBUG: Redirection vers login');
      return AppRoutes.login;
    }
  }
}
