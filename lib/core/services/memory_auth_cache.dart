import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

/// Cache en mémoire pour les tokens d'authentification
/// Évite les lectures répétées de SecureStorage pendant l'utilisation normale
class MemoryAuthCache {
  static final MemoryAuthCache _instance = MemoryAuthCache._internal();
  factory MemoryAuthCache() => _instance;
  MemoryAuthCache._internal();

  final Logger _logger = Logger();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _tokenKey = 'jwt_access_token';
  static const String _refreshTokenKey = 'jwt_refresh_token';
  static const String _userKey = 'user_data';

  String? _accessToken;
  String? _refreshToken;
  String? _userData;
  Future<void>? _hydrationFuture;

  // Getters
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  String? get userData => _userData;
  bool get isLoaded => _accessToken != null;

  /// Garantit que les tokens sont en mémoire (lecture SecureStorage si besoin).
  Future<void> ensureLoaded() {
    if (_accessToken != null && _accessToken!.isNotEmpty) {
      return Future.value();
    }
    return _hydrationFuture ??= _hydrateFromStorage();
  }

  Future<void> _hydrateFromStorage() async {
    try {
      await loadFromStorage();
    } finally {
      _hydrationFuture = null;
    }
  }

  /// Charge les données depuis SecureStorage vers la mémoire
  /// À appeler au démarrage de l'application
  Future<void> loadFromStorage() async {
    try {
      _accessToken = await _secureStorage.read(key: _tokenKey);
      _refreshToken = await _secureStorage.read(key: _refreshTokenKey);
      _userData = await _secureStorage.read(key: _userKey);

      // Nettoyer le token pour éviter les caractères parasites (#, espaces, etc.)
      if (_accessToken != null) {
        final cleanToken = _accessToken!
            .trim()
            .replaceAll('#', '')
            .replaceAll(RegExp(r'\s'), '');
        if (cleanToken != _accessToken) {
          // Token had parasites, update storage
          await _secureStorage.write(key: _tokenKey, value: cleanToken);
          _logger.d('🧹 Token nettoyé et mis à jour dans SecureStorage');
        }
        _accessToken = cleanToken;
      }

      _logger.d('📦 MemoryAuthCache chargé depuis SecureStorage');
      _logger.d('  Token: ${_accessToken != null ? "Présent" : "ABSENT"}');
      _logger.d('  Refresh: ${_refreshToken != null ? "Présent" : "ABSENT"}');
      _logger.d('  User: ${_userData != null ? "Présent" : "ABSENT"}');
    } catch (e) {
      _logger.e('Erreur chargement MemoryAuthCache: $e');
    }
  }

  /// Sauvegarde les tokens en mémoire et dans SecureStorage
  Future<void> saveTokens(String accessToken, String? refreshToken) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;

    await _secureStorage.write(key: _tokenKey, value: accessToken);
    if (refreshToken != null) {
      await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
    }

    _logger.d('💾 Tokens sauvegardés en mémoire et SecureStorage');
  }

  /// Sauvegarde les données utilisateur en mémoire et dans SecureStorage
  Future<void> saveUserData(String userData) async {
    _userData = userData;
    await _secureStorage.write(key: _userKey, value: userData);
    _logger.d('💾 User data sauvegardé en mémoire et SecureStorage');
  }

  /// Met à jour uniquement l'access token (après refresh)
  Future<void> updateAccessToken(String newAccessToken) async {
    _accessToken = newAccessToken;
    await _secureStorage.write(key: _tokenKey, value: newAccessToken);
    _logger.d('🔄 Access token mis à jour en mémoire et SecureStorage');
  }

  /// Vide le cache en mémoire et SecureStorage
  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
    _userData = null;
    _hydrationFuture = null;

    await _secureStorage.deleteAll();
    _logger.d('🗑️ MemoryAuthCache et SecureStorage vidés');
  }
}
