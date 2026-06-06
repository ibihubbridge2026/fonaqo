import 'package:flutter/foundation.dart';
import 'package:fonaco/core/services/cache_service.dart';

/// Provider pour la gestion des agents favoris
/// Synchronise l'état des favoris entre le Dashboard et l'écran des favoris
class FavoritesProvider extends ChangeNotifier {
  static final FavoritesProvider _instance = FavoritesProvider._internal();
  factory FavoritesProvider() => _instance;
  FavoritesProvider._internal();

  final CacheService _cacheService = CacheService();
  Set<String> _favoriteAgentIds = {};
  bool _isInitialized = false;

  // Getters
  Set<String> get favoriteAgentIds => _favoriteAgentIds;
  bool get isInitialized => _isInitialized;

  /// Initialise le provider en chargeant les favoris depuis le cache
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      if (!_cacheService.isInitialized) {
        await _cacheService.init();
      }

      _favoriteAgentIds = _cacheService.getFavoriteAgents().toSet();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur initialisation FavoritesProvider: $e');
    }
  }

  /// Vérifie si un agent est dans les favoris
  bool isFavorite(String agentId) {
    return _favoriteAgentIds.contains(agentId);
  }

  /// Ajoute un agent aux favoris
  Future<void> addFavorite(String agentId) async {
    if (_favoriteAgentIds.contains(agentId)) return;

    try {
      await _cacheService.addFavoriteAgent(agentId);
      _favoriteAgentIds.add(agentId);
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur ajout favori: $e');
    }
  }

  /// Retire un agent des favoris
  Future<void> removeFavorite(String agentId) async {
    if (!_favoriteAgentIds.contains(agentId)) return;

    try {
      await _cacheService.removeFavoriteAgent(agentId);
      _favoriteAgentIds.remove(agentId);
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur retrait favori: $e');
    }
  }

  /// Bascule le statut de favori d'un agent
  Future<void> toggleFavorite(String agentId) async {
    if (_favoriteAgentIds.contains(agentId)) {
      await removeFavorite(agentId);
    } else {
      await addFavorite(agentId);
    }
  }

  /// Recharge les favoris depuis le cache
  Future<void> reload() async {
    try {
      if (!_cacheService.isInitialized) {
        await _cacheService.init();
      }

      _favoriteAgentIds = _cacheService.getFavoriteAgents().toSet();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur rechargement favoris: $e');
    }
  }

  /// Vide tous les favoris
  Future<void> clearAll() async {
    try {
      await _cacheService.saveFavoriteAgents([]);
      _favoriteAgentIds.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur vidage favoris: $e');
    }
  }
}
