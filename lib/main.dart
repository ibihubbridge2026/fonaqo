import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fonaco/core/config/splash_config.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'core/services/firebase_background_handler.dart';

import 'core/services/feedback_service.dart';
import 'core/services/cache_service.dart';
import 'core/services/tutorial_service.dart';
import 'core/services/lottie_animation_service.dart';
import 'core/services/image_compression_service.dart';
import 'core/services/error_monitoring_service.dart';
import 'core/services/offline_cache_service.dart';

import 'core/providers/auth_provider.dart';
import 'core/providers/wallet_provider.dart';
import 'core/providers/mission_provider.dart';
import 'core/routes/app_routes.dart';
import 'features/agent/providers/agent_provider.dart';

import 'features/auth/forgot_password_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';

import 'features/onboarding/getting_screen.dart';
import 'features/onboarding/onboarding_screen.dart';

import 'features/client/screens/agent_profile_screen.dart' as agents;

import 'widgets/main_wrapper.dart';

import 'features/chat/chat_screen.dart';
import 'features/chat/screens/chat_list_screen.dart';
import 'features/chat/screens/chat_detail_screen.dart';

import 'features/litiges/litige_screen.dart';
import 'features/events/event_detail_screen.dart';

import 'features/client/missions/mission_detail_screen.dart';
import 'features/client/missions/missions_screen.dart';

import 'features/map/agents_map_screen.dart';

import 'features/client/notifications/notifications_screen.dart';

import 'features/client/profile/screens/personal_info_screen.dart';
import 'features/client/profile/screens/security_settings_screen.dart';
import 'features/client/profile/screens/location_settings_screen.dart';
import 'features/client/profile/screens/language_screen.dart';
import 'features/client/profile/screens/help_center_screen.dart';
import 'features/client/profile/screens/notifications_settings_screen.dart';

import 'features/rating/rating_screen.dart';

// Global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Firebase Messaging Initialization
Future<void> _initializeFirebaseMessaging(Logger log) async {
  final FirebaseMessaging messaging = FirebaseMessaging.instance;

  try {
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    switch (settings.authorizationStatus) {
      case AuthorizationStatus.authorized:
        log.i('✅ Notifications autorisées');
        break;

      case AuthorizationStatus.provisional:
        log.i('⚠️ Notifications provisoires');
        break;

      default:
        log.w('❌ Notifications refusées');
    }

    final token = await messaging.getToken();
    log.i('🔑 FCM Token: $token');

    // Foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final title = message.notification?.title ?? 'Nouvelle notification';

      final body = message.notification?.body ?? '';

      final fullMessage = body.isNotEmpty ? '$title\n$body' : title;

      FeedbackService.showInfoGlobal(fullMessage);

      log.i('📨 Notification foreground: $title');
    });

    // Open app from background
    FirebaseMessaging.onMessageOpenedApp.listen(
      (RemoteMessage message) {
        final messageType = message.data['type'];

        log.i(
          '📱 Notification ouverte: ${message.notification?.title} - Type: $messageType',
        );

        // Navigation directe pour les nouvelles missions
        if (messageType == 'NEW_MISSION') {
          _navigateToMissionFromNotification(message);
        }
      },
    );

    // Open app from terminated
    final initialMessage = await messaging.getInitialMessage();

    if (initialMessage != null) {
      final messageType = initialMessage.data['type'];

      log.i(
        '🚀 App ouverte via notification: '
        '${initialMessage.notification?.title} - Type: $messageType',
      );

      // Navigation directe pour les nouvelles missions
      if (messageType == 'NEW_MISSION') {
        _navigateToMissionFromNotification(initialMessage);
      }
    }
  } catch (e) {
    log.e('❌ Erreur Firebase Messaging: $e');
  }
}

