import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:fonaco/core/utils/app_logger.dart';
import 'package:fonaco/core/api/base_client.dart';

/// Service de tracking GPS optimisé pour les missions
/// Envoie la position seulement :
/// - Toutes les 10 secondes
/// - OU si déplacement > 30 mètres
/// Réduit la consommation de batterie et le trafic réseau
class OptimizedLocationService {
  static final OptimizedLocationService _instance =
      OptimizedLocationService._internal();
  factory OptimizedLocationService() => _instance;
  OptimizedLocationService._internal();

  final AppLogger _logger = AppLogger();
  final BaseClient _api = BaseClient();

  // Configuration
  static const Duration _locationUpdateInterval = Duration(seconds: 10);
  static const double _distanceFilterMeters = 30.0;
  static const LocationAccuracy _accuracy = LocationAccuracy.high;

  // État
  bool _isTracking = false;
  StreamSubscription<Position>? _positionSubscription;
  Timer? _uploadTimer;

  // Dernière position connue
  Position? _lastPosition;
  DateTime? _lastUploadTime;

  // Mission actuelle
  String? _currentMissionId;

  // Callbacks
  final StreamController<LocationUpdate> _locationController =
      StreamController.broadcast();
  Stream<LocationUpdate> get locationUpdates => _locationController.stream;

  /// Démarre le tracking pour une mission
  Future<bool> startTracking(String missionId) async {
    if (_isTracking) {
      _logger.w('Tracking already in progress for mission $_currentMissionId');
      return false;
    }

    try {
      // Vérifier les permissions
      final hasPermission = await _checkPermissions();
      if (!hasPermission) {
        _logger.w('Location permission denied');
        return false;
      }

      // Vérifier si le GPS est activé
      final isLocationEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isLocationEnabled) {
        _logger.w('Location service is disabled');
        return false;
      }

      _currentMissionId = missionId;
      _isTracking = true;
      _lastUploadTime = DateTime.now();

      // Configurer les options de localisation
      final locationSettings = AndroidSettings(
        accuracy: _accuracy,
        distanceFilter: _distanceFilterMeters.toInt(),
        forceLocationManager: false,
        intervalDuration: _locationUpdateInterval,
      );

      // Démarrer le stream de position
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        _onPositionUpdate,
        onError: _onLocationError,
      );

      // Démarrer le timer d'upload périodique (backup)
      _uploadTimer = Timer.periodic(_locationUpdateInterval, (_) {
        _uploadCurrentPosition();
      });

      _logger.i('Started tracking for mission $missionId');
      return true;
    } catch (e) {
      _logger.e('Error starting tracking: $e');
      return false;
    }
  }

  /// Arrête le tracking
  void stopTracking() {
    if (!_isTracking) return;

    _positionSubscription?.cancel();
    _uploadTimer?.cancel();
    _isTracking = false;
    _currentMissionId = null;
    _lastPosition = null;
    _lastUploadTime = null;

    _logger.i('Stopped tracking');
  }

  /// Gère les mises à jour de position
  void _onPositionUpdate(Position position) {
    _lastPosition = position;

    // Vérifier si on doit uploader (distance > 30m OU temps > 10s)
    final shouldUpload = _shouldUploadPosition(position);

    if (shouldUpload) {
      _uploadPosition(position);
    }

    // Émettre l'événement de mise à jour locale
    _locationController.add(LocationUpdate(
      position: position,
      missionId: _currentMissionId!,
      timestamp: DateTime.now(),
    ));
  }

  /// Détermine si la position doit être uploadée
  bool _shouldUploadPosition(Position position) {
    if (_lastPosition == null) return true;

    // Vérifier le temps écoulé
    final timeSinceLastUpload = DateTime.now().difference(_lastUploadTime!);
    if (timeSinceLastUpload >= _locationUpdateInterval) {
      return true;
    }

    // Vérifier la distance
    final distance = Geolocator.distanceBetween(
      _lastPosition!.latitude,
      _lastPosition!.longitude,
      position.latitude,
      position.longitude,
    );

    return distance >= _distanceFilterMeters;
  }

  /// Upload la position vers le serveur
  Future<void> _uploadPosition(Position position) async {
    if (_currentMissionId == null) return;

    try {
      final response = await _api.post(
        '/missions/$_currentMissionId/location/',
        data: {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
          'altitude': position.altitude,
          'speed': position.speed,
          'heading': position.heading,
          'timestamp': position.timestamp.toIso8601String(),
        },
      );

      if (response.statusCode == 200) {
        _lastUploadTime = DateTime.now();
        _logger.d('Position uploaded for mission $_currentMissionId');
      }
    } catch (e) {
      _logger.e('Error uploading position: $e');
    }
  }

  /// Upload la position actuelle (backup timer)
  void _uploadCurrentPosition() {
    if (_lastPosition != null) {
      _uploadPosition(_lastPosition!);
    }
  }

  /// Gère les erreurs de localisation
  void _onLocationError(error) {
    _logger.e('Location error: $error');
  }

  /// Vérifie les permissions de localisation
  Future<bool> _checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Obtient la position actuelle (one-shot)
  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await _checkPermissions();
      if (!hasPermission) return null;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: _accuracy,
      );

      return position;
    } catch (e) {
      _logger.e('Error getting current position: $e');
      return null;
    }
  }

  /// Calcule la distance entre deux positions
  static double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  /// Nettoyage
  void dispose() {
    stopTracking();
    _locationController.close();
  }

  // Getters
  bool get isTracking => _isTracking;
  String? get currentMissionId => _currentMissionId;
  Position? get lastPosition => _lastPosition;
}

/// Mise à jour de localisation
class LocationUpdate {
  final Position position;
  final String missionId;
  final DateTime timestamp;

  LocationUpdate({
    required this.position,
    required this.missionId,
    required this.timestamp,
  });
}
