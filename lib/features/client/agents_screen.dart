import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fonaco/core/constants/app_constants.dart';
import 'package:fonaco/core/services/cache_service.dart';
import 'package:fonaco/core/widgets/skeleton_loading.dart';
import 'package:fonaco/features/client/missions/mission_repository.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logger/logger.dart';

class AgentsScreen extends StatefulWidget {
  const AgentsScreen({super.key});

  @override
  State<AgentsScreen> createState() => _AgentsScreenState();
}

class _AgentsScreenState extends State<AgentsScreen> {
  final Logger _log = Logger();
  final MissionRepository _missionRepository = MissionRepository();
  final CacheService _cacheService = CacheService();

  List<Map<String, dynamic>> _agents = [];

  bool _isLoadingAgents = false;
  bool _locating = false;
  bool _nearbyMode = false; // Mode "Proches de moi" désactivé par défaut
  String? _selectedExpertiseTag; // Tag d'expertise sélectionné pour filtrage
  Set<String> _favoriteAgentIds = {};

  static const Color _accent = Color(0xFFFFD400);

  final CameraPosition _initialCamera = const CameraPosition(
    target: LatLng(AppConstants.defaultLatitude, AppConstants.defaultLongitude),
    zoom: 12.8,
  );

  GoogleMapController? _mapController;
  LatLng? _currentLatLng;

  Set<Marker> _markers = <Marker>{};
  double _currentZoom = 12.8;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Charger les favoris
      _loadFavoriteAgents();
      // Charger tous les agents d'abord (sans contrainte GPS)
      await _loadAgents();
      // Initialiser la localisation en arrière-plan
      await _initLocation();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _loadFavoriteAgents() {
    if (!_cacheService.isInitialized) return;
    try {
      _cacheService.init().then((_) {
        if (mounted) {
          setState(() {
            _favoriteAgentIds = _cacheService.getFavoriteAgents().toSet();
          });
        }
      });
    } catch (e) {
      // Ignorer les erreurs
    }
  }

  void _toggleFavoriteAgent(String agentId) {
    if (!_cacheService.isInitialized) {
      _cacheService.init().then((_) {
        _cacheService.toggleFavoriteAgent(agentId);
        if (mounted) {
          setState(() {
            if (_favoriteAgentIds.contains(agentId)) {
              _favoriteAgentIds.remove(agentId);
            } else {
              _favoriteAgentIds.add(agentId);
            }
          });
        }
      });
    } else {
      _cacheService.toggleFavoriteAgent(agentId);
      setState(() {
        if (_favoriteAgentIds.contains(agentId)) {
          _favoriteAgentIds.remove(agentId);
        } else {
          _favoriteAgentIds.add(agentId);
        }
      });
    }
  }

