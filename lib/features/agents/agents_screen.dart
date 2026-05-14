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

  static const Color _accent = Color(0xFFFFD400);
  String _selectedFilter = 'Tous';
  final List<String> _filterOptions = [
    'Tous',
    'Vérifiés',
    'À proximité',
    'Disponibles'
  ];

  final CameraPosition _initialCamera = const CameraPosition(
    target: LatLng(5.3363, -4.0260), // Abidjan (approx.)
    zoom: 12.8,
  );

  GoogleMapController? _mapController;
  LatLng? _currentLatLng;
  bool _locating = false;

  Set<Marker> _markers = const <Marker>{};

  @override
  void initState() {
    super.initState();
    // Attendre que l'UI soit prête avant de demander la position
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initLocation();
      _loadAgents();
    });
  }

  Future<void> _loadAgents() async {
    if (!mounted) return;

    setState(() => _isLoadingAgents = true);

    try {
<<<<<<< HEAD
      // Récupérer les agents depuis l'API
      final agents = await _missionRepository.fetchAgentSuggestions();
=======
      // Récupérer les coordonnées utilisateur pour le filtrage par distance
      final agents = await _missionRepository.fetchAgentSuggestions(
        latitude: _currentLatLng?.latitude,
        longitude: _currentLatLng?.longitude,
      );
>>>>>>> baf250f (mmisse a jour ddu gradle)
      if (mounted) {
        setState(() {
          _agents = agents;
          _isLoadingAgents = false;
        });
        // Mettre à jour les marqueurs après le chargement
        if (_currentLatLng != null) {
          _markers = _buildMarkersAround(_currentLatLng!);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingAgents = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur lors du chargement des agents: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredAgents {
    switch (_selectedFilter) {
      case 'Vérifiés':
        return _agents.where((agent) => agent['is_verified'] == true).toList();
      case 'À proximité':
        return _agents
            .where((agent) =>
                agent['distance_km'] != null && agent['distance_km'] < 10)
            .toList();
      case 'Disponibles':
        return _agents.where((agent) => agent['is_available'] == true).toList();
      case 'Toutes':
      default:
        return _agents;
    }
  }

  Future<void> _initLocation() async {
    if (!mounted) return;

    setState(() => _locating = true);

    try {
      // Vérifier si le service de localisation est activé
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        if (mounted) setState(() => _locating = false);
        return;
      }

      // Vérifier les permissions
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _locating = false);
        return;
      }

      // Obtenir la position actuelle avec timeout
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy
            .medium, // Réduire la précision pour éviter les timeouts
        timeLimit: const Duration(seconds: 15), // Timeout explicite
      );

      if (!mounted) return;

      final me = LatLng(pos.latitude, pos.longitude);
      _currentLatLng = me;
      _markers = _buildMarkersAround(me);

      if (mounted) setState(() => _locating = false);

      // Si la map est déjà prête, on centre immédiatement.
      if (mounted) await _animateTo(me);
    } catch (e, st) {
      _log.e('Localisation agents', error: e, stackTrace: st);

      // Définir une position par défaut (Abidjan) en cas d'erreur
      if (mounted) {
        _currentLatLng = const LatLng(5.3600, -4.0083); // Coordonnées d'Abidjan
        _markers = _buildMarkersAround(_currentLatLng!);
        setState(() => _locating = false);
      }
    }
  }

  /// Parse les coordonnées GPS de manière robuste
  double? _parseCoordinate(dynamic value) {
    if (value == null) return null;

    // Si c'est déjà un nombre
    if (value is num) return value.toDouble();

    // Si c'est une chaîne, essayer de la parser
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;

      // Parser en double
      final parsed = double.tryParse(trimmed);
      return parsed;
    }

    return null;
  }

  Set<Marker> _buildMarkersAround(LatLng center) {
    final markers = <Marker>[];
    final agentsToShow = _filteredAgents;

<<<<<<< HEAD
    // Ajouter le marqueur bleu pour la position de l'utilisateur
    markers.add(
      Marker(
        markerId: const MarkerId('user_position'),
        position: center,
        infoWindow: const InfoWindow(
          title: 'Ma position',
          snippet: 'Vous êtes ici',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );

    // Créer des marqueurs pour les agents disponibles
    for (var i = 0; i < agentsToShow.length; i++) {
      final agent = agentsToShow[i];

      // Vérifier si l'agent a des coordonnées avec parsing robuste
      final latValue = agent['latitude'];
      final lngValue = agent['longitude'];

      if (latValue != null && lngValue != null) {
        final agentLat = _parseCoordinate(latValue);
        final agentLng = _parseCoordinate(lngValue);

        if (agentLat != null &&
            agentLng != null &&
            agentLat.abs() <= 90 &&
            agentLng.abs() <= 180) {
          // Validation des coordonnées
=======
    // Créer des marqueurs pour les agents disponibles
    for (var i = 0; i < _agents.length; i++) {
      final agent = _agents[i];

      // Vérifier si l'agent a des coordonnées
      if (agent['latitude'] != null && agent['longitude'] != null) {
        final agentLat = double.tryParse(agent['latitude'].toString());
        final agentLng = double.tryParse(agent['longitude'].toString());

        if (agentLat != null && agentLng != null) {
>>>>>>> baf250f (mmisse a jour ddu gradle)
          final agentLatLng = LatLng(agentLat, agentLng);
          final name =
              '${agent['first_name'] ?? ''} ${agent['last_name'] ?? ''}'.trim();
          final specialty = agent['specialty'] ?? 'Agent terrain';
          final distance = agent['distance_km'];

          markers.add(
            Marker(
              markerId: MarkerId('agent_${agent['id']}'),
              position: agentLatLng,
              infoWindow: InfoWindow(
                title: name.isNotEmpty ? name : 'Agent',
                snippet:
                    '$specialty${distance != null ? ' • ${distance} km' : ''}',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                agent['is_verified'] == true
<<<<<<< HEAD
                    ? BitmapDescriptor.hueYellow
                    : BitmapDescriptor.hueOrange,
              ),
              onTap: () {
                // Mettre à jour la liste pour sélectionner l'agent correspondant
                _onAgentMarkerTapped(agent);
              },
=======
                    ? BitmapDescriptor.hueGreen
                    : BitmapDescriptor.hueOrange,
              ),
>>>>>>> baf250f (mmisse a jour ddu gradle)
            ),
          );
        }
      }
    }

    return markers.toSet();
  }

  void _onAgentMarkerTapped(Map<String, dynamic> agent) {
    final name =
        '${agent['first_name'] ?? ''} ${agent['last_name'] ?? ''}'.trim();
    final specialty = agent['specialty'] ?? 'Agent terrain';

    // Afficher un message de confirmation avec bouton d'action
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$name • $specialty'),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Voir profil',
          textColor: Colors.white,
          onPressed: () {
            _navigateToAgentProfile(agent);
          },
        ),
      ),
    );
  }

  void _navigateToAgentProfile(Map<String, dynamic> agent) {
    // Navigation vers le profil de l'agent
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
      CameraUpdate.newCameraPosition(CameraPosition(target: target, zoom: 14)),
    );
  }

  // --- FONCTION POUR LE FILTRE (Image ec4474) ---
  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: const SingleChildScrollView(child: _AgentFilterSheet()),
        );
      },
    );
  }

  // --- BARRE DE RECHERCHE FLOTTANTE ---
  Widget _buildFloatingSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10),
                ],
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: "Rechercher un agent (lieu, service...)",
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search, color: Color(0xFFFFD400)),
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
                  BoxShadow(color: Colors.black12, blurRadius: 5),
                ],
              ),
              child: const Icon(Icons.tune_rounded, color: Colors.black),
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
          // Map toujours visible en fond
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: _initialCamera,
              myLocationButtonEnabled: false,
              myLocationEnabled: _currentLatLng != null,
              compassEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              markers: _markers,
              onMapCreated: (c) async {
                _mapController = c;
                final me = _currentLatLng;
                if (me != null) {
                  await _animateTo(me);
                }
              },
            ),
          ),

          // Barre de recherche et filtres toujours visibles en haut
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
                          horizontal: 20, vertical: 8),
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
                              color: Colors.black.withOpacity(0.08),
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
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Localisation…',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      ),
                    ),
