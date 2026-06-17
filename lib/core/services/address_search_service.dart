import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geocoding/geocoding.dart';
import 'package:logger/logger.dart';

import 'location_service.dart';

class AddressSuggestion {
  final String label;
  final String? subtitle;
  final double? latitude;
  final double? longitude;
  final String? placeId;

  const AddressSuggestion({
    required this.label,
    this.subtitle,
    this.latitude,
    this.longitude,
    this.placeId,
  });

  bool get needsPlaceDetails =>
      placeId != null &&
      placeId!.isNotEmpty &&
      (latitude == null || longitude == null);
}

/// Recherche d'adresses : Google Places (si clé) puis Nominatim / géocodage natif.
class AddressSearchService {
  final Logger _logger = Logger();
  final LocationService _location = LocationService();
  final Dio _nominatim = Dio(
    BaseOptions(
      baseUrl: 'https://nominatim.openstreetmap.org',
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
      headers: {
        'User-Agent': 'FONACO-App/1.0 (contact@fonaco.app)',
        'Accept-Language': 'fr',
      },
    ),
  );
  final Dio _google = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
    ),
  );

  DateTime? _lastNominatimCall;

  String? get _googleApiKey {
    final fromEnv = dotenv.env['GOOGLE_PLACES_API_KEY'];
    if (fromEnv != null && fromEnv.trim().isNotEmpty) {
      return fromEnv.trim();
    }
    return null;
  }

  Future<List<AddressSuggestion>> search(String query) async {
    final q = query.trim();
    if (q.length < 2) return [];

    if (_googleApiKey != null) {
      final google = await _searchGooglePlaces(q);
      if (google.isNotEmpty) return google;
    }

    final nominatim = await _searchNominatim(q);
    if (nominatim.isNotEmpty) return nominatim;

    return _searchGeocoding(q);
  }

  /// Résout lat/lng et adresse formatée à partir d'un placeId Google.
  Future<AddressSuggestion?> getDetailsPlace(String placeId) async {
    final apiKey = _googleApiKey;
    if (apiKey == null || placeId.trim().isEmpty) return null;

    try {
      final response = await _google.get<Map<String, dynamic>>(
        'https://maps.googleapis.com/maps/api/place/details/json',
        queryParameters: {
          'place_id': placeId,
          'fields': 'formatted_address,geometry,name',
          'key': apiKey,
          'language': 'fr',
        },
      );
      final data = response.data;
      if (data == null) return null;
      if (data['status']?.toString() != 'OK') return null;

      final result = data['result'];
      if (result is! Map) return null;

      final geometry = result['geometry']?['location'];
      final lat = geometry is Map ? geometry['lat'] : null;
      final lng = geometry is Map ? geometry['lng'] : null;
      final latitude = lat is num ? lat.toDouble() : double.tryParse('$lat');
      final longitude = lng is num ? lng.toDouble() : double.tryParse('$lng');
      if (latitude == null || longitude == null) return null;

      final formatted = result['formatted_address']?.toString().trim();
      final name = result['name']?.toString().trim();
      final label = (formatted != null && formatted.isNotEmpty)
          ? formatted
          : (name ?? 'Adresse sélectionnée');

      return AddressSuggestion(
        label: label,
        latitude: latitude,
        longitude: longitude,
        placeId: placeId,
      );
    } catch (e, st) {
      _logger.w('Google Place Details: $e', stackTrace: st);
      return null;
    }
  }

  Future<List<AddressSuggestion>> _searchGooglePlaces(String query) async {
    final apiKey = _googleApiKey!;
    try {
      final response = await _google.get<Map<String, dynamic>>(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json',
        queryParameters: {
          'input': query,
          'key': apiKey,
          'language': 'fr',
          'components': 'country:bj',
        },
      );
      final data = response.data;
      if (data == null) return [];
      final status = data['status']?.toString();
      if (status != 'OK' && status != 'ZERO_RESULTS') {
        _logger.w('Google Autocomplete status: $status');
        return [];
      }

      final predictions = data['predictions'];
      if (predictions is! List) return [];

      return predictions.map((raw) {
        final map = Map<String, dynamic>.from(raw as Map);
        final description = map['description']?.toString() ?? query;
        final structured = map['structured_formatting'];
        String? subtitle;
        if (structured is Map) {
          subtitle = structured['secondary_text']?.toString();
        }
        return AddressSuggestion(
          label: description,
          subtitle: subtitle,
          placeId: map['place_id']?.toString(),
        );
      }).toList();
    } catch (e, st) {
      _logger.w('Google Autocomplete: $e', stackTrace: st);
      return [];
    }
  }

  Future<List<AddressSuggestion>> _searchNominatim(String query) async {
    await _respectRateLimit();

    try {
      final response = await _nominatim.get<List<dynamic>>(
        '/search',
        queryParameters: {
          'q': '$query, Bénin',
          'format': 'json',
          'addressdetails': 1,
          'limit': 8,
          'countrycodes': 'bj,tg,ci,sn,ng,gh',
        },
      );

      final rows = response.data ?? [];
      final results = <AddressSuggestion>[];

      for (final raw in rows) {
        if (raw is! Map) continue;
        final lat = double.tryParse('${raw['lat']}');
        final lon = double.tryParse('${raw['lon']}');
        if (lat == null || lon == null) continue;

        final display = raw['display_name']?.toString().trim() ?? query;
        final address = raw['address'];
        String? subtitle;
        if (address is Map) {
          subtitle = _subtitleFromNominatimAddress(address);
        }

        results.add(
          AddressSuggestion(
            label: display,
            subtitle: subtitle,
            latitude: lat,
            longitude: lon,
          ),
        );
      }

      if (results.isEmpty) {
        await _respectRateLimit();
        final fallback = await _nominatim.get<List<dynamic>>(
          '/search',
          queryParameters: {
            'q': query,
            'format': 'json',
            'addressdetails': 1,
            'limit': 6,
          },
        );
        for (final raw in fallback.data ?? []) {
          if (raw is! Map) continue;
          final lat = double.tryParse('${raw['lat']}');
          final lon = double.tryParse('${raw['lon']}');
          if (lat == null || lon == null) continue;
          results.add(
            AddressSuggestion(
              label: raw['display_name']?.toString().trim() ?? query,
              subtitle: raw['type']?.toString(),
              latitude: lat,
              longitude: lon,
            ),
          );
        }
      }

      return results;
    } catch (e) {
      _logger.w('Nominatim: $e');
      return [];
    }
  }

  Future<void> _respectRateLimit() async {
    final last = _lastNominatimCall;
    if (last != null) {
      final elapsed = DateTime.now().difference(last);
      if (elapsed.inMilliseconds < 1100) {
        await Future<void>.delayed(
          Duration(milliseconds: 1100 - elapsed.inMilliseconds),
        );
      }
    }
    _lastNominatimCall = DateTime.now();
  }

  String? _subtitleFromNominatimAddress(Map<dynamic, dynamic> address) {
    final parts = <String>[];
    void add(String key) {
      final v = address[key]?.toString().trim();
      if (v != null && v.isNotEmpty && !parts.contains(v)) {
        parts.add(v);
      }
    }

    add('suburb');
    add('neighbourhood');
    add('quarter');
    add('city');
    add('town');
    add('state');
    return parts.isEmpty ? null : parts.join(' · ');
  }

  Future<List<AddressSuggestion>> _searchGeocoding(String query) async {
    try {
      final locations = await locationFromAddress(query);
      final results = <AddressSuggestion>[];

      for (final loc in locations.take(6)) {
        try {
          final marks = await placemarkFromCoordinates(
            loc.latitude,
            loc.longitude,
          );
          final label = marks.isNotEmpty
              ? _formatPlacemark(marks.first)
              : '$query (${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)})';
          results.add(
            AddressSuggestion(
              label: label,
              latitude: loc.latitude,
              longitude: loc.longitude,
            ),
          );
        } catch (_) {
          results.add(
            AddressSuggestion(
              label: query,
              latitude: loc.latitude,
              longitude: loc.longitude,
            ),
          );
        }
      }
      return results;
    } catch (e) {
      _logger.w('Géocodage natif: $e');
      return [];
    }
  }

  Future<AddressSuggestion?> useCurrentLocation() async {
    final status = await _location.checkAndRequestLocation();
    if (status != LocationPermissionStatus.granted) return null;

    await _location.getCurrentLocation();
    final pos = _location.currentPosition;
    if (pos == null) return null;

    final address = _location.currentAddress.trim();
    return AddressSuggestion(
      label: address.isNotEmpty
          ? address
          : 'Position actuelle (${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)})',
      latitude: pos.latitude,
      longitude: pos.longitude,
    );
  }

  String _formatPlacemark(Placemark place) {
    final parts = <String>[];
    void add(String? v) {
      if (v != null && v.trim().isNotEmpty && !parts.contains(v.trim())) {
        parts.add(v.trim());
      }
    }

    add(place.street);
    add(place.subLocality);
    add(place.locality);
    add(place.administrativeArea);
    add(place.country);
    return parts.isNotEmpty ? parts.join(', ') : 'Adresse sélectionnée';
  }
}
