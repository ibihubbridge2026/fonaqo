import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _services = [];
  List<Map<String, dynamic>> _filteredServices = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadServices();
    _searchController.addListener(_filterServices);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterServices);
    _searchController.dispose();
    super.dispose();
  }

  void _loadServices() {
    setState(() {
      _isLoading = true;
    });

    // Services simulés
    final services = [
      {
        'id': '1',
        'name': 'Livraison Express',
        'description': 'Livraison rapide de colis et documents',
        'category': 'Transport',
        'price': '1500 FCFA',
        'rating': 4.8,
        'image': 'assets/images/services/delivery.jpg',
        'available': true,
      },
      {
        'id': '2',
        'name': 'Courses Personnelles',
        'description': 'Aide pour vos courses et achats',
        'category': 'Shopping',
        'price': '2000 FCFA',
        'rating': 4.6,
        'image': 'assets/images/services/shopping.jpg',
        'available': true,
      },
      {
        'id': '3',
        'name': 'Transport de Personnes',
        'description': 'Navette et transport privé',
        'category': 'Transport',
        'price': '3000 FCFA',
        'rating': 4.9,
        'image': 'assets/images/services/transport.jpg',
        'available': false,
      },
      {
        'id': '4',
        'name': 'Assistance Informatique',
        'description': 'Support technique et dépannage',
        'category': 'Technologie',
        'price': '5000 FCFA',
        'rating': 4.7,
        'image': 'assets/images/services/tech.jpg',
        'available': true,
      },
      {
        'id': '5',
        'name': 'Ménage et Entretien',
        'description': 'Services de nettoyage professionnel',
        'category': 'Maison',
        'price': '4000 FCFA',
        'rating': 4.5,
        'image': 'assets/images/services/cleaning.jpg',
        'available': true,
      },
      {
        'id': '6',
        'name': 'Garde d\'Enfants',
        'description': 'Babysitting et garde temporaire',
        'category': 'Famille',
        'price': '3500 FCFA',
        'rating': 4.8,
        'image': 'assets/images/services/babysitting.jpg',
        'available': true,
      },
    ];

    setState(() {
      _services = services;
      _filteredServices = services;
      _isLoading = false;
    });
  }

  void _filterServices() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredServices = _services;
      } else {
        _filteredServices = _services.where((service) {
          final name = service['name'].toString().toLowerCase();
          final description = service['description'].toString().toLowerCase();
          final category = service['category'].toString().toLowerCase();
          return name.contains(query) || 
                 description.contains(query) || 
                 category.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Column(
          children: [
            // Header avec recherche
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Services",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Barre de recherche
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.grey, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Rechercher un service...',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                            },
                            child: const Icon(Icons.clear, color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Liste des services
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFFD400),
                      ),
                    )
                  : _filteredServices.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Aucun service trouvé',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          itemCount: _filteredServices.length,
                          itemBuilder: (context, index) {
                            final service = _filteredServices[index];
                            return _buildServiceCard(service);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          // Navigation vers détail du service
          Navigator.pushNamed(
            context,
            AppRoutes.eventDetail,
            arguments: {
              'title': service['name'],
              'category': service['category'],
              'description': service['description'],
              'price': service['price'],
              'rating': service['rating'],
              'available': service['available'],
              'imagePath': service['image'],
            },
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Image du service
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7CC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: service['image'] != null
                      ? Image.asset(
                          service['image'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.miscellaneous_services,
                              size: 32,
                              color: Color(0xFFFFD400),
                            );
                          },
                        )
                      : const Icon(
                          Icons.miscellaneous_services,
                          size: 32,
                          color: Color(0xFFFFD400),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Informations du service
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            service['name'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: service['available'] == true
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            service['available'] == true ? 'Disponible' : 'Indisponible',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: service['available'] == true
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      service['category'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      service['description'],
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          service['price'],
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFFD400),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 14,
                              color: Color(0xFFFFD400),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              service['rating'].toString(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
