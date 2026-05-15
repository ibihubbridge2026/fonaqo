import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';
import 'package:logger/logger.dart';
import 'dart:async';

/// Énumération pour les différents états de permission de localisation
enum LocationPermissionStatus {
  /// La permission est accordée
  granted,

  /// La permission est refusée
  denied,

  /// La permission est refusée définitivement (nécessite intervention manuelle)
  deniedForever,

  /// Les services de localisation sont désactivés
  serviceDisabled,

  /// Une erreur s'est produite
  error,
}

class LocationService {
  final Logger _logger = Logger();
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Position? _currentPosition;
  String _currentAddress = '';
  bool _isLoading = false;

  Position? get currentPosition => _currentPosition;
  String get currentAddress => _currentAddress;
  bool get isLoading => _isLoading;

  Future<bool> checkLocationPermission() async {
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

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Vérifie si les services de localisation sont activés et demande les permissions si nécessaire
  /// Retourne true si la localisation est disponible, false sinon
  Future<LocationPermissionStatus> checkAndRequestLocation() async {
    try {
      // 1. Vérifier si les services de localisation sont activés
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _logger.w('Services de localisation désactivés');
        return LocationPermissionStatus.serviceDisabled;
      }

      // 2. Vérifier les permissions actuelles
      LocationPermission permission = await Geolocator.checkPermission();

      // 3. Demander la permission si elle n'est pas accordée
      if (permission == LocationPermission.denied) {
        _logger.d('Permission de localisation refusée, demande en cours...');
        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          _logger.w('Permission de localisation refusée par l\'utilisateur');
          return LocationPermissionStatus.denied;
        }
      }

      // 4. Gérer le cas où la permission est refusée définitivement
      if (permission == LocationPermission.deniedForever) {
        _logger.w('Permission de localisation refusée définitivement');
        return LocationPermissionStatus.deniedForever;
      }

      // 5. Vérifier si nous avons les permissions nécessaires
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        _logger.d('Permission de localisation accordée: $permission');
        return LocationPermissionStatus.granted;
      }

      return LocationPermissionStatus.denied;
    } catch (e, st) {
      _logger.e('Erreur lors de la vérification de la localisation',
          error: e, stackTrace: st);
      return LocationPermissionStatus.error;
    }
  }

  /// Ouvre les paramètres de l'application pour que l'utilisateur puisse activer la localisation
  Future<void> openAppSettings() async {
    try {
      await AppSettings.openAppSettings(type: AppSettingsType.settings);
    } catch (e) {
      _logger.e('Erreur lors de l\'ouverture des paramètres: $e');
    }
  }

  Future<void> getCurrentLocation() async {
    if (_isLoading) return;

    _isLoading = true;

    try {
      // Vérification que le service de localisation est activé
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _logger.w('Service de localisation désactivé');
        _isLoading = false;
        return;
      }

      bool hasPermission = await checkLocationPermission();
      if (!hasPermission) {
        _isLoading = false;
        return;
      }

      // Tentative de récupération de la position actuelle avec timeout augmenté
      try {
        _currentPosition = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw TimeoutException(
              'GPS timeout après 30s', const Duration(seconds: 30)),
        );
      } catch (e) {
        _logger.w(
            'Échec getCurrentPosition, tentative avec getLastKnownPosition: $e');

        // Fallback sur la dernière position connue
        _currentPosition = await Geolocator.getLastKnownPosition();

        if (_currentPosition == null) {
          _logger.e('Aucune position disponible');
          _isLoading = false;
          return;
        }
      }

      await _getAddressFromLatLng(_currentPosition!);
    } catch (e, st) {
      _logger.e('Localisation', error: e, stackTrace: st);
    } finally {
      _isLoading = false;
    }
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        _currentAddress = _formatAddress(place);
      }
    } catch (e, st) {
      _logger.e('Géocodage', error: e, stackTrace: st);
      _currentAddress = 'Adresse inconnue';
    }
  }

  String _formatAddress(Placemark place) {
    List<String> parts = [];

    if (place.street?.isNotEmpty == true) {
      parts.add(place.street!);
    }

    if (place.subLocality?.isNotEmpty == true) {
      parts.add(place.subLocality!);
    }

    if (place.locality?.isNotEmpty == true &&
        !parts.contains(place.locality!)) {
      parts.add(place.locality!);
    }

    if (place.country?.isNotEmpty == true) {
      parts.add(place.country!);
    }

    return parts.isNotEmpty ? parts.join(', ') : 'Adresse inconnue';
  }

  void clearLocation() {
    _currentPosition = null;
    _currentAddress = '';
  }
}