/// Navigation directe vers l'écran des missions depuis une notification
void _navigateToMissionFromNotification(RemoteMessage message) {
  final missionId = message.data['mission_id'];

  print('🧭 Navigation vers mission: $missionId');

  // Navigation vers l'explorateur de missions agent
  if (navigatorKey.currentContext != null) {
    if (missionId != null) {
      // Navigation vers le détail de la mission si ID fourni
      navigatorKey.currentState?.pushNamed(
        '/agent/mission-detail',
        arguments: {'missionId': missionId},
      );
    } else {
      // Navigation vers l'explorateur de missions
      navigatorKey.currentState?.pushNamed('/agent/missions-explorer');
    }
  }
}

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  final log = Logger();

  try {
    // Initialisation de Sentry pour le monitoring d'erreurs
    await ErrorMonitoringService().init(
      dsn: 'VOTRE_DSN_SENTRY_ICI', // Remplacer par votre DSN Sentry
    );

    // Initialisation de Hive pour le cache offline
    await Hive.initFlutter();
    await OfflineCacheService().init();
    log.i('✅ Hive & Cache offline initialisés');

    // Initialisation des autres services
    TutorialService().init();
    LottieAnimationService().init();
    ImageCompressionService(); // Préchargement du singleton
    log.i('✅ Services Tutoriel, Animations & Compression initialisés');

    await Firebase.initializeApp();

    log.i('✅ Firebase initialisé');

    // Enregistrer le handler background pour Firebase
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _initializeFirebaseMessaging(log);

    FeedbackService.navigatorKey = navigatorKey;
    
    log.i('🚀 FONAQO prêt à démarrer');
  } catch (e) {
    log.e('❌ Erreur initialisation: $e');
    await ErrorMonitoringService().captureException(e, message: 'Erreur initialisation main()');
  }

  SplashConfig.initializeSplash(widgetsBinding);

  final prefs = await SharedPreferences.getInstance();

  final isFirstTime = prefs.getBool('isFirstTime') ?? true;

  // Vérification session
  final authProvider = AuthProvider();

  await authProvider.checkAuth();

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
          create: (_) => WalletProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => MissionProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => AgentProvider(),
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'FONACO',
            navigatorKey: navigatorKey,
            theme: ThemeData(
              useMaterial3: true,
            ),
            initialRoute: _getInitialRoute(),
            routes: {
              AppRoutes.splash: (context) => GettingScreen(
                    onAuthChecked: () async {
                      await SplashConfig.removeSplash();

                      final prefs = await SharedPreferences.getInstance();

                      await prefs.setBool(
                        'isFirstTime',
                        false,
                      );

                      await authProvider.checkAuth();

                      if (!context.mounted) return;

                      if (authProvider.isAuthenticated) {
                        Navigator.pushReplacementNamed(
                          context,
                          AppRoutes.mainShell,
                        );
                      } else {
                        Navigator.pushReplacementNamed(
                          context,
                          AppRoutes.login,
                        );
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
              AppRoutes.profileNotifications: (context) =>
                  const NotificationsSettingsScreen(),
              AppRoutes.profileLanguage: (context) => const LanguageScreen(),
              AppRoutes.personalInfo: (context) => const PersonalInfoScreen(),
              AppRoutes.securitySettings: (context) =>
                  const SecuritySettingsScreen(),
              AppRoutes.profileLocation: (context) =>
                  const LocationSettingsScreen(),
              AppRoutes.rating: (context) => const RatingScreen(),
              AppRoutes.chat: (context) => const ChatScreen(),
              AppRoutes.chatList: (context) => const ChatListScreen(),
              AppRoutes.chatDetail: (context) {
                final args = ModalRoute.of(context)?.settings.arguments;

                final mapArgs =
                    args is Map<String, dynamic> ? args : <String, dynamic>{};

                return ChatDetailScreen(
                  chatId: mapArgs['chatId']?.toString() ?? '',
                  userName: mapArgs['userName']?.toString() ?? 'Utilisateur',
                );
              },
              AppRoutes.missionsAvailable: (context) => MissionsScreen(
                    showCreateMissionListenable: ValueNotifier(false),
                  ),
              AppRoutes.agentsMap: (context) => const AgentsMapScreen(),
              '/agent-profile': (context) {
                final args = ModalRoute.of(context)?.settings?.arguments
                    as Map<String, dynamic>?;

                return agents.AgentProfileScreen(
                  agentId: args?['agentId']?.toString() ?? '',
                  agent: args?['agent'],
                );
              },
            },
          );
        },
      ),
    );
  }

  String _getInitialRoute() {
    if (isFirstTime) {
      return AppRoutes.splash;
    }

    if (isLoggedIn) {
      return AppRoutes.mainShell;
    }

    return AppRoutes.login;
  }
}
