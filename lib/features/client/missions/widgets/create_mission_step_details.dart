import 'package:flutter/material.dart';

/// Étape 2 : détails selon type (catégories + procuration ou lieu administratif + GPS).
class CreateMissionStepDetails extends StatelessWidget {
  final String flowType;
  final List<Map<String, dynamic>> categories;
  final int? selectedCategoryId;
  final ValueChanged<int> onCategorySelected;
  final bool needsProcuration;
  final ValueChanged<bool> onProcurationChanged;
  final TextEditingController adminPlaceController;
  final TextEditingController addressController;
  final TextEditingController descriptionController;
  final String recurrence;
  final ValueChanged<String> onRecurrenceChanged;
  final VoidCallback onNext;

  const CreateMissionStepDetails({
    super.key,
    required this.flowType,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
    required this.needsProcuration,
    required this.onProcurationChanged,
    required this.adminPlaceController,
    required this.addressController,
    required this.descriptionController,
    required this.recurrence,
    required this.onRecurrenceChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          flowType == 'queue' ? 'Lieu administratif' : 'Service & options',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          flowType == 'queue'
              ? 'Précisez le lieu où l’agent devra se rendre.'
              : 'Choisissez une catégorie et les options nécessaires.',
          style: TextStyle(color: Colors.grey[700], fontSize: 14),
        ),
        const SizedBox(height: 16),
        _InfoCard(
          icon: Icons.help_outline,
          message: flowType == 'queue'
              ? 'L’agent se rendra à l’administration avec votre procuration si nécessaire.'
              : 'Sélectionnez la catégorie qui correspond le mieux à votre besoin.',
        ),
        const SizedBox(height: 24),
        flowType == 'queue' ? _queueBody() : _serviceBody(),
      ],
    );
  }

  Widget _queueBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InputCard(
          icon: Icons.location_city,
          label: 'Lieu ou administration',
          controller: adminPlaceController,
          maxLines: 3,
          hint: 'Ex. Mairie de Cotonou — état civil',
        ),
        const SizedBox(height: 16),
        _InputCard(
          icon: Icons.location_on,
          label: 'Adresse GPS (obligatoire)',
          controller: addressController,
          maxLines: 2,
          hint: 'Ex. Quartier Gbégamey, près du marché Dantokpa',
        ),
      ],
    );
  }

  Widget _serviceBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Catégorie',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: categories.isEmpty
              ? Center(
                  child: Text(
                    'Aucune catégorie disponible. Vérifiez le serveur.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.35,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, i) {
                    final c = categories[i];
                    final id = c['id'] is int
                        ? c['id'] as int
                        : int.tryParse('${c['id']}') ?? i;
                    final name = c['name']?.toString() ?? '—';
                    final sel = selectedCategoryId == id;
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => onCategorySelected(id),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: sel ? const Color(0xFFFFF9E6) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: sel
                                  ? const Color(0xFFFFD400)
                                  : const Color(0xFFE5E5E5),
                              width: sel ? 2 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              name,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: Colors.grey[900],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 12),
        _InputCard(
          icon: Icons.description,
          label: "Besoin d'une procuration ?",
          controller:
              TextEditingController(text: needsProcuration ? 'Oui' : 'Non'),
          maxLines: 1,
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          value: needsProcuration,
          onChanged: onProcurationChanged,
          title: const Text(
            "Activer la procuration",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 16),
        _InputCard(
          icon: Icons.description,
          label: 'Description de la mission (obligatoire)',
          controller: descriptionController,
          maxLines: 4,
          hint: 'Décrivez en détail ce que vous avez besoin...',
        ),
        const SizedBox(height: 16),
        Text(
          'Fréquence de la mission',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          children: [
            _RecurrenceChip(
              label: 'Une fois',
              value: 'once',
              selected: recurrence == 'once',
              onSelected: onRecurrenceChanged,
            ),
            _RecurrenceChip(
              label: 'Toutes les semaines',
              value: 'weekly',
              selected: recurrence == 'weekly',
              onSelected: onRecurrenceChanged,
            ),
            _RecurrenceChip(
              label: 'Tous les mois',
              value: 'monthly',
              selected: recurrence == 'monthly',
              onSelected: onRecurrenceChanged,
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String message;

  const _InfoCard({
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD400), width: 1),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFFFFD400),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextEditingController controller;
  final int maxLines;
  final String? hint;

  const _InputCard({
    required this.icon,
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFFB8860B),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFFBBBBBB)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecurrenceChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final ValueChanged<String> onSelected;

  const _RecurrenceChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.black : Colors.grey[700],
        ),
      ),
      selected: selected,
      onSelected: (selected) {
        if (selected) {
          onSelected(value);
        }
      },
      selectedColor: const Color(0xFFFFD400),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected ? const Color(0xFFFFD400) : const Color(0xFFE5E5E5),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}
