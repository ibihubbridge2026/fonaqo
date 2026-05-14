/// Configuration centralisée de l'API.
/// Modifier cette valeur pour pointer vers un autre serveur (prod, staging, local).
class ApiConfig {
  /// URL de base de l'API backend.
  /// - Émulateur Android : http://10.0.2.2:8000/api/v1/
  /// - Device physique (LAN) : http://<IP_LOCALE>:8000/api/v1/
  /// - Production : https://api.fonaqo.com/api/v1/
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.1.73:8000/api/v1/',
  );

  /// Hôte et port extraits pour les WebSockets.
  static String get wsHost {
    final u = Uri.parse(baseUrl);
    if (u.hasPort) return '${u.host}:${u.port}';
    return u.host;
  }

  /// URL WebSocket complète.
  static String get wsBaseUrl => 'ws://$wsHost';
}
