/// Noms des routes nommées de l'application FONACO.
abstract final class AppRoutes {
  /// Splash / séquence d'introduction (GettingScreen).
  static const splash = '/';

  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const referralJoin = '/join/:code';
  static const forgotPassword = '/forgot-password';
  static const completeProfile = '/complete-profile';

  /// Conteneur principal avec barre inférieure (post-authentification).
  static const mainShell = '/main';

  /// Conteneur principal pour l'interface Agent (post-authentification).
  static const agentMainShell = '/agent';

  /// Sous-écrans profil (pile détail).
  static const profilePersonalInfo = '/profile/personal-info';
  static const profileNotifications = '/profile/notifications';
  static const profileSecurity = '/profile/security';
  static const profileLocation = '/profile/location';
  static const profileLanguage = '/profile/language';
  static const profileHelp = '/profile/help';

  /// Messagerie (route empilée).
  static const String chat = '/chat';
  static const String chatList = '/chat-list';
  static const String chatDetail = '/chat-detail';

  /// Mission detail (route empilée).
  static const String missionDetail = '/mission-detail';

  /// Suivi GPS live (mission).
  static const String missionTracking = '/mission-tracking';

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
  static const String helpCenter = '/profile/help';

  /// Carte des agents
  static const String agentsMap = '/agents-map';

  /// Paramètres de notifications
  static const String notificationsSettings = '/notifications-settings';

  /// Informations personnelles
  static const String personalInfo = '/profile/personal-info';

  /// Paramètres de sécurité
  static const String securitySettings = '/profile/security';

  static const String language = '/profile/language';

  /// Agents favoris
  static const String favoriteAgents = '/favorite-agents';

  /// Portefeuille client
  static const String wallet = '/wallet';

  /// Assistant IA Moki
  static const String aiAssistant = '/ai-assistant';

  /// Deep links agent (notifications FCM)
  static const String agentMissionDetail = '/agent/mission-detail';
  static const String agentMissionsExplorer = '/agent/missions-explorer';
  static const String agentProfile = '/agent-profile';

  /// Profil agent (sous-écrans).
  static const String agentProfilePersonalInfo = '/agent/profile/personal-info';

  /// Dashboard et suivi mission agent.
  static const String agentDashboard = '/agent/dashboard';
  static const String agentMissionTracking = '/agent/mission-tracking';
  static const String agentKycLock = '/agent/kyc-lock';
  static const String agentKycSubmit = '/agent/kyc-submit';
  static const String agentBoost = '/agent/boost';
}