  Future<void> _loadAgents({
    double? radiusKm,
    double? minRating,
    bool? verifiedOnly,
    List<String>? missionTypes,
    int? minPrice,
    int? maxPrice,
  }) async {
    if (!mounted) return;

    setState(() => _isLoadingAgents = true);

    try {
      // Si mode "Proches de moi" est activé et localisation disponible, utiliser les coordonnées
      // Sinon, charger tous les agents sans contrainte GPS
      final useLocation = _nearbyMode && _currentLatLng != null;

      final agents = await _missionRepository.fetchNearbyAgents(
        latitude: useLocation ? _currentLatLng!.latitude : null,
        longitude: useLocation ? _currentLatLng!.longitude : null,
        radiusKm: useLocation
            ? (radiusKm ?? AppConstants.defaultSearchRadiusKm)
            : null,
        minRating: minRating,
        verifiedOnly: verifiedOnly,
        missionTypes: missionTypes,
        minPrice: minPrice,
        maxPrice: maxPrice,
        limit: 20,
      );

      if (!mounted) return;

      // Utiliser les coordonnées actuelles ou les coordonnées par défaut
      final centerLatLng = _currentLatLng ??
          LatLng(AppConstants.defaultLatitude, AppConstants.defaultLongitude);

      setState(() {
        _agents = agents;
        _isLoadingAgents = false;
        _markers = _buildMarkersAround(centerLatLng);
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoadingAgents = false);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur lors du chargement des agents : $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Map<String, dynamic>> get _filteredAgents {
    if (_selectedExpertiseTag == null) return _agents;

    return _agents.where((agent) {
      final tags = (agent['expertise_tags'] as List<dynamic>?)
              ?.map((tag) => tag.toString())
              .toList() ??
          [];
      return tags.contains(_selectedExpertiseTag);
    }).toList();
  }

  Future<void> _initLocation() async {
    if (!mounted) return;

    setState(() => _locating = true);

    try {
      final enabled = await Geolocator.isLocationServiceEnabled();

      if (!enabled) {
        if (mounted) {
          setState(() => _locating = false);
        }
        return;
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => _locating = false);
        }
        return;
      }

      // 1. Essayer d'abord avec la dernière position connue (rapide)
      final lastKnownPosition = await Geolocator.getLastKnownPosition();
      if (lastKnownPosition != null && mounted) {
        final me =
            LatLng(lastKnownPosition.latitude, lastKnownPosition.longitude);
        setState(() {
          _currentLatLng = me;
          _markers = _buildMarkersAround(me);
          _locating = false;
        });
        await _animateTo(me);
        _log.i('📍 Position connue utilisée: ${me.latitude}, ${me.longitude}');
      }

      // 2. Obtenir la position actuelle en arrière-plan (plus précise)
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );

      if (!mounted) return;

      final me = LatLng(position.latitude, position.longitude);

      setState(() {
        _currentLatLng = me;
        _markers = _buildMarkersAround(me);
        _locating = false;
      });

      await _animateTo(me);
      _log.i('📍 Position actuelle obtenue: ${me.latitude}, ${me.longitude}');
    } catch (e, st) {
      _log.e(
        'Erreur localisation agents',
        error: e,
        stackTrace: st,
      );

      if (!mounted) return;

      final fallback = const LatLng(
        AppConstants.defaultLatitude,
        AppConstants.defaultLongitude,
      );

      setState(() {
        _currentLatLng = fallback;
        _markers = _buildMarkersAround(fallback);
        _locating = false;
      });
    }
  }

  double? _parseCoordinate(dynamic value) {
    if (value == null) return null;

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      final parsed = double.tryParse(value.trim());
      return parsed;
    }

