import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logger/logger.dart';

import '../missions/mission_repository.dart';

class AgentsScreen extends StatefulWidget {
  const AgentsScreen({super.key});

  @override
  State<AgentsScreen> createState() => _AgentsScreenState();
}

class _AgentsScreenState extends State<AgentsScreen> {
  final Logger _log = Logger();
  final MissionRepository _missionRepository = MissionRepository();

  List<Map<String, dynamic>> _agents = [];

  bool _isLoadingAgents = false;
  bool _locating = false;

  static const Color _accent = Color(0xFFFFD400);

  String _selectedFilter = 'Tous';

  final List<String> _filterOptions = [
    'Tous',
    'Vérifiés',
    'À proximité',
    'Disponibles',
  ];

  final CameraPosition _initialCamera = const CameraPosition(
    target: LatLng(5.3363, -4.0260),
    zoom: 12.8,
  );

  GoogleMapController? _mapController;
  LatLng? _currentLatLng;

  Set<Marker> _markers = <Marker>{};

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initLocation();
      await _loadAgents();
    });
  }

  Future<void> _loadAgents() async {
    if (!mounted) return;

    setState(() => _isLoadingAgents = true);

    try {
      final agents = await _missionRepository.fetchAgentSuggestions(
        latitude: _currentLatLng?.latitude,
        longitude: _currentLatLng?.longitude,
      );

      if (!mounted) return;

      setState(() {
        _agents = agents;
        _isLoadingAgents = false;
      });

      if (_currentLatLng != null) {
        setState(() {
          _markers = _buildMarkersAround(_currentLatLng!);
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoadingAgents = false);

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
    switch (_selectedFilter) {
      case 'Vérifiés':
        return _agents
            .where((agent) => agent['is_verified'] == true)
            .toList();

      case 'À proximité':
        return _agents.where((agent) {
          final distance = agent['distance_km'];

          if (distance == null) return false;

          final parsed = double.tryParse(distance.toString());

          return parsed != null && parsed < 10;
        }).toList();

      case 'Disponibles':
        return _agents
            .where((agent) => agent['is_available'] == true)
            .toList();

      case 'Tous':
      default:
        return _agents;
    }
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
    } catch (e, st) {
      _log.e(
        'Erreur localisation agents',
        error: e,
        stackTrace: st,
      );

      if (!mounted) return;

      final fallback = const LatLng(5.3600, -4.0083);

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

    for (final agent in _filteredAgents) {
      final lat = _parseCoordinate(agent['latitude']);
      final lng = _parseCoordinate(agent['longitude']);

      if (lat == null || lng == null) continue;

      if (lat.abs() > 90 || lng.abs() > 180) continue;

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
            snippet: distance != null
                ? '$specialty • ${distance} km'
                : specialty,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            agent['is_verified'] == true
                ? BitmapDescriptor.hueYellow
                : BitmapDescriptor.hueOrange,
          ),
          onTap: () => _onAgentMarkerTapped(agent),
        ),
      );
    }

    return markers;
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
          child: const SingleChildScrollView(
            child: _AgentFilterSheet(),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                  ),
                ],
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
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Agents proches',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                          DropdownButton<String>(
                            value: _selectedFilter,
                            underline: const SizedBox(),
                            items: _filterOptions.map((filter) {
                              return DropdownMenuItem(
                                value: filter,
                                child: Text(filter),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value == null) return;

                              setState(() {
                                _selectedFilter = value;

                                if (_currentLatLng != null) {
                                  _markers = _buildMarkersAround(
                                    _currentLatLng!,
                                  );
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: _isLoadingAgents
                          ? const Center(
                              child: CircularProgressIndicator(),
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
                                return AgentListTile(
                                  agent: _filteredAgents[index],
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

  const AgentListTile({
    super.key,
    required this.agent,
  });

  @override
  Widget build(BuildContext context) {
    final name =
        '${agent['first_name'] ?? ''} ${agent['last_name'] ?? ''}'.trim();

    final specialty = agent['specialty'] ?? 'Agent terrain';

    final city = agent['city'] ?? 'Non spécifié';

    final distance = agent['distance_km'];

    final reliability =
        (agent['reliability_score'] ?? 100).toDouble();

    final isVerified = agent['is_verified'] ?? false;

    final avatarUrl = agent['avatar_url'];

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
                backgroundImage:
                    avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null
                    ? Text(
                        name.isNotEmpty
                            ? name[0].toUpperCase()
                            : 'A',
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
                        distance != null
                            ? '$distance km'
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
                        'userName':
                            name.isNotEmpty ? name : 'Agent',
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
  const _AgentFilterSheet();

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
                crossAxisAlignment:
                    CrossAxisAlignment.start,
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
                            _price =
                                const RangeValues(2000, 15000);
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
              onPressed: () => Navigator.pop(context),
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