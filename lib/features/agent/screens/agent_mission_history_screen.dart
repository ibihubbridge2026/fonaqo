import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import '../providers/agent_provider.dart';
import '../repository/agent_repository.dart';
import '../../../core/models/mission_model.dart';

/// Écran d'historique détaillé des missions de l'agent
class AgentMissionHistoryScreen extends StatefulWidget {
  const AgentMissionHistoryScreen({super.key});

  @override
  State<AgentMissionHistoryScreen> createState() =>
      _AgentMissionHistoryScreenState();
}

class _AgentMissionHistoryScreenState extends State<AgentMissionHistoryScreen>
    with SingleTickerProviderStateMixin {
  final AgentRepository _agentRepository = AgentRepository();
  late TabController _tabController;

  List<MissionModel> _completedMissions = [];
  List<MissionModel> _cancelledMissions = [];
  bool _isLoading = true;
  String _selectedFilter = 'Toutes';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMissionHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Charge l'historique des missions depuis l'API
  Future<void> _loadMissionHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implémenter getMissionHistory dans AgentRepository
      // final history = await _agentRepository.getMissionHistory();

      // Données de test pour le moment
      final completedMissions = [
        MissionModel(
          id: '1',
          title: 'Livraison documents SBEE',
          description: 'Livraison de documents officiels à la banque',
          clientName: 'Jean Dupont',
          latitude: 6.3670,
          longitude: 2.3935,
          price: 2500.0,
          status: MissionStatus.COMPLETED,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 12)),
        ),
        MissionModel(
          id: '2',
          title: 'Course restaurant Chez Lamine',
          description: 'Récupération commande repas à emporter',
          clientName: 'Marie Sagna',
          latitude: 6.3670,
          longitude: 2.3935,
          price: 1800.0,
          status: MissionStatus.COMPLETED,
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ];

      final cancelledMissions = [
        MissionModel(
          id: '3',
          title: 'Livraison médicaments pharmacie',
          description: 'Livraison de médicaments urgents',
          clientName: 'Paul Konan',
          latitude: 6.3670,
          longitude: 2.3935,
          price: 3200.0,
          status: MissionStatus.CANCELLED,
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          updatedAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
      ];

      setState(() {
        _completedMissions = completedMissions;
        _cancelledMissions = cancelledMissions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur chargement historique: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Retourne la liste filtrée selon le statut
  List<MissionModel> get _filteredMissions {
    switch (_selectedFilter) {
      case 'Terminées':
        return _completedMissions;
      case 'Annulées':
        return _cancelledMissions;
      default:
        return [..._completedMissions, ..._cancelledMissions];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Historique des missions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: const Color(0xFFFFD400),
          indicatorWeight: 3,
          tabs: const [
            Tab(
              icon: Icon(Icons.check_circle, size: 20),
              text: 'Terminées',
            ),
            Tab(
              icon: Icon(Icons.cancel, size: 20),
              text: 'Annulées',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMissionsList(_completedMissions, 'terminées'),
          _buildMissionsList(_cancelledMissions, 'annulées'),
        ],
      ),
    );
  }

  /// Construit la liste des missions
  Widget _buildMissionsList(List<MissionModel> missions, String type) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (missions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'terminées' ? Icons.history : Icons.cancel_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune mission ${type}',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vous n\'avez pas encore de missions ${type}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: missions.length,
      itemBuilder: (context, index) {
        final mission = missions[index];
        return _MissionHistoryCard(mission: mission);
      },
    );
  }
}

/// Carte pour afficher une mission dans l'historique
class _MissionHistoryCard extends StatelessWidget {
  final MissionModel mission;

  const _MissionHistoryCard({
    required this.mission,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = mission.status == MissionStatus.COMPLETED;
    final formattedDate = _formatDate(mission.updatedAt!);
    final formattedPrice = '${mission.price.toStringAsFixed(0)} FCFA';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header avec titre et statut
          Row(
            children: [
              Expanded(
                child: Text(
                  mission.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      isCompleted ? Colors.green.shade100 : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isCompleted ? 'Terminée' : 'Annulée',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isCompleted
                        ? Colors.green.shade800
                        : Colors.red.shade800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Description
          if (mission.description.isNotEmpty)
            Text(
              mission.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),

          const SizedBox(height: 12),

          // Informations client et prix
          Row(
            children: [
              // Avatar client
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD400).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.person,
                  color: Color(0xFFFFD400),
                  size: 20,
                ),
              ),

              const SizedBox(width: 12),

              // Infos client
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mission.clientName ?? 'Client',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    if (mission.address != null)
                      Text(
                        mission.address!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),

              // Prix et date
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formattedPrice,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isCompleted
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Séparateur
          Container(
            height: 1,
            color: Colors.grey.shade200,
          ),

          const SizedBox(height: 12),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isCompleted) ...[
                // Bouton évaluation (si pas encore noté)
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Ouvrir dialogue de notation
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Fonctionnalité bientôt disponible')),
                    );
                  },
                  icon: const Icon(Icons.star, size: 16),
                  label: const Text(
                    'Noter',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFFD400),
                    side: const BorderSide(color: Color(0xFFFFD400)),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                  ),
                ),
                const SizedBox(width: 8),
              ],

              // Bouton détails
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Naviguer vers les détails de la mission
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Détails bientôt disponibles')),
                  );
                },
                icon: const Icon(Icons.info_outline, size: 16),
                label: const Text(
                  'Détails',
                  style: TextStyle(fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD400),
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Formate la date pour l'affichage
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Aujourd\'hui';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'Il y a $weeks semaine${weeks > 1 ? 's' : ''}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
