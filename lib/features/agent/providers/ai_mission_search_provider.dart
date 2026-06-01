import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
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
        final responseData = response['response'] as Map<String, dynamic>?;

        if (responseData != null) {
          _analysisResult = responseData['suggestion'] ?? 'Analyse terminée.';

          final missionsJson = responseData['results'] as List<dynamic>? ?? [];
          _suggestedMissions =
              missionsJson.map((json) => MissionModel.fromJson(json)).toList();
        }
      }
    } catch (e) {
      _error = "Erreur de connexion. Vérifiez votre réseau internet.";
      Logger().e("Erreur AiMissionSearchProvider: $e");
      // Plus de mock - erreur réseau uniquement
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _suggestedMissions = [];
    _analysisResult = null;
    _error = null;
    notifyListeners();
  }
}
