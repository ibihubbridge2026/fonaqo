import 'package:flutter/material.dart';
import '../../../widgets/custom_app_bar.dart';
import 'widgets/step_5_tracking_view.dart';
import '../../core/routes/app_routes.dart';
import '../../core/models/mission_model.dart';
import '../missions/mission_repository.dart';

class MissionDetailScreen extends StatefulWidget {
  const MissionDetailScreen({super.key});

  @override
  State<MissionDetailScreen> createState() => _MissionDetailScreenState();
}

class _MissionDetailScreenState extends State<MissionDetailScreen> {
  final MissionRepository _missionRepository = MissionRepository();
  MissionModel? _mission;
  bool _isLoading = true;
  String? _errorMessage;
  String? _missionId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMissionId();
    });
  }

  void _loadMissionId() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _missionId = args['missionId']?.toString();
      if (_missionId != null && _missionId!.isNotEmpty) {
        _loadMissionDetails();
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'ID de mission non fourni';
        });
      }
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Arguments de navigation invalides';
      });
    }
  }

  Future<void> _loadMissionDetails() async {
    if (_missionId == null || _missionId!.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

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
          _isLoading = false;
          _errorMessage = 'Erreur lors du chargement: ${e.toString()}';
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
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
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
              Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 16, color: Colors.red),
                textAlign: TextAlign.center,
              ),
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
      return const Center(
        child: Text('Mission non trouvée'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image de contexte (avant le lieu)
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
              _mission!.formattedStatus,
              style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(height: 15),
            Text(
              _mission!.title,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
            ),
            Text(
              _mission!.description ?? 'Description non disponible',
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 30),

            // Mission Details Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
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
                  _buildDetailRow('Prix', '${_mission!.price.toStringAsFixed(0)} FCFA'),
                  _buildDetailRow('Date de création', _formatDate(_mission!.createdAt)),
                  if (_mission!.address != null) 
                    _buildDetailRow('Adresse', _mission!.address!),
                  if (_mission!.agentName != null)
                    _buildDetailRow('Agent assigné', _mission!.agentName!),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Agent Card (Détail)
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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Moussa D.",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Agent Certifié Fonaqo",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.phone, color: Colors.green),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
            const Text(
              "Résumé du paiement",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildInfoTile("Montant bloqué", "2 500 CFA"),
            _buildInfoTile("Heure de début", "14:30"),

            const SizedBox(height: 24),

            // Tracking + actions
            const Text("Suivi", style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Step5TrackingView(onBackToMissions: () {}, showBackButton: false),
            const SizedBox(height: 18),
            const Text(
              "Actions",
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
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
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
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
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.chat),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                "OUVRIR LE CHAT",
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
    );
  }

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
            "Confirmez que la mission a bien été réalisée. Les fonds seront transférés à l’agent.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD400),
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Confirmer',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fonds libérés (simulation).')),
    );
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
  }
}
