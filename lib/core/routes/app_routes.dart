/// Noms des routes nommées de l'application FONACO.
abstract final class AppRoutes {
  /// Splash / séquence d'introduction (GettingScreen).
  static const splash = '/';

  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';

  /// Conteneur principal avec barre inférieure (post-authentification).
  static const mainShell = '/main';

  /// Messagerie (route empilée).
  static const chat = '/chat';
}
