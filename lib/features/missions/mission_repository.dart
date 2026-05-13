import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../../core/api/base_client.dart';
import '../../core/models/mission_model.dart';

/// Données pour créer une mission (POST /missions/).
class MissionCreatePayload {
  final String title;
  final String description;
  final String address;
  final double latitude;
  final double longitude;
  final double price;
  final double serviceFee;
  final bool requiresProcuration;
  final String? targetAgentUsername;

  const MissionCreatePayload({
    required this.title,
    required this.description,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.price,
    required this.serviceFee,
    this.requiresProcuration = false,
    this.targetAgentUsername,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'price': price,
        'service_fee': serviceFee,
        'requires_procuration': requiresProcuration,
        if (targetAgentUsername != null)
          'target_agent_username': targetAgentUsername,
      };
}

/// Repository pour la gestion des missions.
class MissionRepository {
  final BaseClient _baseClient;
  final Logger _logger = Logger();

  MissionRepository({BaseClient? baseClient})
      : _baseClient = baseClient ?? BaseClient();

  List<dynamic> _extractListFromEnvelope(dynamic body) {
    if (body is! Map) return [];
    final data = body['data'];
    if (data is List<dynamic>) return data;
    if (data is Map<String, dynamic> && data['results'] is List<dynamic>) {
      return data['results'] as List<dynamic>;
    }
    return [];
  }

  Map<String, dynamic> _extractObjectFromEnvelope(dynamic body) {
    if (body is! Map<String, dynamic>) {
      throw Exception('Réponse JSON invalide');
    }
    final data = body['data'];
    if (data is Map<String, dynamic>) return data;
    throw Exception('Réponse sans objet « data »');
  }

  /// Missions disponibles pour les agents (proximité optionnelle).
  Future<List<MissionModel>> fetchAvailableMissions({
    double? latitude,
    double? longitude,
  }) async {
    try {
      _logger.i('Récupération missions disponibles (agents)...');
      final Map<String, dynamic> query = {};
      if (latitude != null && longitude != null) {
        query['lat'] = latitude.toString();
        query['lng'] = longitude.toString();
      }

      final response = await _baseClient.get(
        'missions/available/',
        queryParameters: query.isEmpty ? null : query,
      );

      if (response.statusCode != 200) {
        throw Exception('Erreur HTTP ${response.statusCode}');
      }

      final raw = response.data;
      List<dynamic> rows;
      if (raw is Map && raw['data'] is List) {
        rows = raw['data'] as List<dynamic>;
      } else {
        rows = _extractListFromEnvelope(raw);
      }

      return rows
          .map((e) => MissionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      _logger.e('fetchAvailableMissions', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Liste paginée ou missions du client (GET /missions/).
  Future<List<MissionModel>> fetchMissionsList({
    double? latitude,
    double? longitude,
  }) async {
    try {
      final Map<String, dynamic> query = {};
      if (latitude != null && longitude != null) {
        query['lat'] = latitude.toString();
        query['lng'] = longitude.toString();
      }

      final response = await _baseClient.get(
        'missions/',
        queryParameters: query.isEmpty ? null : query,
      );

      if (response.statusCode != 200) {
        throw Exception('Erreur HTTP ${response.statusCode}');
      }

      final rows = _extractListFromEnvelope(response.data);
      return rows
          .map((e) => MissionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      _logger.e('fetchMissionsList', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<MissionModel> fetchMissionDetails(String missionId) async {
    try {
      final response = await _baseClient.get('missions/$missionId/');
      if (response.statusCode != 200) {
        throw Exception('Mission non trouvée (status: ${response.statusCode})');
      }

      // Essayer différents formats de réponse
      Map<String, dynamic> missionMap;
      try {
        missionMap = _extractObjectFromEnvelope(response.data);
      } catch (e) {
        // Si l'enveloppe ne fonctionne pas, essayer directement
        if (response.data is Map<String, dynamic>) {
          missionMap = response.data as Map<String, dynamic>;
        } else {
          throw Exception('Format de réponse invalide: $e');
        }
      }

      return MissionModel.fromJson(missionMap);
    } catch (e, st) {
      _logger.e('fetchMissionDetails - Erreur: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<MissionModel> createMission(MissionCreatePayload payload) async {
    try {
      final response = await _baseClient.post(
        'missions/',
        data: payload.toJson(),
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Création mission refusée',
        );
      }
      final missionMap = _extractObjectFromEnvelope(response.data);
      return MissionModel.fromJson(missionMap);
    } catch (e, st) {
      _logger.e('createMission', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<bool> acceptMission(String missionId) async {
    try {
      final response = await _baseClient.post('missions/$missionId/accept/');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e, st) {
      _logger.e('acceptMission', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Démarre la mission (agent) → IN_PROGRESS + notification WebSocket.
  Future<MissionModel> startMission(String missionId) async {
    final response =
        await _baseClient.post('missions/$missionId/start_mission/');
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Impossible de démarrer la mission');
    }
    return MissionModel.fromJson(_extractObjectFromEnvelope(response.data));
  }

  /// Termine la mission (agent, flux live) → COMPLETED + notification WebSocket.
  Future<MissionModel> markMissionCompletedLive(String missionId) async {
    final response =
        await _baseClient.post('missions/$missionId/mark_completed_live/');
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Impossible de clôturer la mission');
    }
    return MissionModel.fromJson(_extractObjectFromEnvelope(response.data));
  }

  /// Catégories de services (GET /services/categories/).
  Future<List<Map<String, dynamic>>> fetchServiceCategories() async {
    try {
      final response = await _baseClient.get('services/categories/');
      if (response.statusCode != 200) return [];
      final body = response.data;
      if (body is! Map<String, dynamic>) return [];
      final data = body['data'];
      if (data is List<dynamic>) {
        return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    } catch (e, st) {
      _logger.e('fetchServiceCategories', error: e, stackTrace: st);
      return [];
    }
  }

  /// Agents vérifiés pour le dashboard (GET /accounts/agents/suggestions/).
  Future<List<Map<String, dynamic>>> fetchAgentSuggestions() async {
    try {
      final response = await _baseClient.get('accounts/agents/suggestions/');
      if (response.statusCode != 200) return [];
      final body = response.data;
      if (body is! Map<String, dynamic>) return [];
      final data = body['data'];
      if (data is List<dynamic>) {
        return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    } catch (e, st) {
      _logger.e('fetchAgentSuggestions', error: e, stackTrace: st);
      return [];
    }
  }
}
