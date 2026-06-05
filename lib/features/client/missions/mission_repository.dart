import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import 'package:fonaco/core/api/base_client.dart';
import 'package:fonaco/core/models/mission_model.dart';
import 'package:fonaco/core/services/cache_service.dart';

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
  final bool isUrgent;
  final bool isConfidential;
  final double purchaseAmount;
  final double serviceAmount;
  final String recurrence;

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
    this.isUrgent = false,
    this.isConfidential = false,
    this.purchaseAmount = 0,
    this.serviceAmount = 0,
    this.recurrence = 'once',
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
        'is_urgent': isUrgent,
        'is_confidential': isConfidential,
        'purchase_amount': purchaseAmount,
        'service_amount': serviceAmount,
        'recurrence': recurrence,
        if (targetAgentUsername != null)
          'target_agent_username': targetAgentUsername,
      };
}

/// Repository pour la gestion des missions.
class MissionRepository {
  final BaseClient _baseClient;
  final Logger _logger = Logger();
  final CacheService _cacheService = CacheService();

  MissionRepository({BaseClient? baseClient})
      : _baseClient = baseClient ?? BaseClient();

  List<dynamic> _extractListFromEnvelope(dynamic body) {
    if (body is! Map) return [];
    final data = body['data'];
    if (data is List<dynamic>) return data;
    if (data is Map<String, dynamic>) {
      // Cas standard: data.results
      if (data['results'] is List<dynamic>) {
        return data['results'] as List<dynamic>;
      }
      // Cas double imbrication: data.data.results
      if (data['data'] is Map<String, dynamic> &&
          data['data']['results'] is List<dynamic>) {
        return data['data']['results'] as List<dynamic>;
      }
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
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final Map<String, dynamic> query = {
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };
      if (latitude != null && longitude != null) {
        query['lat'] = latitude.toString();
        query['lng'] = longitude.toString();
      }

      _logger.i('📡 Appel API: missions/ avec params: $query');

      final response = await _baseClient.get(
        'missions/',
        queryParameters: query,
      );

      _logger.i(
          '📡 Réponse API: status=${response.statusCode}, data=${response.data}');

      if (response.statusCode != 200) {
        throw Exception('Erreur HTTP ${response.statusCode}');
      }

      final rows = _extractListFromEnvelope(response.data);
      _logger.i('✅ Missions parsées: ${rows.length}');

      return rows
          .map((e) => MissionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      _logger.e('fetchMissionsList', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<MissionModel> fetchMissionDetails(String missionId) async {
    // 1. Initialiser le cache si nécessaire
    if (!_cacheService.isInitialized) {
      try {
        await _cacheService.init();
      } catch (e) {
        _logger.w('⚠️ Erreur initialisation cache: $e');
      }
    }

    // 2. Charger depuis le cache d'abord (Cache-First)
    final cachedMission = _cacheService.getCachedMission(missionId);
    if (cachedMission != null) {
      _logger.i('📦 Mission $missionId chargée depuis le cache');
      try {
        return MissionModel.fromJson(cachedMission);
      } catch (e) {
        _logger.w('⚠️ Erreur parsing cache mission: $e');
      }
    }

    // 3. Si pas de cache ou erreur, charger depuis l'API
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

      final mission = MissionModel.fromJson(missionMap);

      // 4. Mettre à jour le cache en arrière-plan
      _cacheService.cacheMission(missionId, mission.toJson());

      return mission;
    } catch (e, st) {
      _logger.e('fetchMissionDetails - Erreur: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Rafraîchir silencieusement les détails d'une mission (background refresh)
  Future<void> refreshMissionDetails(String missionId) async {
    try {
      final response = await _baseClient.get('missions/$missionId/');
      if (response.statusCode != 200) {
        _logger
            .w('⚠️ Refresh mission $missionId échoué: ${response.statusCode}');
        return;
      }

      Map<String, dynamic> missionMap;
      try {
        missionMap = _extractObjectFromEnvelope(response.data);
      } catch (e) {
        if (response.data is Map<String, dynamic>) {
          missionMap = response.data as Map<String, dynamic>;
        } else {
          return;
        }
      }

      // Mettre à jour le cache
      await _cacheService.cacheMission(missionId, missionMap);
      _logger.i('🔄 Mission $missionId rafraîchie en arrière-plan');
    } catch (e, st) {
      _logger.w('⚠️ Erreur refresh mission: $e', error: e, stackTrace: st);
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
  /// Accepte des coordonnées optionnelles pour le filtrage par distance.
  Future<List<Map<String, dynamic>>> fetchAgentSuggestions({
    double? latitude,
    double? longitude,
    int limit = 12,
  }) async {
    try {
      // Construire les paramètres de requête
      final queryParams = <String, String>{};
      if (latitude != null) queryParams['latitude'] = latitude.toString();
      if (longitude != null) queryParams['longitude'] = longitude.toString();
      if (limit != 12) queryParams['limit'] = limit.toString();

      final response = await _baseClient.get(
        'accounts/agents/suggestions/',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
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

  /// Agents à proximité (GET /accounts/agents/nearby/).
  /// Accepte les coordonnées GPS et les filtres optionnels.
  /// Si latitude/longitude ne sont pas fournis, récupère tous les agents actifs.
  Future<List<Map<String, dynamic>>> fetchNearbyAgents({
    double? latitude,
    double? longitude,
    double? radiusKm,
    double? minRating,
    bool? verifiedOnly,
    List<String>? missionTypes,
    int? minPrice,
    int? maxPrice,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{};

      // N'envoyer les coordonnées que si elles sont fournies (mode "Proches de moi")
      if (latitude != null && longitude != null) {
        queryParams['latitude'] = latitude.toString();
        queryParams['longitude'] = longitude.toString();
        if (radiusKm != null) queryParams['radius_km'] = radiusKm.toString();
      }

      if (minRating != null) queryParams['min_rating'] = minRating.toString();
      if (verifiedOnly != null)
        queryParams['verified_only'] = verifiedOnly.toString();
      if (limit != 20) queryParams['limit'] = limit.toString();
      if (minPrice != null) queryParams['min_price'] = minPrice.toString();
      if (maxPrice != null) queryParams['max_price'] = maxPrice.toString();
      if (missionTypes != null && missionTypes.isNotEmpty) {
        queryParams['mission_types'] = missionTypes.join(',');
      }

      final response = await _baseClient.get(
        'accounts/agents/nearby/',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      if (response.statusCode != 200) return [];
      final body = response.data;
      if (body is! Map<String, dynamic>) return [];
      final data = body['data'];
      if (data is List<dynamic>) {
        return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    } catch (e, st) {
      _logger.e('fetchNearbyAgents', error: e, stackTrace: st);
      return [];
    }
  }

  /// Noter une mission terminée
  Future<void> rateMission(
    String missionId,
    int rating,
    String comment,
  ) async {
    try {
      _logger.i('Notation de la mission $missionId: $rating étoiles');

      final response = await _baseClient.post(
        'missions/$missionId/rate/',
        data: {
          'rating': rating,
          'comment': comment,
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Erreur HTTP ${response.statusCode}');
      }

      _logger.i('✅ Mission notée avec succès');
    } catch (e, st) {
      _logger.e('rateMission', error: e, stackTrace: st);
      rethrow;
    }
  }
}
