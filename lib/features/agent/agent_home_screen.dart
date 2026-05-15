import 'package:flutter/material.dart';

class AgentDashboardScreen extends StatelessWidget {
  const AgentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundImage: AssetImage(
                      'assets/images/avatar.png',
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bonjour 👋',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),

                        const SizedBox(height: 4),

                        const Text(
                          'Jean Agent',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.notifications_none_outlined,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 26),

              // SOLDE
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFFD400),
                      Color(0xFFFFC107),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Solde disponible',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      '245 600 FCFA',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: const Color(0xFFFFD400),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Retirer',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.black,
                              side: const BorderSide(color: Colors.black),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Historique',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // STATS
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      '24',
                      'Missions',
                      Icons.work_outline,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: _buildStatCard(
                      '4.8',
                      'Note',
                      Icons.star_outline,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: _buildStatCard(
                      '98%',
                      'Succès',
                      Icons.trending_up,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ACTIONS RAPIDES
              const Text(
                'Actions rapides',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 18),

              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      Icons.map_outlined,
                      'Explorer',
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: _buildActionCard(
                      Icons.account_balance_wallet_outlined,
                      'Wallet',
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: _buildActionCard(
                      Icons.person_outline,
                      'Profil',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // MISSIONS URGENTES
              Row(
                children: [
                  const Text(
                    'Missions urgentes',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const Spacer(),

                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Voir tout',
                      style: TextStyle(
                        color: Color(0xFFE0B800),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _buildMissionCard(
                title: 'Attente à la banque',
                location: 'Place de l’Indépendance',
                amount: '3 000 FCFA',
                distance: '450m',
                urgent: true,
              ),

              const SizedBox(height: 16),

              _buildMissionCard(
                title: 'Livraison de colis',
                location: 'Akpakpa',
                amount: '5 500 FCFA',
                distance: '1.2km',
                urgent: false,
              ),

              const SizedBox(height: 30),

              // ACTIVITÉ RÉCENTE
              const Text(
                'Activité récente',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 18),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildActivity(
                      Icons.check_circle_outline,
                      'Mission terminée',
                      '+2 500 FCFA',
                      Colors.green,
                    ),

                    const Divider(height: 28),

                    _buildActivity(
                      Icons.account_balance_wallet_outlined,
                      'Retrait effectué',
                      '-10 000 FCFA',
                      Colors.red,
                    ),

                    const Divider(height: 28),

                    _buildActivity(
                      Icons.star_outline,
                      'Nouvel avis reçu',
                      '5 étoiles',
                      Colors.orange,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String value,
    String label,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFE0B800)),

          const SizedBox(height: 10),

          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    IconData icon,
    String label,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7CC),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: Colors.black),
          ),

          const SizedBox(height: 12),

          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionCard({
    required String title,
    required String location,
    required String amount,
    required String distance,
    required bool urgent,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor:
                    const Color(0xFFFFD400).withOpacity(.15),
                child: const Icon(
                  Icons.work_outline,
                  color: Colors.black,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      location,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: urgent
                      ? Colors.red.shade50
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  urgent ? 'Urgent' : 'Disponible',
                  style: TextStyle(
                    color: urgent ? Colors.red : Colors.green,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Text(
                amount,
                style: const TextStyle(
                  color: Color(0xFFE0B800),
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),

              const Spacer(),

              Icon(
                Icons.location_on_outlined,
                size: 18,
                color: Colors.grey.shade600,
              ),

              const SizedBox(width: 4),

              Text(
                distance,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivity(
    IconData icon,
    String title,
    String value,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color),
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}