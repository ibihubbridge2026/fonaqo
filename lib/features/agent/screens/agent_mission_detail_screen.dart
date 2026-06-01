import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/agent_provider.dart';
import '../repository/agent_repository.dart';
import '../../../core/models/mission_model.dart';
import 'agent_active_mission_screen.dart';

class AgentMissionDetailScreen extends StatefulWidget {
  final MissionModel? mission;

  const AgentMissionDetailScreen({super.key, this.mission});

  @override
  State<AgentMissionDetailScreen> createState() =>
      _AgentMissionDetailScreenState();
}

class _AgentMissionDetailScreenState extends State<AgentMissionDetailScreen> {
  bool _isAccepting = false;
  final AgentRepository _agentRepository = AgentRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xFFEAEAEA),
                  ),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 42,
                      width: 42,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      "Détail de la mission",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (widget.mission?.isUrgent == true)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF6D8),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Text(
                        "Urgent",
                        style: TextStyle(
                          color: Color(0xFFC79A00),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // CLIENT CARD
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: const Color(0xFFFFD54F),
                            backgroundImage: widget.mission?.avatarUrl != null
                                ? CachedNetworkImageProvider(
                                    widget.mission!.avatarUrl!) as ImageProvider
                                : null,
                            child: widget.mission?.avatarUrl == null
                                ? const Icon(
                                    Icons.person,
                                    color: Colors.black,
                                    size: 30,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.mission?.clientName ?? 'Client',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.mission?.isVerified == true
                                      ? "Client vérifié${widget.mission?.clientRating != null ? ' • ${widget.mission!.clientRating!.toStringAsFixed(1)} ⭐' : ''}"
                                      : "Client non vérifié",
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: 46,
                            width: 46,
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.call,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // INFOS MISSION
                    const Text(
                      "Informations",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 14),

                    _buildInfoCard(
                      icon: Icons.inventory_2_outlined,
                      title: "Type de mission",
                      value: widget.mission?.category ?? 'Livraison',
                    ),

                    const SizedBox(height: 14),

                    _buildInfoCard(
                      icon: Icons.location_on_outlined,
                      title: "Destination",
                      value: widget.mission?.address ?? 'Non spécifié',
                    ),

                    const SizedBox(height: 14),

                    _buildInfoCard(
                      icon: Icons.access_time,
                      title: "Créée le",
                      value: widget.mission?.createdAt != null
                          ? '${widget.mission!.createdAt!.day}/${widget.mission!.createdAt!.month}/${widget.mission!.createdAt!.year}'
                          : 'Non spécifié',
                    ),

                    const SizedBox(height: 22),

                    // DESCRIPTION
                    const Text(
                      "Description",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 14),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Text(
                        widget.mission?.description ??
                            'Aucune description disponible',
                        style: const TextStyle(
                          height: 1.6,
                          color: Color(0xFF555555),
                          fontSize: 15,
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    // GAIN
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFFD54F),
                            Color(0xFFFFC107),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            "Gain estimé",
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "${widget.mission?.price.toStringAsFixed(0) ?? '0'} FCFA",
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // BOUTON ACCEPTER
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton(
                        onPressed: _isAccepting
                            ? null
                            : () async {
                                await _acceptMission();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: _isAccepting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text(
                                "Accepter la mission",
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // REFUSER
                    Center(
                      child: TextButton(
                        onPressed: _isAccepting
                            ? null
                            : () {
                                Navigator.pop(context);
                              },
                        child: const Text(
                          "Refuser la mission",
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF6D8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: const Color(0xFFC79A00),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Accepte la mission et navigue vers l'écran de mission active
  Future<void> _acceptMission() async {
    HapticFeedback.lightImpact();
    if (widget.mission == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur: Aucune mission sélectionnée'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isAccepting = true;
    });

    try {
      // Utiliser l'ID de la mission passée en paramètre
      final missionId = widget.mission!.id;

      // Utiliser le provider pour accepter et mettre à jour l'état
      await context
          .read<AgentProvider>()
          .acceptMissionAndUpdateState(missionId);

      if (mounted) {
        // Afficher un message de succès
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mission acceptée avec succès!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Naviguer vers l'écran de mission active
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                AgentActiveMissionScreen(mission: widget.mission!),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAccepting = false;
        });
      }
    }
  }
}
