import 'package:flutter/material.dart';

class ServiceType {
  final String id;
  final String title;
  final IconData icon;
  final String description;

  const ServiceType({
    required this.id,
    required this.title,
    required this.icon,
    required this.description,
  });
}

class Step1TypeSelector extends StatefulWidget {
  /// Appelée lorsque l'utilisateur clique sur suivant
  final void Function(String mode, String description) onNext;

  const Step1TypeSelector({
    super.key,
    required this.onNext,
  });

  @override
  State<Step1TypeSelector> createState() =>
      _Step1TypeSelectorState();
}

class _Step1TypeSelectorState
    extends State<Step1TypeSelector> {
  String _selectedService = '';

  final TextEditingController _descriptionController =
      TextEditingController();

  bool _isConfidential = false;

  // Liste des services
  final List<ServiceType> _services = [
    const ServiceType(
      id: 'livraison',
      title: 'Livraison',
      icon: Icons.local_shipping,
      description:
          'Livraison de colis, documents, courses',
    ),

    const ServiceType(
      id: 'menage',
      title: 'Aide ménagère',
      icon: Icons.cleaning_services,
      description: 'Ménage, entretien, repassage',
    ),

    const ServiceType(
      id: 'courses',
      title: 'Courses',
      icon: Icons.shopping_cart,
      description:
          'Courses alimentaires, shopping',
    ),

    const ServiceType(
      id: 'administratif',
      title: 'Démarches',
      icon: Icons.description,
      description:
          'Papiers, administrations, postes',
    ),

    const ServiceType(
      id: 'garde',
      title: 'Garde enfants/animaux',
      icon: Icons.pets,
      description:
          'Baby-sitting, promenade chiens',
    ),

    const ServiceType(
      id: 'bricolage',
      title: 'Bricolage',
      icon: Icons.build,
      description:
          'Petits travaux, réparations',
    ),
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _canContinue {
    return _selectedService.isNotEmpty &&
        _descriptionController.text.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // TITRE
          const Text(
            "Quel service\nsouhaitez-vous ?",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              height: 1.1,
            ),
          ),

          const SizedBox(height: 18),

          // GRID SERVICES
          GridView.builder(
            shrinkWrap: true,
            physics:
                const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: _services.length,
            itemBuilder: (context, index) {
              final service = _services[index];

              return _ServiceCard(
                service: service,
                isSelected:
                    _selectedService == service.id,
                onTap: () {
                  setState(() {
                    _selectedService = service.id;
                  });
                },
              );
            },
          ),

          const SizedBox(height: 18),

          // SWITCH CONFIDENTIEL
          if (_selectedService.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.black.withOpacity(
                    0.05,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lock,
                    color: Colors.grey[600],
                    size: 20,
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Mission confidentielle",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),

                        Text(
                          "Visible uniquement par les agents internes",
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  Switch(
                    value: _isConfidential,
                    activeThumbColor:
                        const Color(0xFFFFD400),
                    onChanged: (value) {
                      setState(() {
                        _isConfidential = value;
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),
          ],

          // DESCRIPTION
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(
                    0.04,
                  ),
                  blurRadius: 20,
                ),
              ],
            ),
            child: TextField(
              controller: _descriptionController,
              maxLines: 5,
              onChanged: (_) {
                setState(() {});
              },
              decoration: const InputDecoration(
                hintText:
                    "Décrivez votre besoin en détail...",
                border: InputBorder.none,
              ),
            ),
          ),

          const SizedBox(height: 18),

          // BOUTON
          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton(
              onPressed: _canContinue
                  ? () {
                      widget.onNext(
                        _selectedService,
                        _descriptionController.text
                            .trim(),
                      );
                    }
                  : null,

              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                disabledBackgroundColor:
                    Colors.black.withOpacity(
                  0.12,
                ),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(16),
                ),
              ),

              child: const Text(
                "SUIVANT",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final ServiceType service;
  final bool isSelected;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.service,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.black
                : Colors.black.withOpacity(
                    0.06,
                  ),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                0.04,
              ),
              blurRadius: 12,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFFFD400)
                    : Colors.grey[100],
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child: Icon(
                service.icon,
                size: 28,
                color: isSelected
                    ? Colors.black
                    : Colors.grey[600],
              ),
            ),

            const SizedBox(height: 12),

            Text(
              service.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: isSelected
                    ? Colors.black
                    : Colors.grey[700],
              ),
            ),

            const SizedBox(height: 4),

            Text(
              service.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                height: 1.2,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}