    return null;
  }

  Set<Marker> _buildMarkersAround(LatLng center) {
    final markers = <Marker>{};

    // Position utilisateur
    markers.add(
      Marker(
        markerId: const MarkerId('user_position'),
        position: center,
        infoWindow: const InfoWindow(
          title: 'Ma position',
          snippet: 'Vous êtes ici',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueBlue,
        ),
      ),
    );

    // Clustering manuel basé sur le niveau de zoom
    final clusterRadius =
        _currentZoom < 13 ? 0.01 : 0.005; // Plus grand quand zoom éloigné
    final clusters = <List<Map<String, dynamic>>>[];

    for (final agent in _filteredAgents) {
      final lat = _parseCoordinate(agent['latitude']);
      final lng = _parseCoordinate(agent['longitude']);

      if (lat == null || lng == null) continue;
      if (lat.abs() > 90 || lng.abs() > 180) continue;

      bool addedToCluster = false;

      for (final cluster in clusters) {
        final clusterLat = _parseCoordinate(cluster.first['latitude']);
        final clusterLng = _parseCoordinate(cluster.first['longitude']);

        if (clusterLat != null && clusterLng != null) {
          final distance = _calculateDistance(lat, lng, clusterLat, clusterLng);
          if (distance < clusterRadius) {
            cluster.add(agent);
            addedToCluster = true;
            break;
          }
        }
      }

      if (!addedToCluster) {
        clusters.add([agent]);
      }
    }

    // Créer les marqueurs (clusters ou individuels)
    for (final cluster in clusters) {
      if (cluster.length > 1 && _currentZoom < 14) {
        // Créer un marqueur de cluster
        final clusterLat = _parseCoordinate(cluster.first['latitude']);
        final clusterLng = _parseCoordinate(cluster.first['longitude']);

        if (clusterLat != null && clusterLng != null) {
          markers.add(
            Marker(
              markerId: MarkerId('cluster_${cluster.first['id']}'),
              position: LatLng(clusterLat, clusterLng),
              infoWindow: InfoWindow(
                title: '${cluster.length} agents',
                snippet: 'Zoom pour voir les détails',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueOrange,
              ),
              onTap: () {
                // Zoomer sur le cluster
                _mapController?.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: LatLng(clusterLat, clusterLng),
                      zoom: _currentZoom + 2,
                    ),
                  ),
                );
              },
            ),
          );
        }
      } else {
        // Afficher les marqueurs individuels
        for (final agent in cluster) {
          final lat = _parseCoordinate(agent['latitude']);
          final lng = _parseCoordinate(agent['longitude']);

          if (lat == null || lng == null) continue;

          final name =
              '${agent['first_name'] ?? ''} ${agent['last_name'] ?? ''}'.trim();

          final specialty = agent['specialty'] ?? 'Agent terrain';

          final distance = agent['distance_km'];

          markers.add(
            Marker(
              markerId: MarkerId('agent_${agent['id']}'),
              position: LatLng(lat, lng),
              infoWindow: InfoWindow(
                title: name.isNotEmpty ? name : 'Agent',
                snippet: _formatDistance(distance).isNotEmpty
                    ? '$specialty • ${_formatDistance(distance)}'
                    : specialty,
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueYellow,
              ),
              onTap: () => _onAgentMarkerTapped(agent),
            ),
          );
        }
      }
    }

    return markers;
  }

  double _calculateDistance(
      double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371; // km
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(dLat / 2) * cos(dLat / 2) * sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * asin(sqrt(a));

    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * 3.141592653589793 / 180;
  }

  void _onAgentMarkerTapped(Map<String, dynamic> agent) {
    final name =
        '${agent['first_name'] ?? ''} ${agent['last_name'] ?? ''}'.trim();

    final specialty = agent['specialty'] ?? 'Agent terrain';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$name • $specialty'),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Voir profil',
          textColor: Colors.white,
          onPressed: () => _navigateToAgentProfile(agent),
        ),
      ),
    );
  }

  void _navigateToAgentProfile(Map<String, dynamic> agent) {
    Navigator.pushNamed(
      context,
      '/agent-profile',
      arguments: {
        'agentId': agent['id'],
        'agent': agent,
      },
    );
  }

  Future<void> _animateTo(LatLng target) async {
    final controller = _mapController;

    if (controller == null) return;

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: target,
          zoom: 14,
        ),
      ),
    );
  }

  String _getDynamicTitle() {
    return 'Agents proches';
  }

  static String _formatDistance(dynamic distance) {
    if (distance == null) return '';

    final parsed = double.tryParse(distance.toString());
    if (parsed == null) return '';

    // Hide distance if > 50km
    if (parsed > 50) return '';

    // Format to 1 decimal place
    return '${parsed.toStringAsFixed(1)} km';
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: _AgentFilterSheet(
            onApply:
                (radiusKm, minRating, verifiedOnly, types, minPrice, maxPrice) {
              Navigator.pop(context);
              _loadAgents(
                radiusKm: radiusKm,
                minRating: minRating,
                verifiedOnly: verifiedOnly,
                missionTypes: types,
                minPrice: minPrice,
                maxPrice: maxPrice,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildFloatingSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 10,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: "Rechercher un agent...",
                  border: InputBorder.none,
                  prefixIcon: Icon(
                    Icons.search,
                    color: Color(0xFFFFD400),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _showFilterSheet,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.tune_rounded,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: _initialCamera,
              myLocationEnabled: _currentLatLng != null,
              myLocationButtonEnabled: false,
              compassEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              markers: _markers,
              onMapCreated: (controller) async {
                _mapController = controller;

                final me = _currentLatLng;

                if (me != null) {
                  await _animateTo(me);
                }
              },
              onCameraMove: (CameraPosition position) {
                // Annuler le timer précédent
                _debounceTimer?.cancel();

                // Nouveau timer avec délai de 300ms
                _debounceTimer = Timer(const Duration(milliseconds: 300), () {
                  if (!mounted) return;

                  setState(() {
                    _currentZoom = position.zoom;

                    // Recalculer les markers avec le nouveau zoom
                    final centerLatLng = _currentLatLng ??
                        LatLng(AppConstants.defaultLatitude,
                            AppConstants.defaultLongitude);
                    _markers = _buildMarkersAround(centerLatLng);
                  });
                });
              },
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Column(
                children: [
                  _buildFloatingSearchBar(),
                  if (_locating)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 14,
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Localisation…',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 220,
            child: SafeArea(
              top: false,
              child: FloatingActionButton(
                heroTag: 'recenter',
                backgroundColor: Colors.white,
                elevation: 2,
                onPressed: () async {
                  final me = _currentLatLng;

                  if (me == null) {
                    await _initLocation();
                    return;
                  }

                  await _animateTo(me);
                },
                child: const Icon(
                  Icons.my_location,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Container(
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 18,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _getDynamicTitle(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                          // Interrupteur "Proches de moi"
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _nearbyMode = !_nearbyMode;
                              });
                              _loadAgents();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _nearbyMode
                                    ? const Color(0xFFFFD400)
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 16,
                                    color: _nearbyMode
                                        ? Colors.black
                                        : Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Proches de moi',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _nearbyMode
                                          ? Colors.black
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _isLoadingAgents
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: SkeletonLoading.list(itemCount: 3),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                10,
                                20,
                                20,
                              ),
                              itemCount: _filteredAgents.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final agent = _filteredAgents[index];
                                final agentId = agent['id']?.toString() ?? '';
                                return AgentListTile(
                                  agent: agent,
                                  selectedTag: _selectedExpertiseTag,
                                  onTagSelected: (tag) {
                                    setState(() {
                                      _selectedExpertiseTag = tag;
                                    });
                                  },
                                  isFavorite:
                                      _favoriteAgentIds.contains(agentId),
                                  onToggleFavorite: _toggleFavoriteAgent,
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AgentListTile extends StatelessWidget {
  final Map<String, dynamic> agent;
  final String? selectedTag;
  final Function(String?) onTagSelected;
  final bool isFavorite;
  final Function(String) onToggleFavorite;

  const AgentListTile({
    super.key,
    required this.agent,
    this.selectedTag,
    required this.onTagSelected,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  static String _formatDistance(dynamic distance) {
    if (distance == null) return '';

    final parsed = double.tryParse(distance.toString());
    if (parsed == null) return '';

    // Hide distance if > 50km
    if (parsed > 50) return '';

    // Format to 1 decimal place
    return '${parsed.toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    final name =
        '${agent['first_name'] ?? ''} ${agent['last_name'] ?? ''}'.trim();

    final specialty = agent['specialty'] ?? 'Agent terrain';

    final city = agent['city'] ?? 'Non spécifié';

    final distance = agent['distance_km'];

    final reliability = (agent['reliability_score'] ?? 100).toDouble();

    final isVerified = agent['is_verified'] ?? false;

    final avatarUrl = agent['avatar_url'];

    // Extraire les tags d'expertise
    final expertiseTags = (agent['expertise_tags'] as List<dynamic>?)
            ?.map((tag) => tag.toString())
            .toList() ??
        [];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.blue[100],
                backgroundImage: avatarUrl != null
                    ? CachedNetworkImageProvider(avatarUrl) as ImageProvider
                    : null,
                child: avatarUrl == null
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'A',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              if (isVerified)
                const CircleAvatar(
                  radius: 10,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.verified,
                    color: Colors.blue,
                    size: 14,
                  ),
                ),
              // Icône favoris
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => onToggleFavorite(agent['id']?.toString() ?? ''),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.grey,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isNotEmpty ? name : 'Agent',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  specialty,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                // Tags d'expertise
                if (expertiseTags.isNotEmpty)
                  Wrap(
                    spacing: 4,
                    runSpacing: 2,
                    children: expertiseTags.take(3).map((tag) {
                      final isSelected = selectedTag == tag;
                      return GestureDetector(
                        onTap: () {
                          onTagSelected(isSelected ? null : tag);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFFFD400)
                                : const Color(0xFFFFD400)
                                    .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: isSelected
                                ? Border.all(
                                    color: const Color(0xFFFFD400), width: 1)
                                : null,
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.black
                                  : const Color(0xFF715D00),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      size: 14,
                      color: Colors.orange[700],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${reliability.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.location_on,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        _formatDistance(distance).isNotEmpty
                            ? _formatDistance(distance)
                            : city,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 85,
                height: 32,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Profil agent bientôt disponible',
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Profil',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 85,
                height: 32,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/chat-detail',
                      arguments: {
                        'chatId': 'chat_${agent['id']}',
                        'userName': name.isNotEmpty ? name : 'Agent',
                        'missionId': null,
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD400),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Contacter',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AgentFilterSheet extends StatefulWidget {
  final Function(double radiusKm, double minRating, bool verifiedOnly,
      List<String> types, int minPrice, int maxPrice) onApply;

  const _AgentFilterSheet({required this.onApply});

  @override
  State<_AgentFilterSheet> createState() => _AgentFilterSheetState();
}

class _AgentFilterSheetState extends State<_AgentFilterSheet> {
  static const _accent = Color(0xFFFFD400);

  RangeValues _price = const RangeValues(2000, 15000);

  double _radiusKm = 10;

  double _minRating = 4.0;

  bool _verifiedOnly = true;

  final Set<String> _types = {'File d’attente'};

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(30),
        ),
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Filtres',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _price = const RangeValues(2000, 15000);
                            _radiusKm = 10;
                            _minRating = 4.0;
                            _verifiedOnly = true;

                            _types
                              ..clear()
                              ..add('File d’attente');
                          });
                        },
                        child: const Text(
                          'Réinitialiser',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Prix (${_price.start.toStringAsFixed(0)} - ${_price.end.toStringAsFixed(0)} CFA)',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  RangeSlider(
                    values: _price,
                    min: 0,
                    max: 50000,
                    divisions: 100,
                    activeColor: _accent,
                    onChanged: (value) {
                      setState(() => _price = value);
                    },
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Type de mission',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _typeChip('File d’attente'),
                      _typeChip('Service libre'),
                      _typeChip('Achat ticket'),
                      _typeChip('Livraison'),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Rayon (${_radiusKm.toStringAsFixed(0)} km)',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Slider(
                    value: _radiusKm,
                    min: 1,
                    max: 50,
                    divisions: 49,
                    activeColor: _accent,
                    onChanged: (value) {
                      setState(() => _radiusKm = value);
                    },
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Note minimale (${_minRating.toStringAsFixed(1)})',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Slider(
                    value: _minRating,
                    min: 1,
                    max: 5,
                    divisions: 40,
                    activeColor: _accent,
                    onChanged: (value) {
                      setState(() => _minRating = value);
                    },
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                    child: SwitchListTile(
                      value: _verifiedOnly,
                      activeThumbColor: _accent,
                      onChanged: (value) {
                        setState(() => _verifiedOnly = value);
                      },
                      title: const Text(
                        'Agents vérifiés uniquement',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      subtitle: const Text(
                        'Filtrer les profils certifiés',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(
                  _radiusKm,
                  _minRating,
                  _verifiedOnly,
                  _types.toList(),
                  _price.start.toInt(),
                  _price.end.toInt(),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'APPLIQUER',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeChip(String label) {
    final selected = _types.contains(label);

    return FilterChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      backgroundColor: Colors.grey[100],
      selectedColor: _accent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      labelStyle: TextStyle(
        color: selected ? Colors.black : Colors.grey[700],
        fontWeight: FontWeight.bold,
      ),
      onSelected: (_) {
        setState(() {
          if (selected) {
            _types.remove(label);
          } else {
            _types.add(label);
          }
        });
      },
    );
  }
}
