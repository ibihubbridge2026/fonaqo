import 'package:fonaco/core/api/base_client.dart';
import 'package:fonaco/core/utils/app_logger.dart';
import 'package:fonaco/features/rating/models/rating.dart';

/// Repository pour les évaluations
class RatingRepository {
  final BaseClient _api = BaseClient();
  final AppLogger _logger = AppLogger();

  /// Soumet une évaluation
  Future<Rating?> submitRating({
    required String missionId,
    required String ratedId,
    required int score,
    required RatingType type,
    String? comment,
  }) async {
    try {
      final response = await _api.post(
        '/ratings/',
        data: {
          'mission_id': missionId,
          'rated_id': ratedId,
          'score': score,
          'type': type.toJson(),
          if (comment != null) 'comment': comment,
        },
      );

      if (response.statusCode == 201) {
        _logger.i('Rating submitted successfully for mission $missionId');
        return Rating.fromJson(response.data as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      _logger.e('Error submitting rating: $e');
      return null;
    }
  }

  /// Récupère les évaluations d'un utilisateur
  Future<List<Rating>> getUserRatings(String userId, {RatingType? type}) async {
    try {
      String endpoint = '/ratings/user/$userId/';
      if (type != null) {
        endpoint += '?type=${type.toJson()}';
      }

      final response = await _api.get(endpoint);

      if (response.statusCode == 200) {
        final data = response.data as List;
        return data.map((item) => Rating.fromJson(item as Map<String, dynamic>)).toList();
      }

      return [];
    } catch (e) {
      _logger.e('Error fetching user ratings: $e');
      return [];
    }
  }

  /// Récupère les évaluations d'une mission
  Future<List<Rating>> getMissionRatings(String missionId) async {
    try {
      final response = await _api.get('/ratings/mission/$missionId/');

      if (response.statusCode == 200) {
        final data = response.data as List;
        return data.map((item) => Rating.fromJson(item as Map<String, dynamic>)).toList();
      }

      return [];
    } catch (e) {
      _logger.e('Error fetching mission ratings: $e');
      return [];
    }
  }

  /// Récupère les statistiques d'un utilisateur
  Future<RatingStats?> getUserStats(String userId) async {
    try {
      final response = await _api.get('/ratings/stats/$userId/');

      if (response.statusCode == 200) {
        return RatingStats.fromJson(response.data as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      _logger.e('Error fetching user stats: $e');
      return null;
    }
  }

  /// Met à jour une évaluation
  Future<Rating?> updateRating({
    required String ratingId,
    int? score,
    String? comment,
  }) async {
    try {
      final response = await _api.patch(
        '/ratings/$ratingId/',
        data: {
          if (score != null) 'score': score,
          if (comment != null) 'comment': comment,
        },
      );

      if (response.statusCode == 200) {
        _logger.i('Rating updated successfully: $ratingId');
        return Rating.fromJson(response.data as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      _logger.e('Error updating rating: $e');
      return null;
    }
  }

  /// Supprime une évaluation
  Future<bool> deleteRating(String ratingId) async {
    try {
      final response = await _api.delete('/ratings/$ratingId/');

      if (response.statusCode == 204) {
        _logger.i('Rating deleted successfully: $ratingId');
        return true;
      }

      return false;
    } catch (e) {
      _logger.e('Error deleting rating: $e');
      return false;
    }
  }

  /// Vérifie si l'utilisateur peut noter une mission
  Future<bool> canRateMission(String missionId) async {
    try {
      final response = await _api.get('/ratings/can-rate/$missionId/');

      if (response.statusCode == 200) {
        return response.data['can_rate'] as bool;
      }

      return false;
    } catch (e) {
      _logger.e('Error checking if can rate mission: $e');
      return false;
    }
  }
}
