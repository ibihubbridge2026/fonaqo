/// Noms des routes nommées de l'application FONACO.
abstract final class AppRoutes {
  /// Splash / séquence d'introduction (GettingScreen).
  static const splash = '/';

  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';

  /// Conteneur principal avec barre inférieure (post-authentification).
  static const mainShell = '/main';

  /// Sous-écrans profil (pile détail).
  static const profilePersonalInfo = '/profile/personal-info';
  static const profileNotifications = '/profile/notifications';
  static const profileSecurity = '/profile/security';
  static const profileLanguage = '/profile/language';
  static const profileHelp = '/profile/help';

  /// Messagerie (route empilée).
  static const chat = '/chat';

  /// Mission detail (route empilée).
  static const String missionDetail = '/mission-detail';

  /// Détail événement (route empilée).
  static const String eventDetail = '/event-detail';

  /// Ouvrir un litige (route empilée).
  static const String litige = '/litige';

  /// Notifications (liste).
  static const String notifications = '/notifications';

  /// Notation d’un agent (fin mission).
  static const String rating = '/rating';

  /// Missions disponibles pour les agents.
  static const String missionsAvailable = '/missions-available';

  /// Centre d'aide
  static const String helpCenter = '/help-center';

  /// Paramètres de notifications
  static const String notificationsSettings = '/notifications-settings';

  /// Informations personnelles
  static const String personalInfo = '/personal-info';

  /// Paramètres de sécurité
  static const String securitySettings = '/security-settings';

  static const String language = '/language';
}
