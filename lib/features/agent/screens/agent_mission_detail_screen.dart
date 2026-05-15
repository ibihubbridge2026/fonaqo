import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/agent_provider.dart';
import '../repository/agent_repository.dart';
import '../../../core/models/mission_model.dart';
import 'agent_active_mission_screen.dart';

class AgentMissionDetailScreen extends StatefulWidget {
  const AgentMissionDetailScreen({super.key});

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
                            child: const Icon(
                              Icons.person,
                              color: Colors.black,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  "Jean Koffi",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "Client vérifié • 4.9 ⭐",
                                  style: TextStyle(
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
                      value: "Livraison de colis",
                    ),

                    const SizedBox(height: 14),

                    _buildInfoCard(
                      icon: Icons.location_on_outlined,
                      title: "Point de départ",
                      value: "Cocody Angré 8ème tranche",
                    ),

                    const SizedBox(height: 14),

                    _buildInfoCard(
                      icon: Icons.flag_outlined,
                      title: "Destination",
                      value: "Plateau Avenue Chardy",
                    ),

                    const SizedBox(height: 14),

                    _buildInfoCard(
                      icon: Icons.access_time,
                      title: "Durée estimée",
                      value: "25 minutes",
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
                      child: const Text(
                        "Le client souhaite faire livrer un colis fragile contenant des documents importants. Merci de manipuler avec précaution et de confirmer la livraison via QR code.",
                        style: TextStyle(
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
                        children: const [
                          Text(
                            "Gain estimé",
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "8 500 FCFA",
                            style: TextStyle(
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
    setState(() {
      _isAccepting = true;
    });

    try {
      // Récupérer l'ID de la mission (passé en argument ou depuis les params)
      final missionId =
          'mission_id_placeholder'; // TODO: Récupérer depuis les arguments

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
            builder: (context) => const AgentActiveMissionScreen(),
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
