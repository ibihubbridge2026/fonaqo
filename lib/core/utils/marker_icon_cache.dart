import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Cache singleton pour les BitmapDescriptor utilisés dans les markers.
/// Évite la recréation répétée des mêmes icônes de marker.
class MarkerIconCache {
  static final MarkerIconCache _instance = MarkerIconCache._internal();
  factory MarkerIconCache() => _instance;
  MarkerIconCache._internal();

  BitmapDescriptor? _userMarker;
  BitmapDescriptor? _agentMarker;
  BitmapDescriptor? _clusterMarker;
  BitmapDescriptor? _missionMarker;
  BitmapDescriptor? _agentOnRouteMarker;

  /// Marker pour la position utilisateur (bleu)
  BitmapDescriptor get userMarker {
    _userMarker ??= BitmapDescriptor.defaultMarkerWithHue(
      BitmapDescriptor.hueBlue,
    );
    return _userMarker!;
  }

  /// Marker pour un agent individuel (vert)
  BitmapDescriptor get agentMarker {
    _agentMarker ??= BitmapDescriptor.defaultMarkerWithHue(
      BitmapDescriptor.hueGreen,
    );
    return _agentMarker!;
  }

  /// Marker pour un cluster d'agents (orange)
  BitmapDescriptor get clusterMarker {
    _clusterMarker ??= BitmapDescriptor.defaultMarkerWithHue(
      BitmapDescriptor.hueOrange,
    );
    return _clusterMarker!;
  }

  /// Marker pour une mission (bleu)
  BitmapDescriptor get missionMarker {
    _missionMarker ??= BitmapDescriptor.defaultMarkerWithHue(
      BitmapDescriptor.hueBlue,
    );
    return _missionMarker!;
  }

  /// Marker pour un agent en route (vert)
  BitmapDescriptor get agentOnRouteMarker {
    _agentOnRouteMarker ??= BitmapDescriptor.defaultMarkerWithHue(
      BitmapDescriptor.hueGreen,
    );
    return _agentOnRouteMarker!;
  }

  /// Réinitialiser le cache (utile pour les tests)
  void reset() {
    _userMarker = null;
    _agentMarker = null;
    _clusterMarker = null;
    _missionMarker = null;
    _agentOnRouteMarker = null;
  }
}
