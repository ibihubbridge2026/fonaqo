import 'package:logger/logger.dart';

import '../../core/api/base_client.dart';
import '../../core/models/mission_model.dart';

/// Repository pour la gestion des missions
/// Centralise les appels API liés aux missions
class MissionRepository {
  final BaseClient _baseClient;
  final Logger _logger = Logger();

  MissionRepository() : _baseClient = BaseClient();

  /// Récupère les missions disponibles autour de l'utilisateur
  Future<List<MissionModel>> fetchAvailableMissions({
    double? latitude,
    double? longitude,
    double radius = 10.0, // Rayon par défaut en km
  }) async {
    try {
      _logger.i('Récupération missions disponibles...');

      // Déterminer l'endpoint selon le rôle de l'utilisateur
      final String endpoint;

      // TODO: Récupérer le rôle depuis AuthProvider de manière plus propre
      // Pour l'instant, on utilise l'endpoint client par défaut
      endpoint =
          '/missions/'; // Endpoint pour les clients (leurs propres missions)

      // Préparer les paramètres de requête
      final Map<String, String> requestParams = {};
      if (latitude != null && longitude != null) {
        requestParams['latitude'] = latitude.toString();
        requestParams['longitude'] = longitude.toString();
      }
      if (radius != 10.0) {
        requestParams['radius'] = radius.toString();
      }

      // Appeler l'API pour récupérer les missions
      final response = await _baseClient.get(
        endpoint,
        queryParameters: requestParams,
      );

      _logger.i('Missions récupérées: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;
        final missionsData = responseData['data'] as List<dynamic>? ?? [];
        final missions = missionsData
            .map(
              (missionJson) =>
                  MissionModel.fromJson(missionJson as Map<String, dynamic>),
            )
            .toList();

        _logger.d('Nombre de missions: ${missions.length}');
        return missions;
      } else {
        final errorMessage = response.data is Map
            ? response.data['message'] ??
                  'Erreur lors de la récupération des missions'
            : 'Erreur lors de la récupération des missions';
        _logger.e('Erreur missions: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      _logger.e('Exception lors de fetchAvailableMissions: $e');
      throw Exception('Erreur de connexion: ${e.toString()}');
    }
  }

  /// Récupère les détails d'une mission spécifique
  Future<MissionModel> fetchMissionDetails(int missionId) async {
    try {
      _logger.d('Récupération détails mission: $missionId');

      final response = await _baseClient.get('/missions/$missionId/');

      if (response.statusCode == 200) {
        final missionData = response.data['data'] as Map<String, dynamic>;
        final mission = MissionModel.fromJson(missionData);

        _logger.i('Détails mission récupérés: ${mission.title}');
        return mission;
      } else {
        final errorMessage = response.data is Map
            ? response.data['message'] ?? 'Mission non trouvée'
            : 'Mission non trouvée';
        _logger.e('Erreur détails mission: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      _logger.e('Exception lors de fetchMissionDetails: $e');
      throw Exception('Erreur de connexion: ${e.toString()}');
    }
  }

  /// Accepte une mission
  Future<bool> acceptMission(int missionId) async {
    try {
      _logger.d('Acceptation mission: $missionId');

      final response = await _baseClient.post('/missions/$missionId/accept/');

      if (response.statusCode == 200) {
        _logger.i('Mission acceptée avec succès');
        return true;
      } else {
        final errorMessage = response.data is Map
            ? response.data['message'] ??
                  "Erreur lors de l'acceptation de la mission"
            : "Erreur lors de l'acceptation de la mission";
        _logger.e('Erreur acceptation mission: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      _logger.e('Exception lors de acceptMission: $e');
      throw Exception('Erreur de connexion: ${e.toString()}');
    }
  }

  /// Annule une mission
  Future<bool> cancelMission(int missionId, {String? reason}) async {
    try {
      _logger.d('Annulation mission: $missionId');

      final data = <String, dynamic>{};
      if (reason != null && reason.isNotEmpty) {
        data['reason'] = reason;
      }

      final response = await _baseClient.post(
        '/missions/$missionId/cancel/',
        data: data,
      );

      if (response.statusCode == 200) {
        _logger.i('Mission annulée avec succès');
        return true;
      } else {
        final errorMessage = response.data is Map
            ? response.data['message'] ??
                  "Erreur lors de l'annulation de la mission"
            : "Erreur lors de l'annulation de la mission";
        _logger.e('Erreur annulation mission: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      _logger.e('Exception lors de cancelMission: $e');
      throw Exception('Erreur de connexion: ${e.toString()}');
    }
  }
}
