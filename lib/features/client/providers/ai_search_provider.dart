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
      // Endpoint : POST /api/v1/ai/search/
      // Body: { "query": "...", "type": "agent" }
      final response = await _apiService.post(
        '/ai/search/',
        data: {'query': query, 'type': 'agent'},
      );

      if (response is Map<String, dynamic>) {
        // Gérer la réponse du backend
        if (response['status'] == 'success') {
          final responseData = response['response'];
          _analysisResult = responseData['suggestion'] ?? 'Analyse terminée.';

          // Extraire les agents des résultats
          final results = responseData['results'] as List<dynamic>? ?? [];
          _suggestedAgents = results.map((json) {
            return AgentModel(
              id: json['id'].toString(),
              name: json['fullName'],
              avatarUrl: json['avatarUrl'] ?? '',
              rating: (json['rating'] as num).toDouble(),
              specialty: (json['specialties'] as List<dynamic>).join(', '),
              completedMissions: json['completedMissions'] as int,
              estimatedPrice: 'À déterminer',
            );
          }).toList();
        } else {
          throw Exception(response['error'] ?? 'Erreur inconnue');
        }
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
    _analysisResult =
        "Je cherche un agent disponible pour une démarche bancaire.";
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
