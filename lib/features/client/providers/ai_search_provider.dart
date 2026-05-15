import 'package:flutter/foundation.dart';
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
      // Endpoint : POST /api/ai/search-agents/
      // Body: { "query": "J'ai besoin de..." }
      final response = await _apiService.post(
        '/ai/search-agents/',
        data: {'query': query},
      );

      if (response is Map<String, dynamic>) {
        _analysisResult = response['analysis'] ?? 'Analyse terminée.';
        
        final agentsJson = response['agents'] as List<dynamic>? ?? [];
        _suggestedAgents = agentsJson
            .map((json) => AgentModel.fromJson(json))
            .toList();
      }
    } catch (e) {
      _error = "L'analyse IA a échoué. Veuillez réessayer.";
      print("Erreur AiSearchProvider: $e");
      // Mock pour démo si l'API n'est pas prête
      _simulateMockResponse(query);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Simulation de réponse pour démo (à supprimer en prod)
  void _simulateMockResponse(String query) {
    _analysisResult = "Je cherche un agent disponible pour une démarche bancaire.";
    _suggestedAgents = [
      AgentModel(
        id: '1',
        name: 'Moussa Diop',
        avatarUrl: '',
        rating: 4.9,
        specialty: 'Expert en démarches',
        completedMissions: 124,
        estimatedPrice: '5 000 FCFA',
      ),
      AgentModel(
        id: '2',
        name: 'Awa Ndiaye',
        avatarUrl: '',
        rating: 5.0,
        specialty: 'Banque & Finance',
        completedMissions: 142,
        estimatedPrice: '4 500 FCFA',
        isTopChoice: true,
      ),
    ];
  }

  void clear() {
    _suggestedAgents = [];
    _analysisResult = null;
    _error = null;
    notifyListeners();
  }
}
