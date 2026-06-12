import 'package:logger/logger.dart';
import '../models/artisan_model.dart';
import '../../../core/seeds/dev_seed_artisans.dart';
import '../../../core/api/base_client.dart';

/// Repository pour la gestion des Artisans (Annuaire/Vitrine Publicitaire)
/// Source principale : API `public/artisans/` (agents vérifiés côté backend).
class ArtisanRepository {
  final BaseClient _baseClient;
  final Logger _logger = Logger();

  ArtisanRepository({BaseClient? baseClient})
      : _baseClient = baseClient ?? BaseClient();

  /// Récupère la liste des artisans avec filtres optionnels.
  Future<List<ArtisanModel>> fetchArtisans({
    String? query,
    String? specialty,
    String? location,
  }) async {
    try {
      return await _fetchArtisansFromApi(
        query: query,
        specialty: specialty,
        location: location,
      );
    } catch (e, st) {
      _logger.e('Erreur fetchArtisans', error: e, stackTrace: st);
      _logger.w('Fallback vers dev_seed_artisans (API indisponible)');
      return _filterSeedArtisans(
        query: query,
        specialty: specialty,
        location: location,
      );
    }
  }

  List<ArtisanModel> _filterSeedArtisans({
    String? query,
    String? specialty,
    String? location,
  }) {
    var artisans = devSeedArtisans;

    if (query != null && query.isNotEmpty) {
      final queryLower = query.toLowerCase();
      artisans = artisans.where((artisan) {
        return artisan.fullName.toLowerCase().contains(queryLower) ||
            artisan.specialty.toLowerCase().contains(queryLower) ||
            artisan.city.toLowerCase().contains(queryLower) ||
            artisan.district.toLowerCase().contains(queryLower);
      }).toList();
    }

    if (specialty != null && specialty.isNotEmpty) {
      final specialtyLower = specialty.toLowerCase();
      artisans = artisans.where((artisan) {
        return artisan.specialty.toLowerCase().contains(specialtyLower);
      }).toList();
    }

    if (location != null && location.isNotEmpty) {
      final locationLower = location.toLowerCase();
      artisans = artisans.where((artisan) {
        return artisan.city.toLowerCase().contains(locationLower) ||
            artisan.district.toLowerCase().contains(locationLower);
      }).toList();
    }

    return artisans;
  }

  Future<List<ArtisanModel>> _fetchArtisansFromApi({
    String? query,
    String? specialty,
    String? location,
  }) async {
    final queryParams = <String, String>{};

    if (query != null && query.isNotEmpty) {
      queryParams['query'] = query;
    }
    if (specialty != null && specialty.isNotEmpty) {
      queryParams['specialty'] = specialty;
    }
    if (location != null && location.isNotEmpty) {
      queryParams['location'] = location;
    }

    final response = await _baseClient.get(
      'public/artisans/',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final statusCode = response.statusCode ?? 0;
    if (statusCode != 200) {
      throw Exception('Erreur HTTP $statusCode');
    }

    final body = response.data;
    if (body is! Map<String, dynamic>) {
      throw Exception('Format de réponse invalide');
    }

    final data = body['data'];
    if (data is List<dynamic>) {
      return data
          .map((json) => ArtisanModel.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    throw Exception('Format de données invalide');
  }

  Future<ArtisanModel?> fetchArtisanById(String id) async {
    try {
      final response = await _baseClient.get('public/artisans/$id/');

      final statusCode = response.statusCode ?? 0;
      if (statusCode != 200) {
        throw Exception('Erreur HTTP $statusCode');
      }

      final body = response.data;
      if (body is! Map<String, dynamic>) {
        throw Exception('Format de réponse invalide');
      }

      final data = body['data'];
      if (data is Map<String, dynamic>) {
        return ArtisanModel.fromJson(data);
      }

      throw Exception('Format de données invalide');
    } catch (e, st) {
      _logger.e('Erreur fetchArtisanById', error: e, stackTrace: st);
      _logger.w('Fallback vers dev_seed_artisans');
      try {
        return devSeedArtisans.firstWhere((artisan) => artisan.id == id);
      } catch (_) {
        return null;
      }
    }
  }
}
