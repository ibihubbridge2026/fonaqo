import 'package:flutter/material.dart';
import 'package:fonaco/core/config/splash_config.dart';
import 'package:go_router/go_router.dart';
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
import 'core/routes/app_router.dart';
import 'features/agent/providers/agent_provider.dart';
import 'core/theme/theme_provider.dart';
import 'package:fonaco/l10n/app_localizations.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  final log = Logger();

  try {
    await ErrorMonitoringService().init();

    await CacheService().init();
    log.i('✅ Cache offline initialisé');

    TutorialService().init();
    LottieAnimationService().init();
    ImageCompressionService();
    log.i('✅ Services Tutoriel, Animations & Compression initialisés');

    await Firebase.initializeApp();
    log.i('✅ Firebase initialisé');

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

  final authProvider = AuthProvider();
  await authProvider.checkAuth();
  if (authProvider.isAuthenticated) {
    final token = authProvider.accessToken;
    if (token != null) {
      await NotificationService().sendTokenToBackend(token);
    }
  }

  log.d(
    '🚀 FONACO | FirstTime: $isFirstTime '
    '| LoggedIn: ${authProvider.isAuthenticated}',
  );

  final router = createAppRouter(
    navigatorKey: navigatorKey,
    isFirstTime: isFirstTime,
  );

  runApp(
    FonacoApp(
      authProvider: authProvider,
      router: router,
    ),
  );
}

class FonacoApp extends StatelessWidget {
  final AuthProvider authProvider;
  final GoRouter router;

  const FonacoApp({
    super.key,
    required this.authProvider,
    required this.router,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..loadTheme()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => MissionProvider()),
        ChangeNotifierProvider(create: (_) => AgentProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'FONACO',
            theme: themeProvider.themeData,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('fr'),
            routerConfig: router,
          );
        },
      ),
    );
  }
}
