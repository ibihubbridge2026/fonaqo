/// Noms des routes nommées de l'application FONACO.
abstract final class AppRoutes {
  /// Splash / séquence d'introduction (GettingScreen).
  static const splash = '/';

  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';

  /// Conteneur principal avec barre inférieure (post-authentification).
  static const mainShell = '/main';

  /// Création d'une mission (pile détail).
  static const createMission = '/missions/create';

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
}
