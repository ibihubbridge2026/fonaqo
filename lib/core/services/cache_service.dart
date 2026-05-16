import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';

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
      debugPrint('✅ CacheService initialisé avec succès');
    } catch (e) {
      debugPrint('❌ Erreur initialisation CacheService: $e');
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
      debugPrint('📦 ${missions.length} missions mises en cache');
    } catch (e) {
      debugPrint('❌ Erreur cache missions: $e');
    }
  }

  /// Récupère les missions depuis le cache
  List<Map<String, dynamic>> getCachedMissions() {
    try {
      final box = Hive.box(_missionsBoxName);
      return List<Map<String, dynamic>>.from(
        box.get('available_missions', defaultValue: []),
      );
    } catch (e) {
      debugPrint('❌ Erreur lecture cache missions: $e');
      return [];
    }
  }

  /// Sauvegarde une mission spécifique
  Future<void> cacheMission(String missionId, Map<String, dynamic> mission) async {
    try {
      final box = Hive.box(_missionsBoxName);
      await box.put('mission_$missionId', mission);
    } catch (e) {
      debugPrint('❌ Erreur cache mission unique: $e');
    }
  }

  /// Récupère une mission spécifique depuis le cache
  Map<String, dynamic>? getCachedMission(String missionId) {
    try {
      final box = Hive.box(_missionsBoxName);
      return box.get('mission_$missionId');
    } catch (e) {
      debugPrint('❌ Erreur lecture cache mission: $e');
      return null;
    }
  }

  // ==================== PROFIL CACHE ====================

  /// Sauvegarde le profil utilisateur
  Future<void> cacheProfile(Map<String, dynamic> profile) async {
    try {
      final box = Hive.box(_profileBoxName);
      await box.put('user_profile', profile);
      debugPrint('👤 Profil mis en cache');
    } catch (e) {
      debugPrint('❌ Erreur cache profil: $e');
    }
  }

  /// Récupère le profil depuis le cache
  Map<String, dynamic>? getCachedProfile() {
    try {
      final box = Hive.box(_profileBoxName);
      return box.get('user_profile');
    } catch (e) {
      debugPrint('❌ Erreur lecture cache profil: $e');
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
      debugPrint('❌ Erreur sauvegarde setting: $e');
    }
  }

  /// Récupère un setting
  T? getSetting<T>(String key, {T? defaultValue}) {
    try {
      final box = Hive.box(_settingsBoxName);
      return box.get(key, defaultValue: defaultValue) as T?;
    } catch (e) {
      debugPrint('❌ Erreur lecture setting: $e');
      return defaultValue;
    }
  }

  // ==================== TOKEN FCM ====================

  /// Sauvegarde le token FCM
  Future<void> saveFcmToken(String token) async {
    try {
      final box = Hive.box(_cacheBoxName);
      await box.put(_fcmTokenKey, token);
      debugPrint('🔔 Token FCM sauvegardé');
    } catch (e) {
      debugPrint('❌ Erreur sauvegarde token FCM: $e');
    }
  }

  /// Récupère le token FCM
  String? getFcmToken() {
    try {
      final box = Hive.box(_cacheBoxName);
      return box.get(_fcmTokenKey);
    } catch (e) {
      debugPrint('❌ Erreur lecture token FCM: $e');
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
      debugPrint('❌ Erreur sauvegarde localisation: $e');
    }
  }

  /// Récupère la dernière position connue
  Map<String, dynamic>? getLastKnownLocation() {
    try {
      final box = Hive.box(_cacheBoxName);
      return box.get(_userLocationKey);
    } catch (e) {
      debugPrint('❌ Erreur lecture localisation: $e');
      return null;
    }
  }

  // ==================== ÉTAT EN LIGNE/HORS LIGNE ====================

  /// Met à jour le statut de connexion
  Future<void> setOnlineStatus(bool isOnline) async {
    try {
      final box = Hive.box(_cacheBoxName);
      await box.put(_isOnlineKey, isOnline);
      debugPrint(isOnline ? '🟢 En ligne' : '🔴 Hors ligne');
    } catch (e) {
      debugPrint('❌ Erreur mise à jour statut online: $e');
    }
  }

  /// Vérifie si l'utilisateur était en ligne lors de la dernière session
  bool? wasOnline() {
    try {
      final box = Hive.box(_cacheBoxName);
      return box.get(_isOnlineKey, defaultValue: true);
    } catch (e) {
      debugPrint('❌ Erreur lecture statut online: $e');
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
      debugPrint('❌ Erreur lecture last sync: $e');
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
      debugPrint('🗑️ Cache entièrement effacé');
    } catch (e) {
      debugPrint('❌ Erreur nettoyage cache: $e');
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
        debugPrint('🧹 Cache expiré nettoyé automatiquement');
      }
    } catch (e) {
      debugPrint('❌ Erreur nettoyage cache expiré: $e');
    }
  }
}
