import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';

import 'package:fonaco/features/client/leboncoin/models/local_listing_model.dart';

/// Intégration Google Places (préparée) pour enrichir LeBonCoin côté touristes.
///
/// Activez `GOOGLE_PLACES_API_KEY` dans `.env` pour interroger l'API réelle.
/// Sans clé, retourne une liste vide (les listings locaux FONACO restent affichés).
class GooglePlacesService {
  GooglePlacesService({Dio? dio, Logger? logger})
      : _dio = dio ?? Dio(),
        _logger = logger ?? Logger();

  final Dio _dio;
  final Logger _logger;

  String? get _apiKey {
    final fromEnv = dotenv.env['GOOGLE_PLACES_API_KEY'];
    if (fromEnv != null && fromEnv.trim().isNotEmpty) {
      return fromEnv.trim();
    }
    return null;
  }

  bool get isConfigured => _apiKey != null;

  /// Recherche d'établissements à proximité (restaurants, musées, salles de sport…).
  Future<List<LocalListingModel>> searchNearby({
    required double latitude,
    required double longitude,
    LeBonCoinFilter filter = LeBonCoinFilter.all,
    int radiusMeters = 5000,
  }) async {
    final apiKey = _apiKey;
    if (apiKey == null) {
      _logger.d('Google Places désactivé — clé API absente');
      return [];
    }

    final placeType = _placeTypeForFilter(filter);
    if (placeType == null) {
      return [];
    }

    try {
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json',
        queryParameters: {
          'location': '$latitude,$longitude',
          'radius': radiusMeters,
          'type': placeType,
          'key': apiKey,
          'language': 'fr',
        },
      );

      if (response.statusCode != 200) return [];
      final data = response.data;
      if (data is! Map) return [];

      final status = data['status']?.toString();
      if (status != 'OK' && status != 'ZERO_RESULTS') {
        _logger.w('Google Places status: $status');
        return [];
      }

      final results = data['results'];
      if (results is! List) return [];

      return results.map((raw) {
        final map = Map<String, dynamic>.from(raw as Map);
        final geometry = map['geometry']?['location'];
        final lat = geometry is Map ? geometry['lat'] : null;
        final lng = geometry is Map ? geometry['lng'] : null;
        final types = (map['types'] as List?)?.map((e) => e.toString()).toList() ?? [];

        return LocalListingModel(
          id: 'gplace_${map['place_id']}',
          name: map['name']?.toString() ?? 'Lieu',
          category: _categoryFromGoogleTypes(types, placeType),
          specialty: placeType,
          description: map['vicinity']?.toString() ?? '',
          address: map['vicinity']?.toString() ?? '',
          latitude: lat is num ? lat.toDouble() : double.tryParse('$lat'),
          longitude: lng is num ? lng.toDouble() : double.tryParse('$lng'),
          rating: (map['rating'] as num?)?.toDouble() ?? 4.0,
          tags: const ['google_places'],
        );
      }).toList();
    } catch (e, st) {
      _logger.w('Google Places indisponible', error: e, stackTrace: st);
      return [];
    }
  }

  String? _placeTypeForFilter(LeBonCoinFilter filter) {
    switch (filter) {
      case LeBonCoinFilter.restaurant:
        return 'restaurant';
      case LeBonCoinFilter.leisure:
        return 'tourist_attraction';
      case LeBonCoinFilter.gym:
        return 'gym';
      case LeBonCoinFilter.museum:
        return 'museum';
      case LeBonCoinFilter.shop:
        return 'store';
      case LeBonCoinFilter.all:
      case LeBonCoinFilter.artisan:
      case LeBonCoinFilter.service:
        return null;
    }
  }

  String _categoryFromGoogleTypes(List<String> types, String fallback) {
    if (types.contains('restaurant') || types.contains('food')) return 'restaurant';
    if (types.contains('gym')) return 'gym';
    if (types.contains('museum')) return 'museum';
    if (types.contains('store') || types.contains('shopping_mall')) return 'shop';
    if (types.contains('tourist_attraction')) return 'leisure';
    return fallback;
  }
}
