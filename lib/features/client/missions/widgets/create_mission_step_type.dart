import 'package:flutter/material.dart';

/// Étape 1 : choix File d'attente vs Service.
class CreateMissionStepType extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelect;

  const CreateMissionStepType({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Type de mission',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Choisissez le mode adapté à votre besoin.',
            style: TextStyle(color: Colors.grey[700], fontSize: 14),
          ),
          const SizedBox(height: 24),
          _TypeCard(
            title: "File d'attente",
            subtitle:
                'Remplacement physique dans une administration (guichet, file).',
            icon: Icons.queue_play_next_outlined,
            value: 'queue',
            selected: selected,
            onTap: () => onSelect('queue'),
          ),
          const SizedBox(height: 14),
          _TypeCard(
            title: 'Service',
            subtitle: 'Prestation ciblée (SBEE, SONEB, mairie, etc.).',
            icon: Icons.home_repair_service_outlined,
            value: 'service',
            selected: selected,
            onTap: () => onSelect('service'),
          ),
        ],
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String value;
  final String? selected;
  final VoidCallback onTap;

  const _TypeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isOn = selected == value;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isOn ? const Color(0xFFFFF9E6) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isOn ? const Color(0xFFFFD400) : const Color(0xFFE5E5E5),
              width: isOn ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 28, color: const Color(0xFF715D00)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              if (isOn)
                const Icon(Icons.check_circle, color: Color(0xFF715D00)),
            ],
          ),
        ),
      ),
    );
  }
}
