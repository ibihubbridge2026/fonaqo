import 'package:logger/logger.dart';

import 'package:fonaco/core/api/base_client.dart';
import 'package:fonaco/core/constants/app_constants.dart';
import 'package:fonaco/core/seeds/dev_seed_leboncoin.dart';
import 'package:fonaco/features/client/leboncoin/models/local_listing_model.dart';

class LeBonCoinRepository {
  final BaseClient _baseClient;
  final Logger _logger = Logger();

  LeBonCoinRepository({BaseClient? baseClient})
      : _baseClient = baseClient ?? BaseClient();

  Future<List<LocalListingModel>> fetchListings({
    LeBonCoinFilter filter = LeBonCoinFilter.all,
    String? query,
    double? latitude,
    double? longitude,
    int radiusMeters = 15000,
  }) async {
    try {
      final params = <String, String>{};
      final category = filter.apiCategory;
      if (category != null) params['category'] = category;
      if (query != null && query.trim().isNotEmpty) {
        params['query'] = query.trim();
      }
      if (latitude != null && longitude != null) {
        params['latitude'] = latitude.toString();
        params['longitude'] = longitude.toString();
        params['radius'] = radiusMeters.toString();
      }

      final response = await _baseClient.get(
        'leboncoin/listings/',
        queryParameters: params.isNotEmpty ? params : null,
      );

      if (response.statusCode == 200) {
        return _parseList(response.data);
      }
      throw Exception('HTTP ${response.statusCode}');
    } catch (e, st) {
      _logger.w('LeBonCoin API indisponible — seed local', error: e, stackTrace: st);
      return _filterSeed(filter: filter, query: query);
    }
  }

  List<LocalListingModel> _filterSeed({
    required LeBonCoinFilter filter,
    String? query,
  }) {
    var items = devSeedLeBonCoinListings;
    final category = filter.apiCategory;
    if (category != null) {
      items = items.where((e) => e.category == category).toList();
    }
    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      items = items.where((e) {
        return e.name.toLowerCase().contains(q) ||
            e.specialty.toLowerCase().contains(q) ||
            e.district.toLowerCase().contains(q) ||
            e.city.toLowerCase().contains(q);
      }).toList();
    }
    return items;
  }

  List<LocalListingModel> _parseList(dynamic raw) {
    List<dynamic> rows;
    if (raw is Map && raw['results'] is List) {
      rows = raw['results'] as List;
    } else if (raw is List) {
      rows = raw;
    } else {
      return devSeedLeBonCoinListings;
    }
    return rows
        .map((e) => LocalListingModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

/// Coordonnées par défaut carte LeBonCoin (Cotonou).
const leBonCoinDefaultLat = AppConstants.defaultLatitude;
const leBonCoinDefaultLng = AppConstants.defaultLongitude;
