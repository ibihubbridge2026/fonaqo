import 'package:fonaco/core/api/base_client.dart';

/// Synchronisation des agents favoris avec le backend.
/// Stratégie hybride Hive + API comme demandé.
class FavoritesRepository {
  final BaseClient _api;

  FavoritesRepository({BaseClient? api}) : _api = api ?? BaseClient();

  /// Récupère la liste complète des agents favoris depuis le serveur.
  /// Endpoint: GET /api/v1/accounts/client/favorites/
  Future<List<String>> fetchFavoriteAgentIds() async {
    final response = await _api.get('accounts/client/favorites/');
    if (response.statusCode != 200) {
      throw Exception('Erreur HTTP ${response.statusCode}');
    }
    final body = response.data;
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is List) {
        return data.map((e) => e['id']?.toString() ?? e.toString()).toList();
      }
    }
    return [];
  }

  /// Toggle favori (ajoute si absent, retire si présent).
  /// Endpoint: POST /api/v1/accounts/client/favorites/toggle/
  /// Retourne le nouveau statut booléen (is_favorite).
  Future<bool> toggleFavorite(String agentId) async {
    final response = await _api.post(
      'accounts/client/favorites/toggle/',
      data: {'agent_id': agentId},
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur HTTP ${response.statusCode}');
    }
    final body = response.data;
    if (body is Map<String, dynamic>) {
      return body['is_favorite'] as bool? ?? false;
    }
    return false;
  }

  /// Ajoute un favori (méthode legacy, utilise toggleFavorite à la place).
  Future<void> addFavorite(String agentId) async {
    await toggleFavorite(agentId);
  }

  /// Retire un favori (méthode legacy, utilise toggleFavorite à la place).
  Future<void> removeFavorite(String agentId) async {
    await toggleFavorite(agentId);
  }
}
