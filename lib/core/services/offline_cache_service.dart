import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Service central pour la gestion du cache offline avec Hive
class OfflineCacheService {
  static final OfflineCacheService _instance = OfflineCacheService._internal();
  factory OfflineCacheService() => _instance;
  OfflineCacheService._internal();

  // Boxes Hive
  static const String missionsBox = 'missions_cache';
  static const String profileBox = 'profile_cache';
  static const String settingsBox = 'settings_cache';
  static const String onboardingBox = 'onboarding_cache';

  /// Initialisation de Hive - À appeler dans main() avant runApp()
  Future<void> init() async {
    await Hive.initFlutter();
    
    // Ouverture des boxes
    await Hive.openBox(missionsBox);
    await Hive.openBox(profileBox);
    await Hive.openBox(settingsBox);
    await Hive.openBox(onboardingBox);
    
    debugPrint('✅ Hive initialisé - Mode offline prêt');
  }

  /// Sauvegarde des missions en cache
  Future<void> cacheMissions(List<dynamic> missions) async {
    try {
      final box = Hive.box(missionsBox);
      await box.put('missions', missions);
      await box.put('last_update', DateTime.now().toIso8601String());
      debugPrint('📦 ${missions.length} missions mises en cache');
    } catch (e) {
      debugPrint('❌ Erreur cache missions: $e');
      await Sentry.captureException(e);
    }
  }

  /// Récupération des missions depuis le cache
  List<dynamic>? getCachedMissions() {
    try {
      final box = Hive.box(missionsBox);
      return box.get('missions', defaultValue: []);
    } catch (e) {
      debugPrint('❌ Erreur lecture cache missions: $e');
      return null;
    }
  }

  /// Vérifie si le cache est récent (< 5 minutes)
  bool isCacheValid({int maxAgeMinutes = 5}) {
    try {
      final box = Hive.box(missionsBox);
      final lastUpdateStr = box.get('last_update') as String?;
      if (lastUpdateStr == null) return false;
      
      final lastUpdate = DateTime.parse(lastUpdateStr);
      final age = DateTime.now().difference(lastUpdate);
      return age.inMinutes < maxAgeMinutes;
    } catch (e) {
      return false;
    }
  }

  /// Sauvegarde du profil utilisateur
  Future<void> cacheProfile(Map<String, dynamic> profile) async {
    try {
      await Hive.box(profileBox).put('profile', profile);
      debugPrint('👤 Profil mis en cache');
    } catch (e) {
      await Sentry.captureException(e);
    }
  }

  /// Récupération du profil en cache
  Map<String, dynamic>? getCachedProfile() {
    try {
      return Hive.box(profileBox).get('profile');
    } catch (e) {
      return null;
    }
  }

  /// Gestion de l'onboarding (déjà vu ou non)
  Future<void> setOnboardingComplete(bool isComplete) async {
    await Hive.box(onboardingBox).put('onboarding_complete', isComplete);
  }

  bool isOnboardingComplete() {
    return Hive.box(onboardingBox).get('onboarding_complete', defaultValue: false);
  }

  /// Nettoyage du cache
  Future<void> clearCache() async {
    await Hive.box(missionsBox).clear();
    await Hive.box(profileBox).clear();
    debugPrint('🗑️ Cache nettoyé');
  }
}
