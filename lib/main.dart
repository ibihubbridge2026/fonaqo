import 'package:flutter/material.dart';
import 'package:fonaco/core/config/splash_config.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart'; // Ajouté

import 'core/providers/auth_provider.dart';
import 'core/providers/wallet_provider.dart';
import 'core/routes/app_routes.dart';
import 'features/auth/forgot_password_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/onboarding/getting_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'widgets/main_wrapper.dart';
import 'features/chat/chat_screen.dart';
import 'features/chat/screens/chat_list_screen.dart';
import 'features/chat/screens/chat_detail_screen.dart';
import 'features/litiges/litige_screen.dart';
import 'features/events/event_detail_screen.dart';
import 'features/missions/mission_detail_screen.dart';
import 'features/missions/screens/mission_tracking_screen.dart';
import 'features/missions/missions_screen.dart';
import 'features/notifications/notifications_screen.dart';
import 'features/profile/screens/personal_info_screen.dart';
import 'features/profile/screens/security_settings_screen.dart';
import 'features/profile/screens/location_settings_screen.dart';
import 'features/profile/screens/language_screen.dart';
import 'features/profile/screens/help_center_screen.dart';
import 'features/rating/rating_screen.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  final log = Logger();

  // 1. Initialisation de Firebase obligatoire
  try {
    await Firebase.initializeApp();
    log.i('✅ Firebase initialisé avec succès');
  } catch (e) {
    log.e('❌ Échec initialisation Firebase : $e');
    // On continue quand même, mais les notifications ne marcheront pas
  }

  SplashConfig.initializeSplash(widgetsBinding);

  final prefs = await SharedPreferences.getInstance();
  final isFirstTime = prefs.getBool('isFirstTime') ?? true;
  final isLoggedIn = prefs.getString('token') != null;

  log.d(
      '🚀 Démarrage FONACO | FirstTime: $isFirstTime | LoggedIn: $isLoggedIn');

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
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'FONACO',
            theme: ThemeData(useMaterial3: true),
            initialRoute: _getInitialRoute(),
            routes: {
              AppRoutes.splash: (context) => GettingScreen(
                    onAuthChecked: () async {
                      await SplashConfig.removeSplash();
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('isFirstTime', false);
                      await authProvider.checkAuth();

                      // AJOUT DE LA VÉRIFICATION DE MONTAGE (MOUNTED)
                      if (!context.mounted) return;

                      if (authProvider.isAuthenticated) {
                        Navigator.pushReplacementNamed(
                            context, AppRoutes.mainShell);
                      } else {
                        Navigator.pushReplacementNamed(
                            context, AppRoutes.login);
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
              AppRoutes.missionTracking: (context) {
                final args = ModalRoute.of(context)?.settings.arguments;
                final id = args is Map ? args['missionId']?.toString() : null;
                if (id == null || id.isEmpty) {
                  return const Scaffold(
                    body: Center(child: Text('Mission introuvable')),
                  );
                }
                return MissionTrackingScreen(missionId: id);
              },
              AppRoutes.eventDetail: (context) => const EventDetailScreen(),
              AppRoutes.litige: (context) => const LitigeScreen(),
              AppRoutes.notifications: (context) => const NotificationsScreen(),
              AppRoutes.helpCenter: (context) => const HelpCenterScreen(),
              AppRoutes.profileLanguage: (context) => const LanguageScreen(),
              AppRoutes.personalInfo: (context) => const PersonalInfoScreen(),
              AppRoutes.securitySettings: (context) =>
                  const SecuritySettingsScreen(),
              AppRoutes.profileLocation: (context) =>
                  const LocationSettingsScreen(),
              AppRoutes.rating: (context) => const RatingScreen(),
              AppRoutes.chat: (context) => const ChatScreen(),
              AppRoutes.chatList: (context) => const ChatListScreen(),
              AppRoutes.chatDetail: (context) => const ChatDetailScreen(
                    chatId: '',
                    userName: '',
                  ),
              AppRoutes.missionsAvailable: (context) => MissionsScreen(
                    showCreateMissionListenable: ValueNotifier(false),
                  ),
            },
          );
        },
      ),
    );
  }

  String _getInitialRoute() {
    if (isFirstTime) return AppRoutes.splash;
    if (isLoggedIn) return AppRoutes.mainShell;
    return AppRoutes.login;
  }
}
