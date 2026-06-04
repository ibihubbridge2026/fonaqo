import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fonaco/core/utils/app_logger.dart';

/// Service pour la gestion des permissions
/// Vérifie et demande les permissions nécessaires pour l'application
class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  final AppLogger _logger = AppLogger();

  /// Vérifie toutes les permissions requises
  Future<Map<PermissionType, bool>> checkAllPermissions() async {
    final results = <PermissionType, bool>{};

    results[PermissionType.location] = await checkLocationPermission();
    results[PermissionType.camera] = await checkCameraPermission();
    results[PermissionType.microphone] = await checkMicrophonePermission();
    results[PermissionType.storage] = await checkStoragePermission();
    results[PermissionType.notification] = await checkNotificationPermission();

    _logger.i('Permissions check completed: $results');
    return results;
  }

  /// Vérifie la permission de localisation
  Future<bool> checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _logger.w('Location service is disabled');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _logger.w('Location permission denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _logger.w('Location permission denied forever');
      return false;
    }

    return true;
  }

  /// Vérifie la permission de caméra
  Future<bool> checkCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isDenied) {
      final result = await Permission.camera.request();
      return result.isGranted;
    }
    return status.isGranted;
  }

  /// Vérifie la permission de microphone
  Future<bool> checkMicrophonePermission() async {
    final status = await Permission.microphone.status;
    if (status.isDenied) {
      final result = await Permission.microphone.request();
      return result.isGranted;
    }
    return status.isGranted;
  }

  /// Vérifie la permission de stockage
  Future<bool> checkStoragePermission() async {
    final status = await Permission.storage.status;
    if (status.isDenied) {
      final result = await Permission.storage.request();
      return result.isGranted;
    }
    return status.isGranted;
  }

  /// Vérifie la permission de notification
  Future<bool> checkNotificationPermission() async {
    final status = await Permission.notification.status;
    if (status.isDenied) {
      final result = await Permission.notification.request();
      return result.isGranted;
    }
    return status.isGranted;
  }

  /// Demande toutes les permissions
  Future<Map<PermissionType, bool>> requestAllPermissions() async {
    final results = <PermissionType, bool>{};

    results[PermissionType.location] = await requestLocationPermission();
    results[PermissionType.camera] = await requestCameraPermission();
    results[PermissionType.microphone] = await requestMicrophonePermission();
    results[PermissionType.storage] = await requestStoragePermission();
    results[PermissionType.notification] =
        await requestNotificationPermission();

    _logger.i('Permissions request completed: $results');
    return results;
  }

  /// Demande la permission de localisation
  Future<bool> requestLocationPermission() async {
    final result = await Geolocator.requestPermission();
    return result == LocationPermission.always ||
        result == LocationPermission.whileInUse;
  }

  /// Demande la permission de caméra
  Future<bool> requestCameraPermission() async {
    final result = await Permission.camera.request();
    return result.isGranted;
  }

  /// Demande la permission de microphone
  Future<bool> requestMicrophonePermission() async {
    final result = await Permission.microphone.request();
    return result.isGranted;
  }

  /// Demande la permission de stockage
  Future<bool> requestStoragePermission() async {
    final result = await Permission.storage.request();
    return result.isGranted;
  }

  /// Demande la permission de notification
  Future<bool> requestNotificationPermission() async {
    final result = await Permission.notification.request();
    return result.isGranted;
  }

  /// Ouvre les paramètres de l'application
  Future<void> openAppSettings() async {
    await Permission.camera.request(); // Trigger settings if needed
  }
}

/// Types de permissions
enum PermissionType {
  location,
  camera,
  microphone,
  storage,
  notification,
}
