import 'package:flutter/foundation.dart';
import '../../../core/models/mission_model.dart';
import '../../../core/services/api_service.dart';

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
      // Endpoint : POST /api/v1/ai/search/
      // Body: { "query": "...", "type": "mission" }
      final response = await _apiService.post(
        '/ai/search/',
        data: {'query': query, 'type': 'mission'},
      );

      if (response is Map<String, dynamic>) {
        _analysisResult = response['analysis'] ?? 'Analyse terminée.';

        final missionsJson = response['missions'] as List<dynamic>? ?? [];
        _suggestedMissions =
            missionsJson.map((json) => MissionModel.fromJson(json)).toList();
      }
    } catch (e) {
      _error = "L'analyse IA a échoué. Veuillez réessayer.";
      debugPrint("Erreur AiMissionSearchProvider: $e");
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
        "Je cherche une mission de livraison rapide près de Cocody.";
    _suggestedMissions = [
      MissionModel(
        id: '1',
        title: 'Livraison Document Urgent',
        description: '',
        price: 7500,
        status: MissionStatus.PENDING,
        address: 'Cocody, Abidjan',
        category: 'Livraison',
        isUrgent: true,
      ),
      MissionModel(
        id: '2',
        title: 'Course Supermarché',
        description: '',
        price: 5000,
        status: MissionStatus.PENDING,
        address: 'Plateau, Abidjan',
        category: 'Courses',
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