<<<<<<< HEAD
=======
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Agents proches',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 180,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _agents.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        return SizedBox(
                          width: 320,
                          child: AgentListTile(agent: _agents[index]),
                        );
                      },
                    ),
                  ),
>>>>>>> baf250f (mmisse a jour ddu gradle)
                ],
              ),
            ),
          ),

          // Bouton recentrer
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
                child: const Icon(Icons.my_location, color: Colors.black),
              ),
            ),
          ),

          // Container des agents avec scroll vertical
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Container(
                height: 300, // Hauteur fixe pour garantir la visibilité
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.10),
                      blurRadius: 18,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Poignée pour indiquer que c'est scrollable
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

                    // Header avec filtres
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Agents proches',
                            style: TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButton<String>(
                              value: _selectedFilter,
                              underline: const SizedBox(),
                              isDense: true,
                              items: _filterOptions.map((filter) {
                                return DropdownMenuItem(
                                  value: filter,
                                  child: Text(
                                    filter,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedFilter = value;
                                    _markers =
                                        _buildMarkersAround(_currentLatLng!);
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Liste des agents avec scroll
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                        itemCount: _filteredAgents.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return AgentListTile(agent: _filteredAgents[index]);
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
  const AgentListTile({super.key, required this.agent});

  @override
  Widget build(BuildContext context) {
    final name =
        '${agent['first_name'] ?? ''} ${agent['last_name'] ?? ''}'.trim();
    final specialty = agent['specialty'] ?? 'Agent terrain';
    final city = agent['city'] ?? 'Non spécifié';
    final distance = agent['distance_km'];
    final reliability = agent['reliability_score'] ?? 100.0;
    final isVerified = agent['is_verified'] ?? false;
    final avatarUrl = agent['avatar_url'];

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10),
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
                  child: Icon(Icons.verified, color: Colors.blue, size: 14),
                ),
            ],
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name.isNotEmpty ? name : 'Agent',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  specialty,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: Colors.orange[700],
                      size: 14,
                    ),
<<<<<<< HEAD
                    Flexible(
                      child: Text(
                        "${reliability.toStringAsFixed(0)}%",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
=======
                    Text(
                      "${reliability.toStringAsFixed(0)}%",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
>>>>>>> baf250f (mmisse a jour ddu gradle)
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      Icons.location_on,
                      color: Colors.grey,
                      size: 14,
                    ),
<<<<<<< HEAD
                    Flexible(
                      child: Text(
                        distance != null ? '${distance} km' : city,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
=======
                    Text(
                      distance != null ? '${distance} km' : city,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
>>>>>>> baf250f (mmisse a jour ddu gradle)
                    ),
                  ],
                ),
              ],
            ),
          ),
<<<<<<< HEAD
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Bouton Voir profil
              SizedBox(
                width: 80,
                height: 32,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Profil agent bientôt disponible')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Profil',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
=======
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Contact agent bientôt disponible')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD400),
              foregroundColor: Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
>>>>>>> baf250f (mmisse a jour ddu gradle)
              ),
              const SizedBox(height: 6),
              // Bouton Contacter
              SizedBox(
                width: 80,
                height: 32,
                child: ElevatedButton(
                  onPressed: () {
                    // Démarrer une conversation chat avec l'agent sans mission
                    Navigator.pushNamed(
                      context,
                      '/chat-detail',
                      arguments: {
                        'chatId': 'chat_${agent['id']}',
                        'userName': name.isNotEmpty ? name : 'Agent',
                        'agentAvatar':
                            agent['image'] ?? 'assets/images/avatar/user.png',
                        'missionId': null, // Pas de mission liée
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
                    minimumSize: const Size(60, 35),
                  ),
                  child: const Text(
                    'Contacter',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
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

  // Prix (range)
  RangeValues _price = const RangeValues(2000, 15000);

  // Distance rayon (km)
  double _radiusKm = 10;

  // Note minimale
  double _minRating = 4.0;

  // Vérifié
  bool _verifiedOnly = true;

  // Type mission
  final Set<String> _types = {'File d’attente'};

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.all(22),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Filtres',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
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
                    style: TextStyle(color: Colors.black87),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Prix
            Text(
              'Prix (${_price.start.toStringAsFixed(0)} – ${_price.end.toStringAsFixed(0)} CFA)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            RangeSlider(
              values: _price,
              min: 0,
              max: 50000,
              divisions: 100,
              activeColor: _accent,
              inactiveColor: Colors.grey[200],
              onChanged: (v) => setState(() => _price = v),
            ),

            const SizedBox(height: 10),

            // Type de mission
            const Text(
              'Type de mission',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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

            // Distance rayon
            Text(
              'Rayon (${_radiusKm.toStringAsFixed(0)} km)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Slider(
              value: _radiusKm,
              max: 50,
              min: 1,
              divisions: 49,
              activeColor: _accent,
              inactiveColor: Colors.grey[200],
              onChanged: (val) => setState(() => _radiusKm = val),
            ),

            const SizedBox(height: 10),

            // Notation
            Text(
              'Note minimale (${_minRating.toStringAsFixed(1)})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Slider(
              value: _minRating,
              max: 5,
              min: 1,
              divisions: 40,
              activeColor: _accent,
              inactiveColor: Colors.grey[200],
              onChanged: (val) => setState(() => _minRating = val),
            ),

            const SizedBox(height: 10),

            // Vérifié
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.black.withOpacity(0.06)),
              ),
              child: SwitchListTile(
                value: _verifiedOnly,
                activeThumbColor: _accent,
                onChanged: (val) => setState(() => _verifiedOnly = val),
                title: const Text(
                  'Agents vérifiés uniquement',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: const Text(
                  'Filtrer les profils certifiés',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'APPLIQUER',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _typeChip(String label) {
    final selected = _types.contains(label);
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() {
          if (selected) {
            _types.remove(label);
          } else {
            _types.add(label);
          }
        });
      },
      backgroundColor: Colors.grey[100],
      selectedColor: _accent,
      labelStyle: TextStyle(
        color: selected ? Colors.black : Colors.grey[700],
        fontWeight: FontWeight.bold,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      showCheckmark: false,
    );
  }
}
