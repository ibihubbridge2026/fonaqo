import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
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

  Future<void> getCurrentLocation() async {
    if (_isLoading) return;

    _isLoading = true;

    try {
      bool hasPermission = await checkLocationPermission();
      if (!hasPermission) {
        _isLoading = false;
        return;
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      await _getAddressFromLatLng(_currentPosition!);
    } catch (e) {
      print('Erreur lors de l\'obtention de la localisation: $e');
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
    } catch (e) {
      print('Erreur lors du geocoding: $e');
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
