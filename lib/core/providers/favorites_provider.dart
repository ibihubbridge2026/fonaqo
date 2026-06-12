import 'package:flutter/foundation.dart';
import 'package:fonaco/core/services/cache_service.dart';
import 'package:fonaco/features/client/repositories/favorites_repository.dart';

/// Provider pour la gestion des agents favoris (API + cache local de secours).
class FavoritesProvider extends ChangeNotifier {
  static final FavoritesProvider _instance = FavoritesProvider._internal();
  factory FavoritesProvider() => _instance;
  FavoritesProvider._internal();

  final CacheService _cacheService = CacheService();
  final FavoritesRepository _repository = FavoritesRepository();
  Set<String> _favoriteAgentIds = {};
  bool _isInitialized = false;
  String? _currentUserId;

  Set<String> get favoriteAgentIds => _favoriteAgentIds;
  bool get isInitialized => _isInitialized;

  Future<void> init(String userId) async {
    if (_isInitialized && _currentUserId == userId) return;

    _currentUserId = userId;
    if (!_cacheService.isInitialized) {
      await _cacheService.init();
    }

    try {
      final ids = await _repository.fetchFavoriteAgentIds();
      _favoriteAgentIds = ids.toSet();
      await _cacheService.saveFavoriteAgents(ids, userId);
    } catch (e) {
      debugPrint('Favoris API indisponible, cache local: $e');
      _favoriteAgentIds = _cacheService.getFavoriteAgents(userId).toSet();
    }

    _isInitialized = true;
    notifyListeners();
  }

  bool isFavorite(String agentId) => _favoriteAgentIds.contains(agentId);

  Future<void> addFavorite(String agentId) async {
    if (_favoriteAgentIds.contains(agentId) || _currentUserId == null) return;

    _favoriteAgentIds.add(agentId);
    notifyListeners();

    try {
      await _repository.addFavorite(agentId);
      await _cacheService.saveFavoriteAgents(
        _favoriteAgentIds.toList(),
        _currentUserId!,
      );
    } catch (e) {
      _favoriteAgentIds.remove(agentId);
      notifyListeners();
      debugPrint('Erreur ajout favori: $e');
      rethrow;
    }
  }

  Future<void> removeFavorite(String agentId) async {
    if (!_favoriteAgentIds.contains(agentId) || _currentUserId == null) return;

    _favoriteAgentIds.remove(agentId);
    notifyListeners();

    try {
      await _repository.removeFavorite(agentId);
      await _cacheService.saveFavoriteAgents(
        _favoriteAgentIds.toList(),
        _currentUserId!,
      );
    } catch (e) {
      _favoriteAgentIds.add(agentId);
      notifyListeners();
      debugPrint('Erreur retrait favori: $e');
      rethrow;
    }
  }

  Future<void> toggleFavorite(String agentId) async {
    if (_favoriteAgentIds.contains(agentId)) {
      await removeFavorite(agentId);
    } else {
      await addFavorite(agentId);
    }
  }

  Future<void> reload() async {
    if (_currentUserId == null) return;
    _isInitialized = false;
    await init(_currentUserId!);
  }

  Future<void> clearAll() async {
    if (_currentUserId == null) return;
    final copy = _favoriteAgentIds.toList();
    for (final id in copy) {
      try {
        await removeFavorite(id);
      } catch (_) {}
    }
  }

  Future<void> switchUser(String userId) async {
    _currentUserId = userId;
    _isInitialized = false;
    await init(userId);
  }
}
