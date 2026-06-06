import 'package:flutter/material.dart';

import 'missions/mission_repository.dart';

class ArtisansScreen extends StatefulWidget {
  const ArtisansScreen({super.key});

  @override
  State<ArtisansScreen> createState() => _ArtisansScreenState();
}

class _ArtisansScreenState extends State<ArtisansScreen> {
  final MissionRepository _repo = MissionRepository();
  List<Map<String, dynamic>> _artisans = [];
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadArtisans();
  }

  Future<void> _loadArtisans() async {
    setState(() {
      _loading = true;
    });

    try {
      final artisans = await _repo.fetchAgentSuggestions(limit: 20);
      if (!mounted) return;
      setState(() {
        _artisans = artisans;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        // Données fictives en cas d'erreur
        _artisans = _getMockArtisans();
      });
    }
  }

  List<Map<String, dynamic>> _getMockArtisans() {
    return [
      {
        'username': 'Koffi',
        'specialty': 'Électricité',
        'location': 'Cotonou, Quartier Fidjrossè',
        'experience': '10 ans d\'expérience',
        'rating': 4.8,
        'completed_missions': 156,
        'estimated_price': '5,000 FCFA/h',
        'is_top_choice': true,
      },
      {
        'username': 'Moussa',
        'specialty': 'Plomberie',
        'location': 'Porto-Novo, Quartier Ganhi',
        'experience': '15 ans d\'expérience',
        'rating': 4.5,
        'completed_missions': 203,
        'estimated_price': '4,500 FCFA/h',
        'is_top_choice': false,
      },
      {
        'username': 'Adjoua',
        'specialty': 'Maçonnerie',
        'location': 'Cotonou, Quartier Gbedjromede',
        'experience': '8 ans d\'expérience',
        'rating': 4.9,
        'completed_missions': 89,
        'estimated_price': '6,000 FCFA/h',
        'is_top_choice': true,
      },
      {
        'username': 'Kouassi',
        'specialty': 'Menuiserie',
        'location': 'Ouidah, Quartier Djègbadji',
        'experience': '12 ans d\'expérience',
        'rating': 4.7,
        'completed_missions': 134,
        'estimated_price': '5,500 FCFA/h',
        'is_top_choice': false,
      },
    ];
  }

  List<Map<String, dynamic>> get _filteredArtisans {
    if (_searchQuery.isEmpty) return _artisans;
    final query = _searchQuery.toLowerCase();
    return _artisans.where((artisan) {
      final name = (artisan['username'] as String?)?.toLowerCase() ?? '';
      final specialty = (artisan['specialty'] as String?)?.toLowerCase() ?? '';
      final location = (artisan['location'] as String?)?.toLowerCase() ?? '';
      return name.contains(query) ||
          specialty.contains(query) ||
          location.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nos artisans',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Découvrez des artisans professionnels, rapides et efficaces pour tous vos besoins.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // Barre de recherche
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black.withOpacity(0.08)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey[600], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Rechercher un artisan (ex: Plombier)...',
                          hintStyle: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Liste des artisans
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredArtisans.isEmpty
                      ? Center(
                          child: Text(
                            'Aucun artisan trouvé',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _filteredArtisans.length,
                          itemBuilder: (context, index) {
                            final artisan = _filteredArtisans[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: ArtisanCard(
                                name: artisan['username'] ?? 'Artisan',
                                location: artisan['location'] ?? '',
                                experience: artisan['experience'] ?? '',
                                rating:
                                    (artisan['rating'] as num?)?.toDouble() ??
                                        0.0,
                                completedMissions:
                                    (artisan['completed_missions'] as int?) ??
                                        0,
                                estimatedPrice:
                                    artisan['estimated_price'] ?? '',
                                isTopChoice: artisan['is_top_choice'] == true,
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class ArtisanCard extends StatelessWidget {
  final String name;
  final String location;
  final String experience;
  final double rating;
  final int completedMissions;
  final String estimatedPrice;
  final bool isTopChoice;

  const ArtisanCard({
    super.key,
    required this.name,
    required this.location,
    required this.experience,
    this.rating = 0.0,
    this.completedMissions = 0,
    this.estimatedPrice = '',
    this.isTopChoice = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // TODO: Navigation vers profil artisan
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.black.withOpacity(0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Photo de profil
            Stack(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFFD400).withOpacity(0.3),
                        const Color(0xFFFFD400).withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      name[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                if (isTopChoice)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFD400),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.star,
                        size: 12,
                        color: Colors.black,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            // Informations
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      if (isTopChoice) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD400).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Top',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: Colors.grey[600],
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Rating étoiles
                  if (rating > 0)
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            index < rating.round()
                                ? Icons.star
                                : Icons.star_border,
                            size: 12,
                            color: const Color(0xFFFFD400),
                          );
                        }),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 4),
                  // Missions complétées et prix
                  Row(
                    children: [
                      if (completedMissions > 0) ...[
                        Icon(
                          Icons.check_circle_outline,
                          color: Colors.green[600],
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$completedMissions missions',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (estimatedPrice.isNotEmpty)
                        Text(
                          estimatedPrice,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    experience,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Flèche
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
