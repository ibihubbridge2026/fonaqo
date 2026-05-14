import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fonaco/core/config/splash_config.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
<<<<<<< HEAD
import 'package:firebase_messaging/firebase_messaging.dart';

import 'core/services/feedback_service.dart';
=======
>>>>>>> baf250f (mmisse a jour ddu gradle)

import 'core/providers/auth_provider.dart';
import 'core/providers/wallet_provider.dart';
import 'core/providers/mission_provider.dart';
import 'core/routes/app_routes.dart';
import 'features/auth/forgot_password_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/onboarding/getting_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/agents/agents_screen.dart';
import 'features/agents/screens/agent_profile_screen.dart';
import 'widgets/main_wrapper.dart';
import 'features/chat/chat_screen.dart';
import 'features/chat/screens/chat_list_screen.dart';
import 'features/chat/screens/chat_detail_screen.dart';
import 'features/litiges/litige_screen.dart';
import 'features/events/event_detail_screen.dart';
import 'features/missions/mission_detail_screen.dart';
import 'features/missions/missions_screen.dart';
import 'features/map/agents_map_screen.dart';
import 'features/notifications/notifications_screen.dart';
import 'features/profile/screens/personal_info_screen.dart';
import 'features/profile/screens/security_settings_screen.dart';
import 'features/profile/screens/location_settings_screen.dart';
import 'features/profile/screens/language_screen.dart';
import 'features/profile/screens/help_center_screen.dart';
import 'features/profile/screens/notifications_settings_screen.dart';
import 'features/rating/rating_screen.dart';

// GlobalKey pour accéder au contexte depuis n'importe où
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Initialise Firebase Cloud Messaging et configure les listeners
Future<void> _initializeFirebaseMessaging(Logger log) async {
  final FirebaseMessaging messaging = FirebaseMessaging.instance;

  try {
    // Demander la permission pour les notifications (iOS)
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      log.i('✅ Permission notifications accordée');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      log.i('⚠️ Permission notifications provisoire');
    } else {
      log.i('❌ Permission notifications refusée');
    }

    // Obtenir le token FCM
    String? token = await messaging.getToken();
    log.i('🔑 FCM Token: $token');

    // Listener pour les messages quand l'app est au premier plan
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log.i(
          '📨 Notification reçue en premier plan: ${message.notification?.title}');

      // Afficher un toast élégant avec FeedbackService global
      final title = message.notification?.title ?? 'Nouvelle notification';
      final body = message.notification?.body ?? '';
      final fullMessage = body.isNotEmpty ? '$title\n$body' : title;

      FeedbackService.showInfoGlobal(fullMessage);

      // Log pour debug
      print('🔔 Notification foreground: $title');
    });

    // Listener pour les messages quand l'app est en arrière-plan mais ouverte
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log.i('📱 Notification cliquée: ${message.notification?.title}');
      // TODO: Naviguer vers l'écran approprié selon le message
    });

    // Gérer les messages quand l'app est complètement fermée
    RemoteMessage? initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      log.i(
          '🚀 App ouverte depuis notification: ${initialMessage.notification?.title}');
      // TODO: Naviguer vers l'écran approprié
    }
  } catch (e) {
    log.e('❌ Erreur initialisation FCM: $e');
  }
}

/// Affiche un message de debug pour les notifications (à remplacer par de vraies notifications)
void _showNotificationDebug(RemoteMessage message, Logger log) {
  // Pour l'instant, on log juste. En production, utiliser flutter_local_notifications
  log.d('🔔 Notification Debug - Titre: ${message.notification?.title}');
  log.d('🔔 Notification Debug - Corps: ${message.notification?.body}');
  log.d('🔔 Notification Debug - Données: ${message.data}');
}

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  final log = Logger();

  // 1. Initialisation de Firebase obligatoire
  try {
    await Firebase.initializeApp();
    log.i('✅ Firebase initialisé avec succès');

    // 2. Initialisation de Firebase Cloud Messaging
    await _initializeFirebaseMessaging(log);

    // 3. Initialiser le navigatorKey dans FeedbackService
    FeedbackService.navigatorKey = navigatorKey;
  } catch (e) {
    log.e('❌ Échec initialisation Firebase : $e');
    // On continue quand même, mais les notifications ne marcheront pas
  }

  SplashConfig.initializeSplash(widgetsBinding);

  final prefs = await SharedPreferences.getInstance();
  final isFirstTime = prefs.getBool('isFirstTime') ?? true;
<<<<<<< HEAD
=======
  const secureStorage = FlutterSecureStorage();
  final token = await secureStorage.read(key: 'jwt_token');
  final isLoggedIn = token != null;
>>>>>>> baf250f (mmisse a jour ddu gradle)

  log.d('🚀 Démarrage FONACO | FirstTime: $isFirstTime');

  // Créer AuthProvider pour vérifier la session avec FlutterSecureStorage
  final authProvider = AuthProvider();
  await authProvider.checkAuth(); // Attendre la vérification de la session

  final isLoggedIn = authProvider.isAuthenticated;
  log.d('🔐 Session vérifiée | LoggedIn: $isLoggedIn');

  runApp(FonacoApp(
      isFirstTime: isFirstTime,
      isLoggedIn: isLoggedIn,
      authProvider: authProvider));
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
            value: authProvider), // Use existing instance
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(
            create: (_) => MissionProvider()), // Add MissionProvider
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'FONACO',
            navigatorKey:
                navigatorKey, // GlobalKey pour accès global au contexte
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
                final chatId =
                    args is Map ? args['chatId']?.toString() ?? '' : '';
                final userName =
                    args is Map ? args['userName']?.toString() ?? '' : '';
                return ChatDetailScreen(
                  chatId: chatId,
                  userName: userName,
                );
              },
              AppRoutes.missionsAvailable: (context) => MissionsScreen(
                    showCreateMissionListenable: ValueNotifier(false),
                  ),
<<<<<<< HEAD
              '/agent-profile': (context) {
                final args = ModalRoute.of(context)?.settings.arguments
                    as Map<String, dynamic>?;
                return AgentProfileScreen(
                  agentId: args?['agentId'] ?? '',
                  agent: args?['agent'],
                );
              },
=======
              AppRoutes.agentsMap: (context) => const AgentsMapScreen(),
>>>>>>> baf250f (mmisse a jour ddu gradle)
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
