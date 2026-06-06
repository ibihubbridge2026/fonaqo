import 'package:fonaco/core/api/base_client.dart';
import 'package:fonaco/core/utils/app_logger.dart';
import 'package:fonaco/features/boost/models/boost.dart';

/// Repository pour les boosts
class BoostRepository {
  final BaseClient _api = BaseClient();
  final AppLogger _logger = AppLogger();

  /// Active un boost pour une mission
  Future<Boost?> activateBoost({
    required String missionId,
    required int durationHours,
    required double amount,
  }) async {
    try {
      final response = await _api.post(
        '/boosts/',
        data: {
          'mission_id': missionId,
          'duration_hours': durationHours,
          'amount': amount,
        },
      );

      if (response.statusCode == 201) {
        _logger.i('Boost activated for mission $missionId');
        return Boost.fromJson(response.data as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      _logger.e('Error activating boost: $e');
      return null;
    }
  }

  /// Récupère les boosts actifs de l'utilisateur
  Future<List<Boost>> getActiveBoosts() async {
    try {
      final response = await _api.get('/boosts/active/');

      if (response.statusCode == 200) {
        final data = response.data as List;
        return data
            .map((item) => Boost.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      _logger.e('Error fetching active boosts: $e');
      return [];
    }
  }

  /// Récupère l'historique des boosts de l'utilisateur
  Future<List<Boost>> getBoostHistory({int page = 1, int pageSize = 20}) async {
    try {
      final response = await _api.get(
        '/boosts/history/',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['results'] as List;
        return data
            .map((item) => Boost.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      _logger.e('Error fetching boost history: $e');
      return [];
    }
  }

  /// Récupère le boost actif d'une mission
  Future<Boost?> getMissionBoost(String missionId) async {
    try {
      final response = await _api.get('/boosts/mission/$missionId/');

      if (response.statusCode == 200) {
        return Boost.fromJson(response.data as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      _logger.e('Error fetching mission boost: $e');
      return null;
    }
  }

  /// Annule un boost
  Future<bool> cancelBoost(String boostId) async {
    try {
      final response = await _api.post('/boosts/$boostId/cancel/');

      if (response.statusCode == 200) {
        _logger.i('Boost cancelled: $boostId');
        return true;
      }

      return false;
    } catch (e) {
      _logger.e('Error cancelling boost: $e');
      return false;
    }
  }

  /// Prolonge un boost
  Future<Boost?> extendBoost({
    required String boostId,
    required int additionalHours,
    required double amount,
  }) async {
    try {
      final response = await _api.post(
        '/boosts/$boostId/extend/',
        data: {
          'additional_hours': additionalHours,
          'amount': amount,
        },
      );

      if (response.statusCode == 200) {
        _logger.i('Boost extended: $boostId');
        return Boost.fromJson(response.data as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      _logger.e('Error extending boost: $e');
      return null;
    }
  }

  /// Récupère les boosts disponibles dans la zone
  Future<List<Boost>> getNearbyBoosts({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
  }) async {
    try {
      final response = await _api.get(
        '/boosts/nearby/',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'radius_km': radiusKm,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as List;
        return data
            .map((item) => Boost.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      _logger.e('Error fetching nearby boosts: $e');
      return [];
    }
  }
}
