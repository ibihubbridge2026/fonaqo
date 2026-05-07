import 'package:flutter/material.dart';

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

  // --- FONCTION POUR LE FILTRE (Image ec4474) ---
  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AgentFilterSheet(),
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
                borderRadius: BorderRadius.circular(15),
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
                color: const Color(0xFFFFD400),
                borderRadius: BorderRadius.circular(15),
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
    return Column(
      children: [
        // 1. ZONE CARTE
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.35,
          width: double.infinity,
          child: Stack(
            children: [
              Container(
                color: Colors.grey[300],
                width: double.infinity,
                child: Image.asset('assets/images/map_placeholder.png', fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.map, size: 50)),
              ),
              Positioned(top: 50, left: 100, child: _buildMapMarker()),
              Positioned(top: 120, right: 80, child: _buildMapMarker()),
              Positioned(bottom: 40, left: 150, child: _buildMapMarker()),
              Positioned(top: 20, left: 0, right: 0, child: _buildFloatingSearchBar()),
            ],
          ),
        ),
        // 2. LISTE DES AGENTS
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF9F9F9),
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _allAgents.length,
              itemBuilder: (context, index) => AgentListTile(agent: _allAgents[index]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapMarker() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(blurRadius: 5, color: Colors.black26)]),
      child: const Icon(Icons.person_pin_circle, color: Color(0xFFFFD400), size: 30),
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

  String _category = 'Tout';
  double _maxDistanceKm = 10;
  double _minRating = 4.0;
  bool _verifiedOnly = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
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
                    _category = 'Tout';
                    _maxDistanceKm = 10;
                    _minRating = 4.0;
                    _verifiedOnly = true;
                  });
                },
                child: const Text('Réinitialiser', style: TextStyle(color: Colors.black87)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text('Catégorie', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _chip('Tout'),
              _chip('Banque'),
              _chip('Courses'),
              _chip('Livraison'),
              _chip('Admin'),
              _chip('Santé'),
            ],
          ),
          const SizedBox(height: 18),
          Text('Distance maximale (${_maxDistanceKm.toStringAsFixed(0)} km)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Slider(
            value: _maxDistanceKm,
            max: 50,
            min: 1,
            divisions: 49,
            activeColor: _accent,
            inactiveColor: Colors.grey[200],
            onChanged: (val) => setState(() => _maxDistanceKm = val),
          ),
          const SizedBox(height: 10),
          Text('Note minimale (${_minRating.toStringAsFixed(1)})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(14),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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

  Widget _chip(String label) {
    final isSelected = _category == label;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _category = label),
      backgroundColor: Colors.grey[100],
      selectedColor: _accent,
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : Colors.grey[700],
        fontWeight: FontWeight.bold,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      showCheckmark: false,
    );
  }
}