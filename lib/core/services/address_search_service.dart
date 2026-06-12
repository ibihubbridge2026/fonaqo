import 'package:dio/dio.dart';
import 'package:geocoding/geocoding.dart';
import 'package:logger/logger.dart';

import 'location_service.dart';

class AddressSuggestion {
  final String label;
  final String? subtitle;
  final double latitude;
  final double longitude;

  const AddressSuggestion({
    required this.label,
    this.subtitle,
    required this.latitude,
    required this.longitude,
  });
}

/// Recherche d'adresses via Nominatim (OSM) avec repli géocodage natif.
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

  DateTime? _lastNominatimCall;

  Future<List<AddressSuggestion>> search(String query) async {
    final q = query.trim();
    if (q.length < 2) return [];

    final nominatim = await _searchNominatim(q);
    if (nominatim.isNotEmpty) return nominatim;

    return _searchGeocoding(q);
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
