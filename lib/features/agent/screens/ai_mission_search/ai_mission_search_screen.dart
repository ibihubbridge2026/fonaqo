import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/ai_mission_search_provider.dart';
import '../widgets/ai_mission_card.dart';

/// Écran de Recherche Assistée par IA (Côté AGENT)
/// L'agent décrit le type de mission qu'il cherche.
/// L'IA analyse et propose des missions pertinentes.
class AiMissionSearchScreen extends StatefulWidget {
  const AiMissionSearchScreen({super.key});

  @override
  State<AiMissionSearchScreen> createState() => _AiMissionSearchScreenState();
}

class _AiMissionSearchScreenState extends State<AiMissionSearchScreen> {
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
    
    final provider = context.read<AiMissionSearchProvider>();
    await provider.searchMissions(_controller.text.trim());
    
    setState(() => _isSearching = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = AppColors(isDark: isDark);
    final provider = context.watch<AiMissionSearchProvider>();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface.withOpacity(0.9),
        elevation: 0,
        title: Text(
          'Recherche Mission IA',
          style: TextStyle(
            color: colors.primary,
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
            _buildInputSection(colors, provider),
            
            const SizedBox(height: 24),
            
            // Section Résultat IA
            if (provider.analysisResult != null)
              _buildAnalysisSection(colors, provider),
            
            const SizedBox(height: 24),
            
            // Section Missions Recommandées
            if (provider.suggestedMissions.isNotEmpty)
              _buildMissionsSection(colors, provider),
              
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

  Widget _buildInputSection(AppColors colors, AiMissionSearchProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: colors.secondary, size: 24),
              const SizedBox(width: 8),
              Text(
                'Quelle mission cherchez-vous ?',
                style: TextStyle(
                  color: colors.secondary,
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
            style: TextStyle(color: colors.onSurface, fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Ex: "Je veux une mission de livraison rapide près de Cocody..."',
              hintStyle: TextStyle(color: colors.onSurfaceVariant),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: colors.surfaceContainer,
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
              label: Text(_isSearching ? 'Analyse en cours...' : 'Trouver des missions'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisSection(AppColors colors, AiMissionSearchProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.secondaryContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.secondary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Compris !',
            style: TextStyle(
              color: colors.secondary,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            provider.analysisResult ?? '',
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 15),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildChip(colors, Icons.local_shipping, 'Livraison'),
              _buildChip(colors, Icons.location_on, 'Cocody'),
              _buildChip(colors, Icons.speed, 'Rapide'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(AppColors colors, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: colors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionsSection(AppColors colors, AiMissionSearchProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Missions Correspondantes',
              style: TextStyle(
                color: colors.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text('Voir tout', style: TextStyle(color: colors.secondary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: provider.suggestedMissions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return AiMissionCard(mission: provider.suggestedMissions[index]);
          },
        ),
      ],
    );
  }
}
