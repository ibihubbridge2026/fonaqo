/// Configuration centralisée de l'API.
/// Modifier cette valeur pour pointer vers un autre serveur (prod, staging, local).
class ApiConfig {
  /// Version API (`v1` par défaut ; `v2` disponible côté backend).
  static const String apiVersion = String.fromEnvironment(
    'API_VERSION',
    defaultValue: 'v1',
  );

  /// URL de base du serveur (sans /api/vX/).
  static const String serverUrl = String.fromEnvironment(
    'SERVER_URL',
    defaultValue: 'http://192.168.1.73:8000',    
  );

  /// URL de base de l'API backend.
  static String get baseUrl {
    final fromEnv = const String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    final normalized = serverUrl.endsWith('/')
        ? serverUrl.substring(0, serverUrl.length - 1)
        : serverUrl;
    return '$normalized/api/$apiVersion/';
  }

  /// Healthcheck (hors préfixe versionné).
  static String get healthUrl {
    final normalized = serverUrl.endsWith('/')
        ? serverUrl.substring(0, serverUrl.length - 1)
        : serverUrl;
    return '$normalized/health/';
  }

  /// Hôte et port pour les WebSockets.
  static String get wsHost {
    final u = Uri.parse(serverUrl);
    if (u.hasPort) return '${u.host}:${u.port}';
    return u.host;
  }

  /// Alias rétrocompatible (utilisé par GPS / timeline WebSockets).
  static String get apiHostAndPort => wsHost;

  /// Schéma WebSocket (`ws` ou `wss` selon SERVER_URL).
  static String get wsScheme {
    final scheme = Uri.parse(serverUrl).scheme;
    return scheme == 'https' ? 'wss' : 'ws';
  }

  /// URL WebSocket complète (sans chemin).
  static String get wsBaseUrl => '$wsScheme://$wsHost';

  /// Construit une URL WebSocket absolue.
  static String wsUrl(String path, {Map<String, String>? query}) {
    final normalized = path.startsWith('/') ? path : '/$path';
    final uri = Uri(
      scheme: wsScheme,
      host: Uri.parse(serverUrl).host,
      port: Uri.parse(serverUrl).hasPort ? Uri.parse(serverUrl).port : null,
      path: normalized,
      queryParameters: query?.isNotEmpty == true ? query : null,
    );
    return uri.toString();
  }
}
