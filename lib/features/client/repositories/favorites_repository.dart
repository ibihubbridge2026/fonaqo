import 'package:fonaco/core/api/base_client.dart';

/// Synchronisation des agents favoris avec le backend.
class FavoritesRepository {
  final BaseClient _api;

  FavoritesRepository({BaseClient? api}) : _api = api ?? BaseClient();

  Future<List<String>> fetchFavoriteAgentIds() async {
    final response = await _api.get('accounts/favorites/');
    if (response.statusCode != 200) {
      throw Exception('Erreur HTTP ${response.statusCode}');
    }
    final body = response.data;
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is List) {
        return data.map((e) => e.toString()).toList();
      }
    }
    return [];
  }

  Future<void> addFavorite(String agentId) async {
    final response = await _api.post('accounts/favorites/$agentId/');
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Erreur HTTP ${response.statusCode}');
    }
  }

  Future<void> removeFavorite(String agentId) async {
    final response = await _api.delete('accounts/favorites/$agentId/');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Erreur HTTP ${response.statusCode}');
    }
  }
}
