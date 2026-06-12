import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';

/// Service de gestion du cache offline avec Hive
/// Permet de stocker localement les données pour une consultation hors ligne
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  // Noms des boxes Hive
  static const String _missionsBoxName = 'missions';
  static const String _profileBoxName = 'profile';
  static const String _settingsBoxName = 'settings';
  static const String _cacheBoxName = 'cache';
  static const String _onboardingBoxName = 'onboarding_cache';

  // Clés de cache
  static const String _lastSyncKey = 'last_sync_timestamp';
  static const String _isOnlineKey = 'is_online';
  static const String _fcmTokenKey = 'fcm_token';
  static const String _userLocationKey = 'user_location';

  bool _isInitialized = false;
  final Logger _logger = Logger();

  /// Initialisation de Hive et ouverture des boxes
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      await Hive.initFlutter();

      // Enregistrement des adaptateurs si nécessaire (pour les modèles complexes)
      // Hive.registerAdapter(MissionAdapter());
      // Hive.registerAdapter(UserAdapter());

      // Ouverture des boxes
      await Hive.openBox(_missionsBoxName);
      await Hive.openBox(_profileBoxName);
      await Hive.openBox(_settingsBoxName);
      await Hive.openBox(_cacheBoxName);
      await Hive.openBox(_onboardingBoxName);

      _isInitialized = true;
      _logger.i('✅ CacheService initialisé avec succès');
    } catch (e) {
      _logger.e('❌ Erreur initialisation CacheService: $e');
      rethrow;
    }
  }

  /// Vérifie si le service est initialisé
  bool get isInitialized => _isInitialized;

  // ==================== MISSIONS CACHE ====================

  /// Sauvegarde une liste de missions en cache
  Future<void> cacheMissions(List<Map<String, dynamic>> missions) async {
    try {
      final box = Hive.box(_missionsBoxName);
      await box.put('available_missions', missions);
      await box.put(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
      _logger.i('📦 ${missions.length} missions mises en cache');
    } catch (e) {
      _logger.e('❌ Erreur cache missions: $e');
    }
  }

  /// Récupère les missions depuis le cache
  List<Map<String, dynamic>> getCachedMissions() {
    try {
      if (!_isInitialized) {
        _logger.w('⚠️ CacheService non initialisé, retour de liste vide');
        return [];
      }
      final box = Hive.box(_missionsBoxName);
      final raw = box.get('available_missions', defaultValue: []);
      if (raw is! List) return [];
      return raw
          .map((e) {
            if (e is Map<String, dynamic>) return e;
            if (e is Map) return Map<String, dynamic>.from(e);
            return <String, dynamic>{};
          })
          .where((m) => m.isNotEmpty)
          .toList();
    } catch (e) {
      _logger.e('❌ Erreur lecture cache missions: $e');
      return [];
    }
  }

  /// Sauvegarde une réponse JSON brute (pour dashboard/agents suggestions)
  Future<void> cacheJsonResponse(String key, String jsonString) async {
    try {
      final box = Hive.box(_cacheBoxName);
      await box.put('json_$key', jsonString);
      await box.put(
          'json_${key}_timestamp', DateTime.now().millisecondsSinceEpoch);
      _logger.i('📦 JSON mis en cache: $key');
    } catch (e) {
      _logger.e('❌ Erreur cache JSON ($key): $e');
    }
  }

  /// Récupère une réponse JSON brute depuis le cache
  String? getCachedJsonResponse(String key) {
    try {
      if (!_isInitialized) {
        _logger.w('⚠️ CacheService non initialisé');
        return null;
      }
      final box = Hive.box(_cacheBoxName);
      return box.get('json_$key');
    } catch (e) {
      _logger.e('❌ Erreur lecture cache JSON ($key): $e');
      return null;
    }
  }

  /// Invalide le cache dashboard (missions + agents suggestions).
  Future<void> invalidateDashboardCache() async {
    try {
      if (!_isInitialized) return;
      final box = Hive.box(_cacheBoxName);
      for (final key in ['dashboard_missions', 'dashboard_agents']) {
        await box.delete('json_$key');
        await box.delete('json_${key}_timestamp');
      }
      _logger.i('🧹 Cache dashboard invalidé');
    } catch (e) {
      _logger.e('❌ Erreur invalidation cache dashboard: $e');
    }
  }

  /// Vérifie si le cache JSON est valide (défaut : 2 minutes pour le dashboard).
  bool isJsonCacheValid(String key, {int maxAgeMinutes = 2}) {
    try {
      final box = Hive.box(_cacheBoxName);
      final timestamp = box.get('json_${key}_timestamp');
      if (timestamp == null) return false;

      final now = DateTime.now().millisecondsSinceEpoch;
      final maxAge = maxAgeMinutes * 60 * 1000;
      return (now - timestamp) < maxAge;
    } catch (e) {
      _logger.e('❌ Erreur validation cache JSON ($key): $e');
      return false;
    }
  }

  /// Sauvegarde une mission spécifique
  Future<void> cacheMission(
      String missionId, Map<String, dynamic> mission) async {
    try {
      final box = Hive.box(_missionsBoxName);
      await box.put('mission_$missionId', mission);
    } catch (e) {
      _logger.e('❌ Erreur cache mission unique: $e');
    }
  }

  /// Récupère une mission spécifique depuis le cache
  Map<String, dynamic>? getCachedMission(String missionId) {
    try {
      final box = Hive.box(_missionsBoxName);
      final raw = box.get('mission_$missionId');
      if (raw == null) return null;
      if (raw is Map<String, dynamic>) return raw;
      if (raw is Map) return Map<String, dynamic>.from(raw);
      return null;
    } catch (e) {
      _logger.e('❌ Erreur lecture cache mission: $e');
      return null;
    }
  }

  // ==================== PROFIL CACHE ====================

  /// Sauvegarde le profil utilisateur
  Future<void> cacheProfile(Map<String, dynamic> profile) async {
    try {
      final box = Hive.box(_profileBoxName);
      await box.put('user_profile', profile);
      _logger.i('👤 Profil mis en cache');
    } catch (e) {
      _logger.e('❌ Erreur cache profil: $e');
    }
  }

  /// Récupère le profil depuis le cache
  Map<String, dynamic>? getCachedProfile() {
    try {
      final box = Hive.box(_profileBoxName);
      final raw = box.get('user_profile');
      if (raw == null) return null;
      if (raw is Map<String, dynamic>) return raw;
      if (raw is Map) return Map<String, dynamic>.from(raw);
      return null;
    } catch (e) {
      _logger.e('❌ Erreur lecture cache profil: $e');
      return null;
    }
  }

  // ==================== SETTINGS & PREFERENCES ====================

  /// Sauvegarde un setting
  Future<void> saveSetting(String key, dynamic value) async {
    try {
      final box = Hive.box(_settingsBoxName);
      await box.put(key, value);
    } catch (e) {
      _logger.e('❌ Erreur sauvegarde setting: $e');
    }
  }

  /// Récupère un setting
  T? getSetting<T>(String key, {T? defaultValue}) {
    try {
      final box = Hive.box(_settingsBoxName);
      return box.get(key, defaultValue: defaultValue) as T?;
    } catch (e) {
      _logger.e('❌ Erreur lecture setting: $e');
      return defaultValue;
    }
  }

  // ==================== TOKEN FCM ====================

  /// Sauvegarde le token FCM
  Future<void> saveFcmToken(String token) async {
    try {
      final box = Hive.box(_cacheBoxName);
      await box.put(_fcmTokenKey, token);
      _logger.i('🔔 Token FCM sauvegardé');
    } catch (e) {
      _logger.e('❌ Erreur sauvegarde token FCM: $e');
    }
  }

  /// Récupère le token FCM
  String? getFcmToken() {
    try {
      final box = Hive.box(_cacheBoxName);
      return box.get(_fcmTokenKey);
    } catch (e) {
      _logger.e('❌ Erreur lecture token FCM: $e');
      return null;
    }
  }

  // ==================== LOCALISATION ====================

  /// Sauvegarde la position actuelle de l'utilisateur
  Future<void> saveUserLocation(double latitude, double longitude) async {
    try {
      final box = Hive.box(_cacheBoxName);
      await box.put(_userLocationKey, {
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      _logger.e('❌ Erreur sauvegarde localisation: $e');
    }
  }

  /// Récupère la dernière position connue
  Map<String, dynamic>? getLastKnownLocation() {
    try {
      final box = Hive.box(_cacheBoxName);
      final raw = box.get(_userLocationKey);
      if (raw == null) return null;
      if (raw is Map<String, dynamic>) return raw;
      if (raw is Map) return Map<String, dynamic>.from(raw);
      return null;
    } catch (e) {
      _logger.e('❌ Erreur lecture localisation: $e');
      return null;
    }
  }

  // ==================== ÉTAT EN LIGNE/HORS LIGNE ====================

  /// Met à jour le statut de connexion
  Future<void> setOnlineStatus(bool isOnline) async {
    try {
      final box = Hive.box(_cacheBoxName);
      await box.put(_isOnlineKey, isOnline);
      _logger.i(isOnline ? '🟢 En ligne' : '🔴 Hors ligne');
    } catch (e) {
      _logger.e('❌ Erreur mise à jour statut online: $e');
    }
  }

  /// Vérifie si l'utilisateur était en ligne lors de la dernière session
  bool? wasOnline() {
    try {
      final box = Hive.box(_cacheBoxName);
      return box.get(_isOnlineKey, defaultValue: true);
    } catch (e) {
      _logger.e('❌ Erreur lecture statut online: $e');
      return null;
    }
  }

  // ==================== DERNIÈRE SYNCHRONISATION ====================

  /// Récupère le timestamp de la dernière synchronisation
  DateTime? getLastSyncTime() {
    try {
      final box = Hive.box(_missionsBoxName);
      final timestamp = box.get(_lastSyncKey);
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      return null;
    } catch (e) {
      _logger.e('❌ Erreur lecture last sync: $e');
      return null;
    }
  }

  // ==================== ONBOARDING ====================

  Future<void> setOnboardingComplete(bool isComplete) async {
    final box = Hive.box(_onboardingBoxName);
    await box.put('onboarding_complete', isComplete);
  }

  bool isOnboardingComplete() {
    if (!_isInitialized) return false;
    return Hive.box(_onboardingBoxName)
        .get('onboarding_complete', defaultValue: false) as bool;
  }

  /// Vérifie si le cache missions est récent (< [maxAgeMinutes]).
  bool isCacheValid({int maxAgeMinutes = 5}) {
    final lastSync = getLastSyncTime();
    if (lastSync == null) return false;
    return DateTime.now().difference(lastSync).inMinutes < maxAgeMinutes;
  }

  // ==================== NETTOYAGE ====================

  /// Efface tout le cache
  Future<void> clearAllCache() async {
    try {
      await Hive.box(_missionsBoxName).clear();
      await Hive.box(_profileBoxName).clear();
      await Hive.box(_settingsBoxName).clear();
      await Hive.box(_cacheBoxName).clear();
      _logger.i('🗑️ Cache entièrement effacé');
    } catch (e) {
      _logger.e('❌ Erreur nettoyage cache: $e');
    }
  }

  /// Efface uniquement les missions expirées (plus de 24h)
  Future<void> cleanExpiredCache() async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final twentyFourHours = 24 * 60 * 60 * 1000;
      final lastSync = getLastSyncTime();

      if (lastSync != null &&
          now - lastSync.millisecondsSinceEpoch > twentyFourHours) {
        await clearAllCache();
        _logger.i('🧹 Cache expiré nettoyé automatiquement');
      }
    } catch (e) {
      _logger.e('❌ Erreur nettoyage cache expiré: $e');
    }
  }

  // ==================== FAVORIS AGENTS ====================

  /// Sauvegarde la liste des agents favoris pour un utilisateur spécifique
  Future<void> saveFavoriteAgents(List<String> agentIds, String userId) async {
    try {
      final box = Hive.box(_cacheBoxName);
      final key = 'favorite_agents_$userId';
      await box.put(key, agentIds);
      _logger.i(
          '❤️ ${agentIds.length} agents favoris sauvegardés pour user $userId');
    } catch (e) {
      _logger.e('❌ Erreur sauvegarde favoris: $e');
    }
  }

  /// Récupère la liste des agents favoris pour un utilisateur spécifique
  List<String> getFavoriteAgents(String userId) {
    try {
      if (!_isInitialized) {
        _logger.w('⚠️ CacheService non initialisé');
        return [];
      }
      final box = Hive.box(_cacheBoxName);
      final key = 'favorite_agents_$userId';
      final favorites = box.get(key, defaultValue: <String>[]);
      if (favorites is List) {
        return favorites.map((e) => e.toString()).toList();
      }
      return [];
    } catch (e) {
      _logger.e('❌ Erreur lecture favoris: $e');
      return [];
    }
  }

  /// Ajoute un agent aux favoris pour un utilisateur spécifique
  Future<void> addFavoriteAgent(String agentId, String userId) async {
    try {
      final favorites = getFavoriteAgents(userId);
      if (!favorites.contains(agentId)) {
        favorites.add(agentId);
        await saveFavoriteAgents(favorites, userId);
        _logger.i('❤️ Agent $agentId ajouté aux favoris pour user $userId');
      }
    } catch (e) {
      _logger.e('❌ Erreur ajout favori: $e');
    }
  }

  /// Retire un agent des favoris pour un utilisateur spécifique
  Future<void> removeFavoriteAgent(String agentId, String userId) async {
    try {
      final favorites = getFavoriteAgents(userId);
      favorites.remove(agentId);
      await saveFavoriteAgents(favorites, userId);
      _logger.i('💔 Agent $agentId retiré des favoris pour user $userId');
    } catch (e) {
      _logger.e('❌ Erreur retrait favori: $e');
    }
  }

  /// Vérifie si un agent est dans les favoris pour un utilisateur spécifique
  bool isAgentFavorite(String agentId, String userId) {
    return getFavoriteAgents(userId).contains(agentId);
  }

  /// Bascule le statut de favori d'un agent pour un utilisateur spécifique
  Future<void> toggleFavoriteAgent(String agentId, String userId) async {
    if (isAgentFavorite(agentId, userId)) {
      await removeFavoriteAgent(agentId, userId);
    } else {
      await addFavoriteAgent(agentId, userId);
    }
  }

  // ==================== MISSIONS NOTÉES ====================

  /// Sauvegarde la liste des missions notées
  Future<void> saveRatedMissions(List<String> missionIds) async {
    try {
      final box = Hive.box(_cacheBoxName);
      await box.put('rated_missions', missionIds);
      _logger.i('⭐ ${missionIds.length} missions notées sauvegardées');
    } catch (e) {
      _logger.e('❌ Erreur sauvegarde missions notées: $e');
    }
  }

  /// Récupère la liste des missions notées
  List<String> getRatedMissionIds() {
    try {
      if (!_isInitialized) {
        _logger.w('⚠️ CacheService non initialisé');
        return [];
      }
      final box = Hive.box(_cacheBoxName);
      final rated = box.get('rated_missions', defaultValue: <String>[]);
      if (rated is List) {
        return rated.map((e) => e.toString()).toList();
      }
      return [];
    } catch (e) {
      _logger.e('❌ Erreur lecture missions notées: $e');
      return [];
    }
  }

  /// Ajoute une mission à la liste des missions notées
  Future<void> addRatedMission(String missionId) async {
    try {
      final rated = getRatedMissionIds();
      if (!rated.contains(missionId)) {
        rated.add(missionId);
        await saveRatedMissions(rated);
        _logger.i('⭐ Mission $missionId marquée comme notée');
      }
    } catch (e) {
      _logger.e('❌ Erreur ajout mission notée: $e');
    }
  }

  // ==================== MISSIONS ARCHIVÉES ====================

  String _archivedMissionsKey(String userId) => 'archived_missions_$userId';

  /// IDs des missions archivées localement pour un utilisateur.
  List<String> getArchivedMissionIds(String userId) {
    try {
      if (!_isInitialized || userId.isEmpty) return [];
      final box = Hive.box(_cacheBoxName);
      final raw = box.get(_archivedMissionsKey(userId), defaultValue: <String>[]);
      if (raw is List) return raw.map((e) => e.toString()).toList();
      return [];
    } catch (e) {
      _logger.e('❌ Erreur lecture missions archivées: $e');
      return [];
    }
  }

  Future<bool> _ensureInitialized() async {
    if (_isInitialized) return true;
    try {
      await init();
      return _isInitialized;
    } catch (e) {
      _logger.e('❌ Impossible d\'initialiser le cache: $e');
      return false;
    }
  }

  Future<bool> archiveMission(String userId, String missionId) async {
    try {
      if (userId.isEmpty || missionId.isEmpty) return false;
      if (!await _ensureInitialized()) return false;

      final ids = getArchivedMissionIds(userId);
      if (ids.contains(missionId)) return true;

      ids.add(missionId);
      final box = Hive.box(_cacheBoxName);
      await box.put(_archivedMissionsKey(userId), ids);
      _logger.i('📁 Mission $missionId archivée');
      return true;
    } catch (e) {
      _logger.e('❌ Erreur archivage mission: $e');
      return false;
    }
  }

  Future<bool> unarchiveMission(String userId, String missionId) async {
    try {
      if (userId.isEmpty || missionId.isEmpty) return false;
      if (!await _ensureInitialized()) return false;

      final ids = getArchivedMissionIds(userId)
        ..removeWhere((id) => id == missionId);
      final box = Hive.box(_cacheBoxName);
      await box.put(_archivedMissionsKey(userId), ids);
      _logger.i('📂 Mission $missionId désarchivée');
      return true;
    } catch (e) {
      _logger.e('❌ Erreur désarchivage mission: $e');
      return false;
    }
  }
}
