import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../models/artisan_model.dart';
import '../../../core/seeds/dev_seed_artisans.dart';
import '../../../core/api/base_client.dart';

/// Repository pour la gestion des Artisans (Annuaire/Vitrine Publicitaire)
/// Totalement indépendant du flux des Agents Fonaqo
class ArtisanRepository {
  final BaseClient _baseClient;
  final Logger _logger = Logger();

  ArtisanRepository({BaseClient? baseClient})
      : _baseClient = baseClient ?? BaseClient();

  /// Récupère la liste des artisans avec filtres optionnels
  /// 
  /// [query] - Recherche textuelle (nom, spécialité)
  /// [specialty] - Filtrer par spécialité
  /// [location] - Filtrer par ville ou quartier
  /// 
  /// En mode Debug: retourne les données du seed filtrées
  /// En mode Release: appelle l'endpoint API /api/v1/public/artisans
  Future<List<ArtisanModel>> fetchArtisans({
    String? query,
    String? specialty,
    String? location,
  }) async {
    try {
      // Mode Debug: utiliser le seed de données
      if (kDebugMode) {
        _logger.i('🔧 Mode Debug: Utilisation du seed artisans');
        return _filterSeedArtisans(query: query, specialty: specialty, location: location);
      }

      // Mode Release: appeler l'API
      _logger.i('🌐 Mode Release: Appel API artisans');
      return await _fetchArtisansFromApi(query: query, specialty: specialty, location: location);
    } catch (e, st) {
      _logger.e('Erreur fetchArtisans', error: e, stackTrace: st);
      
      // Fallback: retourner le seed en cas d'erreur API
      if (!kDebugMode) {
        _logger.w('⚠️ Erreur API, fallback vers seed artisans');
        return _filterSeedArtisans(query: query, specialty: specialty, location: location);
      }
      
      rethrow;
    }
  }

  /// Filtre les artisans du seed selon les critères
  List<ArtisanModel> _filterSeedArtisans({
    String? query,
    String? specialty,
    String? location,
  }) {
    var artisans = devSeedArtisans;

    // Filtrer par recherche textuelle
    if (query != null && query.isNotEmpty) {
      final queryLower = query.toLowerCase();
      artisans = artisans.where((artisan) {
        return artisan.fullName.toLowerCase().contains(queryLower) ||
               artisan.specialty.toLowerCase().contains(queryLower) ||
               artisan.city.toLowerCase().contains(queryLower) ||
               artisan.district.toLowerCase().contains(queryLower);
      }).toList();
    }

    // Filtrer par spécialité
    if (specialty != null && specialty.isNotEmpty) {
      final specialtyLower = specialty.toLowerCase();
      artisans = artisans.where((artisan) {
        return artisan.specialty.toLowerCase().contains(specialtyLower);
      }).toList();
    }

    // Filtrer par localisation
    if (location != null && location.isNotEmpty) {
      final locationLower = location.toLowerCase();
      artisans = artisans.where((artisan) {
        return artisan.city.toLowerCase().contains(locationLower) ||
               artisan.district.toLowerCase().contains(locationLower);
      }).toList();
    }

    return artisans;
  }

  /// Récupère les artisans depuis l'API (Mode Release)
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

    if (response.statusCode != 200) {
      throw Exception('Erreur HTTP ${response.statusCode}');
    }

    final body = response.data;
    if (body is! Map<String, dynamic>) {
      throw Exception('Format de réponse invalide');
    }

    final data = body['data'];
    if (data is List<dynamic>) {
      return data.map((json) => ArtisanModel.fromJson(json as Map<String, dynamic>)).toList();
    }

    throw Exception('Format de données invalide');
  }

  /// Récupère un artisan par son ID
  Future<ArtisanModel?> fetchArtisanById(String id) async {
    try {
      // Mode Debug: chercher dans le seed
      if (kDebugMode) {
        _logger.i('🔧 Mode Debug: Recherche artisan dans seed');
        return devSeedArtisans.firstWhere(
          (artisan) => artisan.id == id,
          orElse: () => throw Exception('Artisan non trouvé'),
        );
      }

      // Mode Release: appeler l'API
      _logger.i('🌐 Mode Release: Appel API artisan');
      final response = await _baseClient.get('public/artisans/$id/');

      if (response.statusCode != 200) {
        throw Exception('Erreur HTTP ${response.statusCode}');
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
      
      // Fallback: chercher dans le seed
      if (!kDebugMode) {
        _logger.w('⚠️ Erreur API, fallback vers seed');
        try {
          return devSeedArtisans.firstWhere(
            (artisan) => artisan.id == id,
            orElse: () => throw Exception('Artisan non trouvé'),
          );
        } catch (_) {
          return null;
        }
      }
      
      return null;
    }
  }
}
