import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/agent_provider.dart';
import '../repository/agent_repository.dart';

class AgentBoostScreen extends StatefulWidget {
  const AgentBoostScreen({super.key});

  @override
  State<AgentBoostScreen> createState() => _AgentBoostScreenState();
}

class _AgentBoostScreenState extends State<AgentBoostScreen> {
  int selectedBoost = 0;
  bool _isActivating = false;
  final AgentRepository _agentRepository = AgentRepository();

  final List<Map<String, dynamic>> boosts = [
    {
      "title": "Day Boost",
      "price": "200 FCFA",
      "duration": "24 heures",
      "missions": "+35% visibilité",
      "recommended": false,
    },
    {
      "title": "Week Boost",
      "price": "1 000 FCFA",
      "duration": "7 jours",
      "missions": "+80% visibilité",
      "recommended": true,
    },
    {
      "title": "Month Boost",
      "price": "2 000 FCFA",
      "duration": "30 jours",
      "missions": "Visibilité maximale",
      "recommended": false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Solde Boost
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFFD400),
                    Color(0xFFFFC107),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Solde Boost",
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "2 200 FCFA",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.trending_up, size: 18),
                        SizedBox(width: 8),
                        Text(
                          "Augmentez votre visibilité",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              "Pass Priorité",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              "Soyez affiché avant les autres agents dans votre zone.",
              style: TextStyle(
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 24),

            // Liste des boosts
            ...List.generate(
              boosts.length,
              (index) {
                final boost = boosts[index];
                final isSelected = selectedBoost == index;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedBoost = index;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFFFD400)
                            : Colors.grey.shade200,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Radio custom
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFFFD400)
                                  : Colors.grey.shade400,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? Center(
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFFFFD400),
                                    ),
                                  ),
                                )
                              : null,
                        ),

                        const SizedBox(width: 16),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    boost['title'],
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (boost['recommended'])
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF3C4),
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      child: const Text(
                                        "Populaire",
                                        style: TextStyle(
                                          color: Color(0xFFB8860B),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                boost['duration'],
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                boost['missions'],
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              boost['price'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 10),

            // Bouton activation
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: _isActivating ? null : _activateBoost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD400),
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: _isActivating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Text(
                        "Activer le boost",
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  /// Active le boost sélectionné
  Future<void> _activateBoost() async {
    if (selectedBoost < 0 || selectedBoost >= boosts.length) return;

    final boost = boosts[selectedBoost];
    final price = double.parse(
        boost['price'].replaceAll(' FCFA', '').replaceAll(' ', ''));

    setState(() {
      _isActivating = true;
    });

    try {
      final agentProvider = Provider.of<AgentProvider>(context, listen: false);
      final currentBalance = agentProvider.balance;

      if (currentBalance < price) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solde insuffisant pour activer ce boost'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Déduire le montant du solde
      final success = await _agentRepository.purchaseBoost(
        boost['title'],
        price,
      );

      if (success) {
        // Mettre à jour le solde immédiatement
        await agentProvider.fetchWalletDetails();

        // Activer le boost
        // TODO: Implémenter la logique d'activation du boost

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${boost["title"]} activé avec succès!'),
            backgroundColor: Colors.green,
          ),
        );

        // Retourner au dashboard
        Navigator.pop(context);
      } else {
        throw Exception('Échec de l\'achat du boost');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isActivating = false;
        });
      }
    }
  }
}
