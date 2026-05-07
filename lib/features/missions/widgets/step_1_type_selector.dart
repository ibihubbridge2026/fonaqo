import 'package:flutter/material.dart';

class Step1TypeSelector extends StatefulWidget {
  /// Appelée lorsque l'utilisateur a sélectionné un type et saisi une description, puis appuie sur Suivant.
  final void Function(String mode, String description) onNext;

  const Step1TypeSelector({super.key, required this.onNext});

  @override
  State<Step1TypeSelector> createState() => _Step1TypeSelectorState();
}

class _Step1TypeSelectorState extends State<Step1TypeSelector> {
  String _selectedMode = '';
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _canContinue => _selectedMode.isNotEmpty && _descriptionController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Que doit faire\nl'agent ?", 
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, height: 1.1)),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _TypeCard(
                title: "File d'attente",
                icon: Icons.hourglass_empty,
                isSelected: _selectedMode == 'queue',
                onTap: () => setState(() => _selectedMode = 'queue'),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _TypeCard(
                title: "Service libre",
                icon: Icons.inventory_2_outlined,
                isSelected: _selectedMode == 'service',
                onTap: () => setState(() => _selectedMode = 'service'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20)],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: TextField(
            controller: _descriptionController,
            maxLines: 5,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: "Décrivez la mission (ex: acte de naissance, nombre de documents, contraintes...)",
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          height: 58,
          child: ElevatedButton(
            onPressed: _canContinue
                ? () => widget.onNext(_selectedMode, _descriptionController.text.trim())
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              disabledBackgroundColor: Colors.black.withOpacity(0.12),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: const Text("SUIVANT", style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ),
      ],
    );
  }
}

class _TypeCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeCard({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isSelected ? Colors.black : Colors.black.withOpacity(0.06), width: isSelected ? 1.5 : 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFFFFD400), size: 38),
            const SizedBox(height: 10),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}