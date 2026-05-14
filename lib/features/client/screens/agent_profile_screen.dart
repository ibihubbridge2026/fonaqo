import 'package:flutter/material.dart';

/// Écran de profil d'agent (basique pour l'instant)
class AgentProfileScreen extends StatelessWidget {
  final String agentId;
  final Map<String, dynamic>? agent;

  const AgentProfileScreen({
    super.key,
    required this.agentId,
    this.agent,
  });

  @override
  Widget build(BuildContext context) {
    // Récupérer les données de l'agent passées en arguments
    final agentData = agent ?? {};
    final name = '${agentData['first_name'] ?? ''} ${agentData['last_name'] ?? ''}'.trim();
    final specialty = agentData['specialty'] ?? 'Agent terrain';
    final isVerified = agentData['is_verified'] == true;
    final rating = agentData['rating']?.toString() ?? '4.5';
    final missions = agentData['completed_missions'] ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: Text(name.isEmpty ? 'Profil Agent' : name),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec avatar et informations principales
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: agentData['avatar'] != null
                              ? NetworkImage(agentData['avatar']) as ImageProvider
                              : null,
                          child: agentData['avatar'] == null
                              ? const Icon(Icons.person, size: 40, color: Colors.grey)
                              : null,
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    name.isEmpty ? 'Agent' : name,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (isVerified) ...[
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.verified,
                                      color: Colors.blue,
                                      size: 20,
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                specialty,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.star, color: Colors.amber, size: 16),
                                      const SizedBox(width: 4),
                                      Text('$rating/5.0'),
                                    ],
                                  ),
                                  const SizedBox(width: 16),
                                  Text('$missions missions'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Message temporaire
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.blue,
                      size: 32,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Profil en cours de développement',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Les fonctionnalités complètes du profil agent seront bientôt disponibles :\n\n'
                      '• Historique des missions\n'
                      '• Avis et évaluations\n'
                      '• Certifications et vérifications\n'
                      '• Statistiques de performance\n'
                      '• Disponibilités et zones d\'intervention',
                      style: TextStyle(
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Contacter l'agent
                      Navigator.pushNamed(
                        context,
                        '/chat-detail',
                        arguments: {
                          'chatId': 'chat_${agentData['id']}',
                          'userName': name.isEmpty ? 'Agent' : name,
                          'agentAvatar': agentData['avatar'],
                          'missionId': null,
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD400),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Contacter'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Retour à la liste des agents
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Retour'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
