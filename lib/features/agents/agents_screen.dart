import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class AgentsScreen extends StatefulWidget {
  const AgentsScreen({super.key});

  @override
  State<AgentsScreen> createState() => _AgentsScreenState();
}

class _AgentsScreenState extends State<AgentsScreen> {
  // Données statiques des agents
  final List<Map<String, dynamic>> _allAgents = [
    {
      'name': 'Marc-Antoine',
      'role': 'Expert Administratif',
      'rating': 4.8,
      'distance': '0.8 km',
      'image': 'assets/images/avatar/agent1.jpg',
      'isVerified': true,
    },
    {
      'name': 'Julie N.',
      'role': 'Conciergerie & Courses',
      'rating': 4.9,
      'distance': '1.2 km',
      'image': 'assets/images/avatar/agent2.jpg',
      'isVerified': true,
    },
    {
      'name': 'Thomas L.',
      'role': 'Livraison Rapide',
      'rating': 4.5,
      'distance': '2.5 km',
      'image': 'assets/images/avatar/agent3.jpg',
      'isVerified': true,
    },
    {
      'name': 'Awa Diop',
      'role': 'Aide Ménagère',
      'rating': 4.7,
      'distance': '3.1 km',
      'image': 'assets/images/avatar/agent1.jpg',
      'isVerified': true,
    },
  ];

  static const Color _accent = Color(0xFFFFD400);

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
    _initLocation();
  }

  Future<void> _initLocation() async {
    setState(() => _locating = true);
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        setState(() => _locating = false);
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() => _locating = false);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final me = LatLng(pos.latitude, pos.longitude);
      _currentLatLng = me;
      _markers = _buildMarkersAround(me);

      setState(() => _locating = false);

      // Si la map est déjà prête, on centre immédiatement.
      await _animateTo(me);
    } catch (_) {
      setState(() => _locating = false);
    }
  }

  Set<Marker> _buildMarkersAround(LatLng center) {
    // Positionnement “demo” : 4 agents autour de l’utilisateur (petit offset).
    const offsets = <LatLng>[
      LatLng(0.0045, 0.0030),
      LatLng(-0.0035, 0.0020),
      LatLng(0.0020, -0.0040),
      LatLng(-0.0040, -0.0030),
    ];

    final markers = <Marker>{};

    // Marker utilisateur
    markers.add(
      Marker(
        markerId: const MarkerId('me'),
        position: center,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'Vous'),
      ),
    );

    for (var i = 0; i < _allAgents.length; i++) {
      final agent = _allAgents[i];
      final off = offsets[i % offsets.length];
      final pos = LatLng(center.latitude + off.latitude, center.longitude + off.longitude);
      markers.add(
        Marker(
          markerId: MarkerId('agent_$i'),
          position: pos,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
          infoWindow: InfoWindow(title: agent['name'], snippet: agent['role']),
        ),
      );
    }

    return markers;
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
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: const SingleChildScrollView(
            child: _AgentFilterSheet(),
          ),
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
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
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
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
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
    // Demande:
    // - Pas d’icône noire sous le header.
    // - GoogleMap en fond.
    // - Cartes agents en overlay en bas.
    return Stack(
      children: [
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
        Positioned(
          top: 8,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFloatingSearchBar(),
                if (_locating)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 14)],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                          SizedBox(width: 10),
                          Text('Localisation…', style: TextStyle(fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                  ),
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
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 18, offset: const Offset(0, -6))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Agents proches', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 180,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _allAgents.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        return SizedBox(
                          width: 320,
                          child: AgentListTile(agent: _allAgents[index]),
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
    );
  }
}

class AgentListTile extends StatelessWidget {
  final Map<String, dynamic> agent;
  const AgentListTile({super.key, required this.agent});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 30,
                child: ClipOval(
                  child: Image.asset(
                    agent['image'],
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.black54),
                  ),
                ),
              ),
              if (agent['isVerified'])
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
              children: [
                Text(agent['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(agent['role'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.orange, size: 14),
                    Text(" ${agent['rating']}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 10),
                    const Icon(Icons.location_searching, color: Colors.grey, size: 14),
                    Text(" ${agent['distance']}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                )
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD400),
              foregroundColor: Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size(60, 35),
            ),
            child: const Text("Choisir", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          )
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
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(
                child: Text('Filtres', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
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
                child: const Text('Réinitialiser', style: TextStyle(color: Colors.black87)),
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
          const Text('Type de mission', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
          Text('Rayon (${_radiusKm.toStringAsFixed(0)} km)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
          Text('Note minimale (${_minRating.toStringAsFixed(1)})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
              activeColor: _accent,
              onChanged: (val) => setState(() => _verifiedOnly = val),
              title: const Text('Agents vérifiés uniquement', style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: const Text('Filtrer les profils certifiés', style: TextStyle(color: Colors.grey)),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 0,
              ),
              child: const Text('APPLIQUER', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
          const SizedBox(height: 10),
        ],
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