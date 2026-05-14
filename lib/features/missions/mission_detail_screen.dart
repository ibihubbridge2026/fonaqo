import 'package:flutter/material.dart';
import '../../../widgets/custom_app_bar.dart';
<<<<<<< HEAD
import 'widgets/step_5_tracking_view.dart';
import '../../core/routes/app_routes.dart';
import '../../core/models/mission_model.dart';
import '../missions/mission_repository.dart';

class MissionDetailScreen extends StatefulWidget {
  const MissionDetailScreen({super.key});
=======
import '../missions/mission_repository.dart';
import '../../core/models/mission_model.dart';

class MissionDetailScreen extends StatefulWidget {
  final String? missionId;

  const MissionDetailScreen({super.key, this.missionId});

  @override
  State<MissionDetailScreen> createState() => _MissionDetailScreenState();
}

class _MissionDetailScreenState extends State<MissionDetailScreen> {
  final MissionRepository _missionRepo = MissionRepository();
  MissionModel? _mission;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMission();
  }

  Future<void> _loadMission() async {
    if (widget.missionId == null) {
      setState(() {
        _loading = false;
        _error = 'ID de mission non fourni';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final mission = await _missionRepo.fetchMissionDetails(widget.missionId!);
      if (!mounted) return;
      setState(() {
        _mission = mission;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }
>>>>>>> baf250f (mmisse a jour ddu gradle)

  @override
  State<MissionDetailScreen> createState() => _MissionDetailScreenState();
}

class _MissionDetailScreenState extends State<MissionDetailScreen> {
  final MissionRepository _missionRepository = MissionRepository();
  MissionModel? _mission;
  bool _isLoading = false;
  String? _errorMessage;
  String? _missionId;

  @override
  void initState() {
    super.initState();
    // Attendre que le widget soit complètement initialisé avant d'accéder aux arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMissionIdAndData();
    });
  }

  void _loadMissionIdAndData() {
    if (!mounted) return;

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _missionId = args?['missionId']?.toString();

    if (_missionId != null) {
      _loadMissionDetails();
    } else {
      if (mounted) {
        setState(() {
          _errorMessage = 'ID de mission non fourni';
        });
      }
    }
  }

  Future<void> _loadMissionDetails() async {
    if (_missionId == null) return;

    setState(() => _isLoading = true);
    _errorMessage = null;

    try {
      final missionData =
          await _missionRepository.fetchMissionDetails(_missionId!);
      if (mounted) {
        setState(() {
          _mission = missionData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Erreur lors du chargement de la mission: ${e.toString()}';
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
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Non spécifiée';
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  bool _hasAgentAccepted() {
    if (_mission == null) return false;
    return _mission!.status == MissionStatus.ACCEPTED ||
        _mission!.status == MissionStatus.ON_THE_WAY ||
        _mission!.status == MissionStatus.ARRIVED ||
        _mission!.status == MissionStatus.IN_PROGRESS ||
        _mission!.status == MissionStatus.COMPLETED;
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
<<<<<<< HEAD
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
=======
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
>>>>>>> baf250f (mmisse a jour ddu gradle)
          child: CircularProgressIndicator(),
        ),
      );
    }

<<<<<<< HEAD
    if (_errorMessage != null) {
=======
    if (_error != null) {
>>>>>>> baf250f (mmisse a jour ddu gradle)
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
<<<<<<< HEAD
              Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 16, color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadMissionDetails,
=======
              Text(_error!, style: TextStyle(color: Colors.red[700])),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadMission,
>>>>>>> baf250f (mmisse a jour ddu gradle)
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_mission == null) {
      return const Center(
        child: Text('Mission non trouvée'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
<<<<<<< HEAD
          // Image de contexte
=======
          // Image
>>>>>>> baf250f (mmisse a jour ddu gradle)
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.asset(
                'assets/images/hero/img-2.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[200],
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    color: Colors.grey,
                    size: 48,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(_mission!.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
<<<<<<< HEAD
              _mission!.formattedStatus,
=======
              _mission!.statusDisplay.toUpperCase(),
>>>>>>> baf250f (mmisse a jour ddu gradle)
              style: TextStyle(
                color: _getStatusColor(_mission!.status),
                fontWeight: FontWeight.w900,
                fontSize: 10,
              ),
            ),
          ),
<<<<<<< HEAD

          const SizedBox(height: 16),

          // Title and description
          Text(
            _mission!.title,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),

          // Metadata badges
          Row(
            children: [
              if (_mission!.isUrgent)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.priority_high,
                          size: 12, color: Colors.red[700]),
                      const SizedBox(width: 4),
                      Text(
                        'URGENT',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              if (_mission!.isConfidential)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock, size: 12, color: Colors.amber[700]),
                      const SizedBox(width: 4),
                      Text(
                        'CONFIDENTIEL',
                        style: TextStyle(
                          color: Colors.amber[700],
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              if (_mission!.category != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _mission!.category!,
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Description
          Text(
            _mission!.description ?? 'Description non disponible',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),

          // Tags
          if (_mission!.tags != null && _mission!.tags!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _mission!.tags!
                    .map((tag) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '#$tag',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 10,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),

          const SizedBox(height: 30),

          // Mission Details Card
=======
          const SizedBox(height: 16),

          // Title and Description
          Text(
            _mission!.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _mission!.description ?? 'Aucune description',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),

          // Mission Details
>>>>>>> baf250f (mmisse a jour ddu gradle)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
<<<<<<< HEAD
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Détails de la mission',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                _buildDetailRow(
                    'Prix', '${_mission!.price.toStringAsFixed(0)} FCFA'),
                _buildDetailRow(
                    'Date de création', _formatDate(_mission!.createdAt)),
                if (_mission!.address != null)
                  _buildDetailRow('Adresse', _mission!.address!),
                if (_mission!.agentName != null)
                  _buildDetailRow('Agent assigné', _mission!.agentName!),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Agent Card
          if (_mission!.agentName != null)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.blue[100],
                    backgroundImage: const NetworkImage(
                      "https://i.pravatar.cc/100?u=1",
                    ),
                    child: Text(
                      _mission!.agentName![0].toUpperCase(),
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _mission!.agentName!,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Text(
                          "Agent Certifié Fonaqo",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.verified, color: Colors.green),
                ],
              ),
            ),

          const SizedBox(height: 30),

          // Tracking et actions conditionnés
          if (_hasAgentAccepted()) ...[
            const Text("Suivi", style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Step5TrackingView(onBackToMissions: () {}, showBackButton: false),
            const SizedBox(height: 18),
            const Text("Actions",
                style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _confirmReleaseFunds(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "LIBÉRER L'ARGENT",
                      style:
                          TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                    ),
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
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "FINALISER",
                      style:
                          TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                    ),
                  ),
=======
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 14,
>>>>>>> baf250f (mmisse a jour ddu gradle)
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Détails de la mission',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoTile('Lieu', _mission!.address ?? 'Non spécifié'),
                _buildInfoTile(
                    'Catégorie', _mission!.category ?? 'Non spécifiée'),
                _buildInfoTile(
                    'Prix', '${_mission!.price.toStringAsFixed(0)} XOF'),
                _buildInfoTile(
                    'Date', _mission!.createdAt.toString().split(' ')[0]),
                _buildInfoTile('Statut', _mission!.statusDisplay),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons
          if (_mission!.status == MissionStatus.PENDING) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Fonctionnalité bientôt disponible')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'ACCEPTER LA MISSION',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chat bientôt disponible')),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.black),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'OUVRIR LE CHAT',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
<<<<<<< HEAD
          ] else ...[
            // Message si aucun agent n'a accepté
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.hourglass_empty,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "En attente d'un agent",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Un agent disponible prendra bientôt votre mission",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
=======
          ),
>>>>>>> baf250f (mmisse a jour ddu gradle)
        ],
      ),
    );
  }

<<<<<<< HEAD
  static Future<void> _confirmReleaseFunds(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Libérer les fonds ?',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: const Text(
            "Confirmez que la mission a bien été réalisée. Les fonds seront transférés à l'agent.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirmer'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fonds libérés avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    }
=======
  Color _getStatusColor(MissionStatus status) {
    switch (status) {
      case MissionStatus.PENDING:
        return Colors.orange;
      case MissionStatus.ACCEPTED:
        return Colors.blue;
      case MissionStatus.ON_THE_WAY:
      case MissionStatus.ARRIVED:
      case MissionStatus.IN_PROGRESS:
        return Colors.green;
      case MissionStatus.COMPLETED:
        return Colors.purple;
      case MissionStatus.CANCELLED:
      case MissionStatus.DISPUTED:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
>>>>>>> baf250f (mmisse a jour ddu gradle)
  }
}
