import 'package:flutter/material.dart';
import 'package:fonaco/widgets/custom_app_bar.dart';
import 'package:fonaco/core/routes/app_routes.dart';
import 'package:fonaco/core/models/mission_model.dart';
import 'mission_repository.dart';
import 'widgets/step_5_tracking_view.dart';

class MissionDetailScreen extends StatefulWidget {
  final String? missionId;

  const MissionDetailScreen({super.key, this.missionId});

  @override
  State<MissionDetailScreen> createState() => _MissionDetailScreenState();
}

class _MissionDetailScreenState extends State<MissionDetailScreen> {
  final MissionRepository _missionRepository = MissionRepository();
  MissionModel? _mission;
  bool _isLoading = true;
  String? _errorMessage;
  String? _resolvedMissionId;

  @override
  void initState() {
    super.initState();
    // Utilise un post-frame callback pour gérer les deux modes d'initialisation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMission();
    });
  }

  void _initializeMission() {
    // 1. Priorité au missionId passé par le constructeur
    // 2. Sinon, on cherche dans les arguments de la route
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _resolvedMissionId = widget.missionId ?? args?['missionId']?.toString();

    if (_resolvedMissionId != null) {
      _loadMissionDetails();
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'ID de mission non fourni';
      });
    }
  }

  Future<void> _loadMissionDetails() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final missionData =
          await _missionRepository.fetchMissionDetails(_resolvedMissionId!);
      if (mounted) {
        setState(() {
          _mission = missionData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur lors du chargement : ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Color _getStatusColor(MissionStatus status) {
    switch (status) {
      case MissionStatus.PENDING:
        return Colors.orange;
      case MissionStatus.ACCEPTED:
        return Colors.blue;
      case MissionStatus.ON_THE_WAY:
        return Colors.purple;
      case MissionStatus.ARRIVED:
        return Colors.indigo;
      case MissionStatus.IN_PROGRESS:
        return Colors.green;
      case MissionStatus.COMPLETED:
        return Colors.teal;
      case MissionStatus.CANCELLED:
      case MissionStatus.DISPUTED:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  bool _hasAgentAccepted() {
    if (_mission == null) return false;
    final acceptedStatuses = [
      MissionStatus.ACCEPTED,
      MissionStatus.ON_THE_WAY,
      MissionStatus.ARRIVED,
      MissionStatus.IN_PROGRESS,
      MissionStatus.COMPLETED
    ];
    return acceptedStatuses.contains(_mission!.status);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: CustomAppBar.detailStack(
        title: _mission?.title ?? 'Détails de la mission',
        detailTitleWidget: Text(
          _mission?.title ?? "Détails de la mission",
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadMissionDetails,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_mission == null) {
      return const Center(child: Text('Mission non trouvée'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image de la mission
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.asset(
                'assets/images/hero/img-2.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[200],
                  child:
                      const Icon(Icons.image_not_supported_outlined, size: 48),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Badge de statut
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(_mission!.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _mission!.statusDisplay.toUpperCase(),
              style: TextStyle(
                color: _getStatusColor(_mission!.status),
                fontWeight: FontWeight.w900,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            _mission!.title,
            style: const TextStyle(
                fontSize: 26, fontWeight: FontWeight.w900, color: Colors.black),
          ),
          const SizedBox(height: 12),
          Text(
            _mission!.description ?? 'Aucune description fournie.',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 24),

          // Carte des détails
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)
              ],
            ),
            child: Column(
              children: [
                _buildDetailRow(
                    'Lieu', _mission!.address ?? 'Adresse non spécifiée'),
                _buildDetailRow(
                    'Prix', '${_mission!.price.toStringAsFixed(0)} FCFA'),
                _buildDetailRow(
                    'Catégorie', _mission!.category ?? 'Non catégorisée'),
                _buildDetailRow(
                    'Date',
                    _mission!.createdAt != null
                        ? _mission!.createdAt.toString().split(' ')[0]
                        : 'Date non disponible'),
                _buildDetailRow(
                    'Client', _mission!.clientName ?? 'Client non spécifié'),
                if (_mission!.agentName != null)
                  _buildDetailRow('Agent', _mission!.agentName!),
                if (_mission!.isUrgent) _buildDetailRow('Urgence', 'Oui'),
                if (_mission!.isConfidential)
                  _buildDetailRow('Confidentiel', 'Oui'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Bouton "Ouvrir un litige"
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1C1C),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFD400),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.gpp_maybe_rounded,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 15),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Signaler un problème',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Un souci ? Nous intervenons.',
                            style:
                                TextStyle(color: Colors.white60, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.litige),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD400),
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'OUVRIR UN LITIGE',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section Tracking / Actions
          if (_hasAgentAccepted()) ...[
            const Text("SUIVI", style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Step5TrackingView(onBackToMissions: () {}, showBackButton: false),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _confirmReleaseFunds(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text("LIBÉRER LES FONDS",
                        style: TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.rating),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD400),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text("FINALISER",
                        style: TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Message d'attente
            _buildWaitingCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.grey, fontWeight: FontWeight.w500)),
          Expanded(
              child: Text(value,
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildWaitingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: const Column(
        children: [
          Icon(Icons.hourglass_empty, size: 40, color: Colors.orange),
          SizedBox(height: 12),
          Text("En attente d'un agent",
              style: TextStyle(fontWeight: FontWeight.bold)),
          Text("Votre mission sera acceptée sous peu.",
              style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Future<void> _confirmReleaseFunds(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer ?'),
        content: const Text("Voulez-vous libérer les fonds à l'agent ?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ANNULER')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('CONFIRMER')),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Fonds libérés !'), backgroundColor: Colors.green));
    }
  }
}
