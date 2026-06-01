import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../models/agent_model.dart';
import '../../../core/services/api_service.dart';

/// Provider pour la Recherche Assistée par IA (Côté CLIENT)
class AiSearchProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<AgentModel> _suggestedAgents = [];
  String? _analysisResult;
  bool _isLoading = false;
  String? _error;

  List<AgentModel> get suggestedAgents => _suggestedAgents;
  String? get analysisResult => _analysisResult;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Analyse le texte et trouve des agents
  Future<void> searchAgents(String query) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Endpoint : POST /api/v1/ai/search/
      // Body: { "query": "...", "type": "agent" }
      final response = await _apiService.post(
        '/ai/search/',
        data: {'query': query, 'type': 'agent'},
      );

      if (response is Map<String, dynamic>) {
        final responseData = response['response'] as Map<String, dynamic>?;

        if (responseData != null) {
          _analysisResult = responseData['suggestion'] ?? 'Analyse terminée.';

          final agentsJson = responseData['results'] as List<dynamic>? ?? [];
          _suggestedAgents =
              agentsJson.map((json) => AgentModel.fromJson(json)).toList();
        }
      }
    } catch (e) {
      _error = "Erreur de connexion. Vérifiez votre réseau internet.";
      Logger().e("Erreur AiSearchProvider: $e");
      // Plus de mock - erreur réseau uniquement
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _suggestedAgents = [];
    _analysisResult = null;
    _error = null;
    notifyListeners();
  }
}
