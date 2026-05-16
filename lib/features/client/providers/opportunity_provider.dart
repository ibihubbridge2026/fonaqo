import 'package:flutter/foundation.dart';
import '../models/opportunity_model.dart';
import '../../../core/services/api_service.dart';

/// Provider pour gérer les Opportunités (Services)
class OpportunityProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<OpportunityModel> _opportunities = [];
  bool _isLoading = false;
  String? _error;

  List<OpportunityModel> get opportunities => _opportunities;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Récupère les opportunités depuis le backend
  Future<void> fetchOpportunities({String? category}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Endpoint : GET /api/opportunities/
      // Params optionnels : ?category=Banque
      final response = await _apiService.get(
        '/opportunities/',
        queryParameters: category != null ? {'category': category} : null,
      );

      if (response is List) {
        _opportunities = response
            .map((json) => OpportunityModel.fromJson(json))
            .toList();
      } else {
        _opportunities = [];
      }
    } catch (e) {
      _error = "Impossible de charger les opportunités. Vérifiez votre connexion.";
      print("Erreur OpportunityProvider: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Réinitialise la liste (pour refresh)
  void clear() {
    _opportunities = [];
    _error = null;
    notifyListeners();
  }
}
