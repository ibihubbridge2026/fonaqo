import 'package:flutter/material.dart';
import '../repository/agent_repository.dart';

/// BottomSheet pour l'ouverture d'un litige
class DisputeBottomSheet extends StatefulWidget {
  final String missionId;
  final VoidCallback onDisputeOpened;

  const DisputeBottomSheet({
    required this.missionId,
    required this.onDisputeOpened,
  });

  @override
  State<DisputeBottomSheet> createState() => _DisputeBottomSheetState();
}

class _DisputeBottomSheetState extends State<DisputeBottomSheet> {
  final _reasonController = TextEditingController();
  final _descriptionController = TextEditingController();
  final AgentRepository _agentRepository = AgentRepository();

  bool _isSubmitting = false;
  String _selectedReason = '';

  final List<String> _reasonOptions = [
    'Client injoignable',
    'Lieu dangereux',
    'Colis non conforme',
    'Paiement refusé',
    'Comportement inapproprié',
    'Autre problème',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitDispute() async {
    final reason = _selectedReason.isEmpty
        ? _reasonController.text.trim()
        : _selectedReason;
    final description = _descriptionController.text.trim();

    if (reason.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final success = await _agentRepository.openDispute(
        widget.missionId,
        reason,
        description,
      );

      if (success) {
        widget.onDisputeOpened();
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Litige ouvert avec succès. Un administrateur FONAQO examine votre cas.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Erreur lors de l\'ouverture du litige. Veuillez réessayer.'),
            backgroundColor: Colors.red,
          ),
        );
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
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            width: 60,
            height: 6,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          const SizedBox(height: 24),

          // Titre
          const Text(
            'Signaler un problème',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Décrivez le problème rencontré pour cette mission',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 32),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Raison
                const Text(
                  'Raison du litige',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 12),

                // Options prédéfinies
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _reasonOptions.map((reason) {
                    final isSelected = _selectedReason == reason;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedReason = isSelected ? '' : reason;
                          if (_selectedReason.isNotEmpty) {
                            _reasonController.clear();
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFFFD400)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFFFD400)
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          reason,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? Colors.black
                                : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // Champ raison personnalisée
                if (_selectedReason.isEmpty)
                  TextField(
                    controller: _reasonController,
                    decoration: InputDecoration(
                      hintText: 'Autre raison...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFFFD400)),
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // Description
                const Text(
                  'Description détaillée',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Décrivez en détail ce qui s\'est passé...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFFFD400)),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Bouton d'envoi
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitDispute,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Ouvrir un litige',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Avertissement
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.red, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'L\'ouverture d\'un litige suspendra automatiquement la mission et bloquera le paiement jusqu\'à résolution par un administrateur.',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
