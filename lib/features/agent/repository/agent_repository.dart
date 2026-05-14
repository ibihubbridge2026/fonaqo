import 'package:logger/logger.dart';
import '../../../core/api/base_client.dart';
import '../../../core/models/mission_model.dart';

/// Repository pour les appels API spécifiques à l'Agent
class AgentRepository {
  final Logger _logger = Logger();
  final BaseClient _baseClient = BaseClient();

  /// Récupère le solde de l'agent
  Future<double> getAgentBalance() async {
    try {
      final response = await _baseClient.get('agent/balance/');
      
      if (response.statusCode == 200) {
        final balance = response.data['data']['balance']?.toDouble() ?? 0.0;
        _logger.d('Solde agent récupéré: $balance');
        return balance;
      } else {
        _logger.e('Erreur récupération solde: ${response.statusCode}');
        return 0.0;
      }
    } catch (e) {
      _logger.e('Erreur getAgentBalance: $e');
      return 0.0;
    }
  }

  /// Récupère les missions disponibles pour l'agent
  Future<List<MissionModel>> getAvailableMissions() async {
    try {
      final response = await _baseClient.get('agent/missions/available/');
      
      if (response.statusCode == 200) {
        final List<dynamic> missionsData = response.data['data']['missions'] ?? [];
        final missions = missionsData.map((data) => MissionModel.fromJson(data)).toList();
        _logger.d('Missions disponibles récupérées: ${missions.length}');
        return missions;
      } else {
        _logger.e('Erreur récupération missions: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      _logger.e('Erreur getAvailableMissions: $e');
      return [];
    }
  }

  /// Met à jour le statut en ligne de l'agent
  Future<bool> updateOnlineStatus(bool isOnline) async {
    try {
      final response = await _baseClient.patch(
        'agent/status/',
        data: {
          'is_online': isOnline,
        },
      );
      
      if (response.statusCode == 200) {
        _logger.d('Statut online mis à jour: $isOnline');
        return true;
      } else {
        _logger.e('Erreur mise à jour statut: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      _logger.e('Erreur updateOnlineStatus: $e');
      return false;
    }
  }

  /// Accepte une mission
  Future<bool> acceptMission(String missionId) async {
    try {
      final response = await _baseClient.post(
        'agent/missions/$missionId/accept/',
        data: {},
      );
      
      if (response.statusCode == 200) {
        _logger.d('Mission acceptée: $missionId');
        return true;
      } else {
        _logger.e('Erreur acceptation mission: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      _logger.e('Erreur acceptMission: $e');
      return false;
    }
  }

  /// Démarre une mission
  Future<bool> startMission(String missionId) async {
    try {
      final response = await _baseClient.post(
        'agent/missions/$missionId/start/',
        data: {},
      );
      
      if (response.statusCode == 200) {
        _logger.d('Mission démarrée: $missionId');
        return true;
      } else {
        _logger.e('Erreur démarrage mission: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      _logger.e('Erreur startMission: $e');
      return false;
    }
  }

  /// Termine une mission
  Future<bool> completeMission(String missionId, Map<String, dynamic> completionData) async {
    try {
      final response = await _baseClient.post(
        'agent/missions/$missionId/complete/',
        data: completionData,
      );
      
      if (response.statusCode == 200) {
        _logger.d('Mission terminée: $missionId');
        return true;
      } else {
        _logger.e('Erreur terminaison mission: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      _logger.e('Erreur completeMission: $e');
      return false;
    }
  }

  /// Récupère les statistiques de l'agent
  Future<Map<String, dynamic>> getAgentStats() async {
    try {
      final response = await _baseClient.get('agent/stats/');
      
      if (response.statusCode == 200) {
        final stats = response.data['data'] ?? {};
        _logger.d('Statistiques agent récupérées');
        return stats;
      } else {
        _logger.e('Erreur récupération statistiques: ${response.statusCode}');
        return {};
      }
    } catch (e) {
      _logger.e('Erreur getAgentStats: $e');
      return {};
    }
  }

  /// Récupère l'historique des missions de l'agent
  Future<List<MissionModel>> getAgentMissionHistory({int limit = 20}) async {
    try {
      final response = await _baseClient.get(
        'agent/missions/history/',
        queryParameters: {'limit': limit.toString()},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> missionsData = response.data['data']['missions'] ?? [];
        final missions = missionsData.map((data) => MissionModel.fromJson(data)).toList();
        _logger.d('Historique missions récupéré: ${missions.length}');
        return missions;
      } else {
        _logger.e('Erreur récupération historique: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      _logger.e('Erreur getAgentMissionHistory: $e');
      return [];
    }
  }
}
