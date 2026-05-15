import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:app_settings/app_settings.dart';

class LocationSettingsScreen extends StatefulWidget {
  const LocationSettingsScreen({super.key});

  @override
  State<LocationSettingsScreen> createState() => _LocationSettingsScreenState();
}

class _LocationSettingsScreenState extends State<LocationSettingsScreen> {
  final Logger _log = Logger();
  Position? _currentPosition;
  bool _isLoading = false;
  bool _isPermissionDenied = false;
  String _errorMessage = '';
  String _currentAddress = '';
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _checkLocationPermissionAndGetLocation();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkLocationPermissionAndGetLocation() async {
    setState(() {
      _isLoading = true;
      _isPermissionDenied = false;
      _errorMessage = '';
    });

    try {
      // Vérifier les permissions de localisation
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        // Demander la permission
        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          setState(() {
            _isPermissionDenied = true;
            _isLoading = false;
            _errorMessage =
                'La permission de localisation est requise pour utiliser cette fonctionnalité.';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isPermissionDenied = true;
          _isLoading = false;
          _errorMessage =
              'La permission de localisation a été refusée. Veuillez l\'activer dans les paramètres.';
        });
        return;
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        // Obtenir la position actuelle
        await _getCurrentLocation();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Erreur lors de l\'obtention de la localisation: ${e.toString()}';
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });

      // Obtenir l'adresse avec debounce
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        _getAddressFromLatLng(position);
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Impossible d\'obtenir votre position: ${e.toString()}';
      });
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
        String address = _formatAddress(place);

        if (mounted) {
          setState(() {
            _currentAddress = address;
          });
        }
      }
    } catch (e, st) {
      _log.e('Géocodage paramètres lieu', error: e, stackTrace: st);
    }
  }

  String _formatAddress(Placemark place) {
    // Construire une adresse lisible: Quartier, Ville, Pays
    List<String> parts = [];

    if (place.subLocality?.isNotEmpty == true) {
      parts.add(place.subLocality!);
    } else if (place.locality?.isNotEmpty == true) {
      parts.add(place.locality!);
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

  Future<void> _refreshLocation() async {
    await _checkLocationPermissionAndGetLocation();
  }

  Future<void> _openAppSettings() async {
    await AppSettings.openAppSettings(type: AppSettingsType.location);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ma Localisation',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carte de position
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Position Actuelle',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (_isLoading)
                      const Column(
                        children: [
                          CircularProgressIndicator(color: Color(0xFFFFD400)),
                          SizedBox(height: 16),
                          Text(
                            'Détermination de votre position...',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      )
                    else if (_isPermissionDenied)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.location_off,
                            size: 48,
                            color: Colors.red[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage,
                            style: TextStyle(
                              color: Colors.red[600],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _openAppSettings,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[600],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Ouvrir les paramètres'),
                            ),
                          ),
                        ],
                      )
                    else if (_errorMessage.isNotEmpty &&
                        _currentPosition == null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.orange[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage,
                            style: TextStyle(
                              color: Colors.orange[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      )
                    else if (_currentPosition != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // CARTE INTERACTIVE (250px de haut)
                          SizedBox(
                            height: 250,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: FlutterMap(
                                options: MapOptions(
                                  initialCenter: LatLng(
                                    _currentPosition!.latitude,
                                    _currentPosition!.longitude,
                                  ),
                                  initialZoom: 15.0,
                                  minZoom: 10.0,
                                  maxZoom: 18.0,
                                  interactionOptions: const InteractionOptions(
                                    flags: InteractiveFlag.all,
                                  ),
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate:
                                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName: 'com.example.fonaco',
                                  ),
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: LatLng(
                                          _currentPosition!.latitude,
                                          _currentPosition!.longitude,
                                        ),
                                        width: 40,
                                        height: 40,
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            color: Colors.black,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.location_history,
                                            color: Color(0xFFFFD400),
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Icon(
                            Icons.location_on,
                            size: 48,
                            color: Color(0xFFFFD400),
                          ),
                          const SizedBox(height: 16),
                          // Adresse lisible (principal)
                          Text(
                            _currentAddress.isNotEmpty
                                ? _currentAddress
                                : 'Détermination de l\'adresse...',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Coordonnées techniques (petit)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '📍 ${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '🎯 Précision: ±${_currentPosition!.accuracy.toStringAsFixed(0)}m',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    else
                      const Text(
                        'Position non disponible',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Bouton de rafraîchissement
            if (!_isPermissionDenied)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _refreshLocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD400),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.refresh),
                      const SizedBox(width: 8),
                      Text(
                        _isLoading
                            ? 'Actualisation...'
                            : 'Rafraîchir ma position',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // if (_isPermissionDenied) const SizedBox(height: 20),
            SizedBox(height: 20),

            // Informations supplémentaires
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Color(0xFFFFD400),
                      size: 24,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Pourquoi la localisation ?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'FONACO utilise votre position pour vous proposer des agents proches de vous et améliorer votre expérience.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
