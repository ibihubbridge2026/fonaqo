import 'package:flutter/foundation.dart';
import '../models/mission_model.dart';
import '../../features/client/missions/mission_repository.dart';

class MissionProvider extends ChangeNotifier {
  final MissionRepository _repository = MissionRepository();

  List<MissionModel> _missions = [];
  bool _isLoading = false;
  String? _error;

  List<MissionModel> get missions => _missions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Rafraîchir la liste des missions
  Future<void> refreshMissions() async {
    await fetchMissions();
  }

  /// Récupérer les missions depuis l'API
  Future<void> fetchMissions() async {
    _setLoading(true);
    _clearError();

    try {
      final missions = await _repository.fetchMissionsList();
      _missions = missions;
      notifyListeners();
    } catch (e) {
      _setError('Erreur lors du chargement des missions: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
