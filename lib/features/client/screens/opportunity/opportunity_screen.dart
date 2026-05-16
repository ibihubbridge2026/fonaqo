import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/opportunity_provider.dart';
import '../../widgets/opportunity_card.dart';

/// Écran "Opportunités" pour le Client
/// Remplace l'ancien écran "Événements".
/// Affiche une grille de services/offres spéciales style "Bento Grid".
class OpportunityScreen extends StatefulWidget {
  const OpportunityScreen({super.key});

  @override
  State<OpportunityScreen> createState() => _OpportunityScreenState();
}

class _OpportunityScreenState extends State<OpportunityScreen> {
  String _selectedCategory = 'Tout';

  final List<String> _categories = [
    'Tout',
    'Banque',
    'Livraison',
    'Entretien',
    'Électricité',
    'Bricolage'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OpportunityProvider>().fetchOpportunities();
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface.withOpacity(0.9),
        elevation: 0,
        title: Text(
          'Opportunités',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.tune, color: AppColors.primary),
            onPressed: () {
              // Ouvrir filtres avancés
            },
          )
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche et Filtres
          _buildSearchAndFilter(),

          // Grille des opportunités
          Expanded(
            child: Consumer<OpportunityProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return Center(
                      child: CircularProgressIndicator(color: AppColors.primary));
                }
                if (provider.error != null) {
                  return Center(
                      child: Text(provider.error!,
                          style: TextStyle(color: AppColors.error)));
                }

                final opportunities = provider.opportunities;
                // Filtrage simple par catégorie
                final filtered = _selectedCategory == 'Tout'
                    ? opportunities
                    : opportunities
                        .where((o) => o.category == _selectedCategory)
                        .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off,
                            size: 64, color: AppColors.outlineVariant),
                        SizedBox(height: 16),
                        Text(
                          'Aucune opportunité trouvée',
                          style: TextStyle(
                              color: AppColors.onSurfaceVariant, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        MediaQuery.of(context).size.width > 600 ? 2 : 1,
                    childAspectRatio: 1.1,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return OpportunityCard(opportunity: filtered[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.surface,
      child: Column(
        children: [
          // Recherche
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher un service...',
                prefixIcon: Icon(Icons.search, color: AppColors.onSurfaceVariant),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Catégories Scrollable
          SizedBox(
            height: 50,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = cat == _selectedCategory;

                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : AppColors.outlineVariant.withOpacity(0.3),
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 8)
                            ]
                          : [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Icon(Icons.apps,
                                size: 18, color: AppColors.onPrimary),
                          ),
                        Text(
                          cat,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.onPrimary
                                : AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
