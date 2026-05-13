import 'package:flutter/material.dart';

/// Étape 3 : adresse GPS (saisie), description, agent optionnel.
class CreateMissionStepLogistics extends StatelessWidget {
  final TextEditingController addressController;
  final TextEditingController descriptionController;
  final TextEditingController targetAgentController;
  final VoidCallback onNext;

  const CreateMissionStepLogistics({
    super.key,
    required this.addressController,
    required this.descriptionController,
    required this.targetAgentController,
    required this.onNext,
  });

  bool get _ok =>
      addressController.text.trim().isNotEmpty &&
      descriptionController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Logistique',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Adresse complète (repère GPS) et consignes pour l’agent.',
            style: TextStyle(color: Colors.grey[700], fontSize: 14),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: addressController,
            decoration: _fieldDeco('Adresse (GPS / repère)'),
            maxLines: 2,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: descriptionController,
            decoration: _fieldDeco('Description de la mission'),
            maxLines: 4,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: targetAgentController,
            decoration: _fieldDeco(
              'Assigner à un agent (username, optionnel)',
              hint: 'Ex. agent_koffi',
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _ok ? onNext : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD400),
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.grey[300],
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Continuer',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDeco(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
      ),
    );
  }
}
