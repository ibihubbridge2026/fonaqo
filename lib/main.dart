import 'package:flutter/material.dart';
import 'package:fonaco/core/config/splash_config.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/services/firebase_background_handler.dart';

import 'core/services/feedback_service.dart';
import 'core/services/tutorial_service.dart';
import 'core/services/lottie_animation_service.dart';
import 'core/services/image_compression_service.dart';
import 'core/services/error_monitoring_service.dart';
import 'core/services/cache_service.dart';
import 'core/services/notification_service.dart';

import 'core/providers/auth_provider.dart';
import 'core/providers/wallet_provider.dart';
import 'core/providers/mission_provider.dart';
import 'core/providers/notification_provider.dart';
import 'core/providers/favorites_provider.dart';
import 'core/routes/app_routes.dart';
import 'features/agent/providers/agent_provider.dart';
import 'core/theme/theme_provider.dart';

import 'features/auth/forgot_password_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';

import 'features/onboarding/onboarding_screen.dart';

import 'features/client/screens/client_agent_profile_screen.dart';

import 'widgets/main_wrapper.dart';
import 'widgets/auth_guard.dart';

import 'features/chat/screens/chat_list_screen.dart';
import 'features/chat/screens/chat_detail_screen.dart';
import 'features/auth/complete_profile_screen.dart';
import 'features/client/missions/screens/mission_tracking_screen.dart';
import 'features/agent/presentation/dashboard/screens/agent_dashboard_screen.dart';

import 'features/litiges/litige_screen.dart';

import 'features/client/missions/mission_detail_screen.dart';
import 'features/client/missions/missions_screen.dart';
import 'features/ai/screens/ai_assistant_screen.dart';
import 'features/client/screens/favorite_agents_screen.dart';


import 'features/client/notifications/notifications_screen.dart';
import 'features/client/wallet/client_wallet_screen.dart';

import 'features/client/profile/screens/personal_info_screen.dart';
import 'features/client/profile/screens/security_settings_screen.dart';
import 'features/client/profile/screens/location_settings_screen.dart';
import 'features/client/profile/screens/language_screen.dart';
import 'features/client/profile/screens/help_center_screen.dart';
import 'features/client/profile/screens/notifications_settings_screen.dart';
import 'features/agent/presentation/profile/screens/agent_personal_info_screen.dart';
import 'features/agent/presentation/dashboard/screens/agent_mission_tracking_screen.dart';
import 'features/agent/presentation/kyc/kyc_lock_screen.dart';
import 'features/agent/screens/agent_boost_screen.dart';
import 'features/agent/screens/agent_mission_detail_screen.dart';
import 'package:fonaco/core/models/mission_model.dart';

import 'features/rating/rating_screen.dart';

// Global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  final log = Logger();

  try {
    // Initialisation de Sentry pour le monitoring d'erreurs
    await ErrorMonitoringService().init(
      dsn: 'VOTRE_DSN_SENTRY_ICI', // Remplacer par votre DSN Sentry
    );

    await CacheService().init();
    log.i('✅ Cache offline initialisé');

    // Initialisation des autres services
    TutorialService().init();
    LottieAnimationService().init();
    ImageCompressionService(); // Préchargement du singleton
    log.i('✅ Services Tutoriel, Animations & Compression initialisés');

    await Firebase.initializeApp();

    log.i('✅ Firebase initialisé');

    // Enregistrer le handler background pour Firebase
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await NotificationService().initialize();
    FeedbackService.navigatorKey = navigatorKey;

    log.i('🚀 FONAQO prêt à démarrer');
  } catch (e) {
    log.e('❌ Erreur initialisation: $e');
    await ErrorMonitoringService()
        .captureException(e, message: 'Erreur initialisation main()');
  }

  SplashConfig.initializeSplash(widgetsBinding);

  final prefs = await SharedPreferences.getInstance();

  final isFirstTime = prefs.getBool('isFirstTime') ?? true;

  // Vérification session
  final authProvider = AuthProvider();

  await authProvider.checkAuth();
  if (authProvider.isAuthenticated) {
    final token = authProvider.accessToken;
    if (token != null) {
      await NotificationService().sendTokenToBackend(token);
    }
  }

  final isLoggedIn = authProvider.isAuthenticated;

  log.d(
    '🚀 FONACO | FirstTime: $isFirstTime '
    '| LoggedIn: $isLoggedIn',
  );

  runApp(
    FonacoApp(
      isFirstTime: isFirstTime,
      isLoggedIn: isLoggedIn,
      authProvider: authProvider,
    ),
  );
}

class FonacoApp extends StatelessWidget {
  final bool isFirstTime;
  final bool isLoggedIn;
  final AuthProvider authProvider;

