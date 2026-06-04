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
      return List<Map<String, dynamic>>.from(
        box.get('available_missions', defaultValue: []),
      );
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

  /// Vérifie si le cache JSON est valide (moins de 5 minutes)
  bool isJsonCacheValid(String key, {int maxAgeMinutes = 5}) {
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
      return box.get('mission_$missionId');
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
      return box.get('user_profile');
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
      return box.get(_userLocationKey);
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

  /// Sauvegarde la liste des agents favoris
  Future<void> saveFavoriteAgents(List<String> agentIds) async {
    try {
      final box = Hive.box(_cacheBoxName);
      await box.put('favorite_agents', agentIds);
      _logger.i('❤️ ${agentIds.length} agents favoris sauvegardés');
    } catch (e) {
      _logger.e('❌ Erreur sauvegarde favoris: $e');
    }
  }

  /// Récupère la liste des agents favoris
  List<String> getFavoriteAgents() {
    try {
      if (!_isInitialized) {
        _logger.w('⚠️ CacheService non initialisé');
        return [];
      }
      final box = Hive.box(_cacheBoxName);
      final favorites = box.get('favorite_agents', defaultValue: <String>[]);
      if (favorites is List) {
        return favorites.map((e) => e.toString()).toList();
      }
      return [];
    } catch (e) {
      _logger.e('❌ Erreur lecture favoris: $e');
      return [];
    }
  }

  /// Ajoute un agent aux favoris
  Future<void> addFavoriteAgent(String agentId) async {
    try {
      final favorites = getFavoriteAgents();
      if (!favorites.contains(agentId)) {
        favorites.add(agentId);
        await saveFavoriteAgents(favorites);
        _logger.i('❤️ Agent $agentId ajouté aux favoris');
      }
    } catch (e) {
      _logger.e('❌ Erreur ajout favori: $e');
    }
  }

  /// Retire un agent des favoris
  Future<void> removeFavoriteAgent(String agentId) async {
    try {
      final favorites = getFavoriteAgents();
      favorites.remove(agentId);
      await saveFavoriteAgents(favorites);
      _logger.i('💔 Agent $agentId retiré des favoris');
    } catch (e) {
      _logger.e('❌ Erreur retrait favori: $e');
    }
  }

  /// Vérifie si un agent est dans les favoris
  bool isAgentFavorite(String agentId) {
    return getFavoriteAgents().contains(agentId);
  }

  /// Bascule le statut de favori d'un agent
  Future<void> toggleFavoriteAgent(String agentId) async {
    if (isAgentFavorite(agentId)) {
      await removeFavoriteAgent(agentId);
    } else {
      await addFavoriteAgent(agentId);
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
}
