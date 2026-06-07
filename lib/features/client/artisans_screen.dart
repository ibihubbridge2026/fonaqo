import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models/artisan_model.dart';
import 'repositories/artisan_repository.dart';
import 'screens/agent_profile_screen.dart';

class ArtisansScreen extends StatefulWidget {
  const ArtisansScreen({super.key});

  @override
  State<ArtisansScreen> createState() => _ArtisansScreenState();
}

class _ArtisansScreenState extends State<ArtisansScreen> {
  final ArtisanRepository _repo = ArtisanRepository();
  List<ArtisanModel> _artisans = [];
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
      final artisans = await _repo.fetchArtisans(query: _searchQuery);
      if (!mounted) return;
      setState(() {
        _artisans = artisans;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _artisans = [];
      });
    }
  }

  List<ArtisanModel> get _filteredArtisans {
    if (_searchQuery.isEmpty) return _artisans;
    final query = _searchQuery.toLowerCase();
    return _artisans.where((artisan) {
      return artisan.fullName.toLowerCase().contains(query) ||
          artisan.specialty.toLowerCase().contains(query) ||
          artisan.city.toLowerCase().contains(query) ||
          artisan.district.toLowerCase().contains(query);
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
                          // Recharger avec le nouveau filtre
                          _loadArtisans();
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
                              child: ArtisanCard(artisan: artisan),
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
  final ArtisanModel artisan;

  const ArtisanCard({
    super.key,
    required this.artisan,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AgentProfileScreen(
              agentId: artisan.id.toString(),
              agent: artisan.toJson(),
            ),
          ),
        );
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
                    shape: BoxShape.circle,
                    color: Colors.grey[200],
                  ),
                  child: ClipOval(
                    child: artisan.avatarUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: artisan.avatarUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[200],
                              child:
                                  Icon(Icons.person, color: Colors.grey[400]),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[200],
                              child:
                                  Icon(Icons.person, color: Colors.grey[400]),
                            ),
                          )
                        : Icon(Icons.person, color: Colors.grey[400], size: 30),
                  ),
                ),
                if (artisan.premium)
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
                        artisan.fullName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      if (artisan.certified) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.verified,
                          size: 14,
                          color: Colors.blue[600],
                        ),
                      ],
                      if (artisan.premium) ...[
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
                  Text(
                    artisan.specialty,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
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
                          '${artisan.district}, ${artisan.city}',
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
                  Row(
                    children: [
                      ...List.generate(5, (index) {
                        return Icon(
                          index < artisan.rating.round()
                              ? Icons.star
                              : Icons.star_border,
                          size: 12,
                          color: const Color(0xFFFFD400),
                        );
                      }),
                      const SizedBox(width: 4),
                      Text(
                        artisan.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Missions complétées et expérience
                  Row(
                    children: [
                      if (artisan.completedMissions > 0) ...[
                        Icon(
                          Icons.check_circle_outline,
                          color: Colors.green[600],
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '✓ ${artisan.completedMissions} chantiers',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        '${artisan.yearsOfExperience} ans d\'expérience',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
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