  const FonacoApp({
    super.key,
    required this.isFirstTime,
    required this.isLoggedIn,
    required this.authProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
          value: authProvider,
        ),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider()..loadTheme(),
        ),
        ChangeNotifierProvider(
          create: (_) => WalletProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => MissionProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => AgentProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => FavoritesProvider(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'FONACO',
            navigatorKey: navigatorKey,
            theme: themeProvider.themeData,
            home: AuthGuard(
              isFirstTime: isFirstTime,
            ),
            routes: {
              AppRoutes.login: (context) => const LoginScreen(),
              AppRoutes.register: (context) => const RegisterScreen(),
              AppRoutes.forgotPassword: (context) =>
                  const ForgotPasswordScreen(),
              AppRoutes.onboarding: (context) => const OnboardingScreen(),
              AppRoutes.mainShell: (context) => const MainWrapper(),
              AppRoutes.missionDetail: (context) => const MissionDetailScreen(),
              AppRoutes.favoriteAgents: (context) =>
                  const FavoriteAgentsScreen(),
              AppRoutes.litige: (context) => const LitigeScreen(),
              AppRoutes.aiAssistant: (context) => const AiAssistantScreen(),
              AppRoutes.notifications: (context) => const NotificationsScreen(),
              AppRoutes.wallet: (context) => const ClientWalletScreen(),
              AppRoutes.helpCenter: (context) => const HelpCenterScreen(),
              AppRoutes.profileNotifications: (context) =>
                  const NotificationsSettingsScreen(),
              AppRoutes.profileLanguage: (context) => const LanguageScreen(),
              AppRoutes.personalInfo: (context) => const PersonalInfoScreen(),
              AppRoutes.agentProfilePersonalInfo: (context) =>
                  const AgentPersonalInfoScreen(),
              AppRoutes.agentMissionTracking: (context) {
                final args = ModalRoute.of(context)?.settings.arguments;
                final mapArgs =
                    args is Map<String, dynamic> ? args : <String, dynamic>{};
                final mission = mapArgs['mission'];
                if (mission is MissionModel) {
                  return AgentMissionTrackingScreen(mission: mission);
                }
                return const Scaffold(
                  body: Center(child: Text('Mission introuvable')),
                );
              },
              AppRoutes.securitySettings: (context) =>
                  const SecuritySettingsScreen(),
              AppRoutes.profileLocation: (context) =>
                  const LocationSettingsScreen(),
              AppRoutes.completeProfile: (context) =>
                  const CompleteProfileScreen(),
              AppRoutes.missionTracking: (context) {
                final args = ModalRoute.of(context)?.settings.arguments;
                final mapArgs =
                    args is Map<String, dynamic> ? args : <String, dynamic>{};
                return MissionTrackingScreen(
                  missionId: mapArgs['missionId']?.toString() ?? '',
                );
              },
              AppRoutes.rating: (context) {
                final args = ModalRoute.of(context)?.settings.arguments;
                final mapArgs =
                    args is Map<String, dynamic> ? args : <String, dynamic>{};
                return RatingScreen(
                  missionId: mapArgs['missionId']?.toString(),
                );
              },
              AppRoutes.chat: (context) => const ChatListScreen(),
              AppRoutes.chatList: (context) => const ChatListScreen(),
              AppRoutes.agentMissionsExplorer: (context) =>
                  const AgentDashboardScreen(),
              AppRoutes.agentMissionDetail: (context) {
                final args = ModalRoute.of(context)?.settings.arguments;
                final mapArgs =
                    args is Map<String, dynamic> ? args : <String, dynamic>{};
                final mission = mapArgs['mission'];
                if (mission is MissionModel) {
                  return AgentMissionDetailScreen(mission: mission);
                }
                return const Scaffold(
                  body: Center(child: Text('Mission introuvable')),
                );
              },
              AppRoutes.agentDashboard: (context) =>
                  const AgentDashboardScreen(),
              AppRoutes.agentKycLock: (context) => const KycLockScreen(),
              AppRoutes.agentBoost: (context) => const AgentBoostScreen(),
              AppRoutes.chatDetail: (context) {
                final args = ModalRoute.of(context)?.settings.arguments;

                final mapArgs =
                    args is Map<String, dynamic> ? args : <String, dynamic>{};

                return ChatDetailScreen(
                  chatId: mapArgs['conversationId']?.toString() ??
                      mapArgs['chatId']?.toString() ??
                      '',
                  userName: mapArgs['userName']?.toString() ?? 'Utilisateur',
                  missionId: mapArgs['missionId']?.toString(),
                );
              },
              AppRoutes.missionsAvailable: (context) => MissionsScreen(
                    showCreateMissionListenable: ValueNotifier(false),
                  ),
              AppRoutes.agentProfile: (context) {
                final args = ModalRoute.of(context)?.settings.arguments
                    as Map<String, dynamic>?;

                return ClientAgentProfileScreen.fromRouteArguments(args);
              },
            },
          );
        },
      ),
    );
  }
}
