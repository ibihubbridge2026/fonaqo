import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/ai_search_provider.dart';
import '../../widgets/ai_agent_card.dart';

/// Écran de Recherche Assistée par IA (Côté CLIENT)
/// L'utilisateur décrit son besoin en langage naturel.
/// L'IA analyse et propose des agents pertinents.
class AiSearchScreen extends StatefulWidget {
  const AiSearchScreen({super.key});

  @override
  State<AiSearchScreen> createState() => _AiSearchScreenState();
}

class _AiSearchScreenState extends State<AiSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _performSearch() async {
    if (_controller.text.trim().isEmpty) return;
    
    setState(() => _isSearching = true);
    
    final provider = context.read<AiSearchProvider>();
    await provider.searchAgents(_controller.text.trim());
    
    setState(() => _isSearching = false);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AiSearchProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface.withOpacity(0.9),
        elevation: 0,
        title: Text(
          'Recherche IA',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
            fontSize: 24,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Input IA
            _buildInputSection(provider),
            
            const SizedBox(height: 24),
            
            // Section Résultat IA (Compréhension)
            if (provider.analysisResult != null)
              _buildAnalysisSection(provider),
            
            const SizedBox(height: 24),
            
            // Section Agents Recommandés
            if (provider.suggestedAgents.isNotEmpty)
              _buildAgentsSection(provider),
              
            // Loading State
            if (provider.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection(AiSearchProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: AppColors.secondary, size: 24),
              const SizedBox(width: 8),
              Text(
                'Décrivez votre besoin',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLines: 3,
            style: TextStyle(color: AppColors.onSurface, fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Ex: "J\'ai besoin de quelqu\'un pour faire la queue à la banque demain matin..."',
              hintStyle: TextStyle(color: AppColors.onSurfaceVariant),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: AppColors.surfaceContainer,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isSearching ? null : _performSearch,
              icon: _isSearching 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.search),
              label: Text(_isSearching ? 'Analyse en cours...' : 'Lancer la recherche'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisSection(AiSearchProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.secondaryContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.secondary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Compris !',
            style: TextStyle(
              color: AppColors.secondary,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            provider.analysisResult ?? '',
            style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 15),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildChip(Icons.schedule, 'Demain Matin'),
              _buildChip(Icons.location_on, 'Proche de vous'),
              _buildChip(Icons.account_balance, 'Banque'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentsSection(AiSearchProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Agents Recommandés',
              style: TextStyle(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text('Voir tout', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: provider.suggestedAgents.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return AiAgentCard(agent: provider.suggestedAgents[index]);
          },
        ),
      ],
    );
  }
}
