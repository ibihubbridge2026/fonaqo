import 'package:flutter/material.dart';
import '../providers/ai_search_provider.dart';

class AiSearchModal extends StatefulWidget {
  const AiSearchModal({super.key});

  @override
  State<AiSearchModal> createState() => _AiSearchModalState();
}

class _AiSearchModalState extends State<AiSearchModal> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<String> _suggestions = [];
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadSuggestions() {
    // Suggestions de recherche simulées
    setState(() {
      _suggestions = [
        'Livraison express Abidjan',
        'Courses au supermarché',
        'Transport aéroport',
        'Assistance informatique',
        'Ménage domicile',
        'Garde enfants',
        'Services urgents',
        'Meilleurs agents près de moi',
      ];
    });
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    // Simulation de recherche IA
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;

      final results = [
        {
          'type': 'agent',
          'title': 'Agent Alpha - Livraison',
          'description': 'Spécialiste en livraison express, disponible immédiatement',
          'rating': 4.9,
          'distance': '2.3 km',
          'price': '1500 FCFA/h',
        },
        {
          'type': 'service',
          'title': 'Livraison Express',
          'description': 'Service de livraison rapide dans toute la ville',
          'rating': 4.7,
          'providers': 12,
          'price': 'À partir de 1000 FCFA',
        },
        {
          'type': 'mission',
          'title': 'Course urgente - Cocody',
          'description': 'Besoin de livreur pour documents urgents',
          'status': 'Disponible',
          'budget': '2000 FCFA',
          'time': 'Maintenant',
        },
      ];

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(
                  Icons.search,
                  color: Color(0xFFFFD400),
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Recherche IA',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Barre de recherche
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFD400), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.grey, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _performSearch,
                      decoration: InputDecoration(
                        hintText: 'Que recherchez-vous ?',
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (_isSearching)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD400)),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Suggestions
          if (_searchController.text.isEmpty && _suggestions.isNotEmpty)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Suggestions populaires',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _suggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = _suggestions[index];
                        return _buildSuggestionTile(suggestion);
                      },
                    ),
                  ),
                ],
              ),
            ),

          // Résultats de recherche
          if (_searchResults.isNotEmpty)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Résultats',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        return _buildResultTile(result);
                      },
                    ),
                  ),
                ],
              ),
            ),

          // État vide
          if (!_isSearching && _searchController.text.isNotEmpty && _searchResults.isEmpty)
            Expanded(
              child: Center(
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
                      'Aucun résultat trouvé',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Essayez avec d\'autres mots-clés',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestionTile(String suggestion) {
    return InkWell(
      onTap: () {
        _searchController.text = suggestion;
        _performSearch(suggestion);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(
              Icons.history,
              size: 16,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                suggestion,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
            ),
            Icon(
              Icons.arrow_upward,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultTile(Map<String, dynamic> result) {
    final type = result['type'] as String;
    final icon = _getIconForType(type);
    final color = _getColorForType(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result['title'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  result['description'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (result.containsKey('rating'))
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 12,
                            color: Color(0xFFFFD400),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            result['rating'].toString(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                      ),
                    if (result.containsKey('price'))
                      Text(
                        result['price'],
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFFD400),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'agent':
        return Icons.person;
      case 'service':
        return Icons.miscellaneous_services;
      case 'mission':
        return Icons.work;
      default:
        return Icons.search;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'agent':
        return Colors.blue;
      case 'service':
        return Colors.green;
      case 'mission':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
