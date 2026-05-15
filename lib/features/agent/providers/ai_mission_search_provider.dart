import 'package:flutter/foundation.dart';
import '../models/mission_model.dart';
import '../../../../core/services/api_service.dart';

/// Provider pour la Recherche Assistée par IA (Côté AGENT)
class AiMissionSearchProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<MissionModel> _suggestedMissions = [];
  String? _analysisResult;
  bool _isLoading = false;
  String? _error;

  List<MissionModel> get suggestedMissions => _suggestedMissions;
  String? get analysisResult => _analysisResult;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Analyse le texte et trouve des missions
  Future<void> searchMissions(String query) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Endpoint : POST /api/ai/search-missions/
      // Body: { "query": "Je veux une mission..." }
      final response = await _apiService.post(
        '/ai/search-missions/',
        data: {'query': query},
      );

      if (response is Map<String, dynamic>) {
        _analysisResult = response['analysis'] ?? 'Analyse terminée.';
        
        final missionsJson = response['missions'] as List<dynamic>? ?? [];
        _suggestedMissions = missionsJson
            .map((json) => MissionModel.fromJson(json))
            .toList();
      }
    } catch (e) {
      _error = "L'analyse IA a échoué. Veuillez réessayer.";
      print("Erreur AiMissionSearchProvider: $e");
      // Mock pour démo si l'API n'est pas prête
      _simulateMockResponse(query);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Simulation de réponse pour démo (à supprimer en prod)
  void _simulateMockResponse(String query) {
    _analysisResult = "Je cherche une mission de livraison rapide près de Cocody.";
    _suggestedMissions = [
      MissionModel(
        id: '1',
        title: 'Livraison Document Urgent',
        location: 'Cocody, Abidjan',
        price: '7 500 FCFA',
        distance: '2.5 km',
        type: 'Livraison',
      ),
      MissionModel(
        id: '2',
        title: 'Course Supermarché',
        location: 'Plateau, Abidjan',
        price: '5 000 FCFA',
        distance: '1.8 km',
        type: 'Courses',
      ),
    ];
  }

  void clear() {
    _suggestedMissions = [];
    _analysisResult = null;
    _error = null;
    notifyListeners();
  }
}
