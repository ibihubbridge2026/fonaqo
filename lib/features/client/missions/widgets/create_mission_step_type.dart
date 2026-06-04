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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Quel type de mission souhaitez-vous créer ?',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
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
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isOn ? const Color(0xFFFFD400) : const Color(0xFFE0E0E0),
              width: isOn ? 2 : 1,
            ),
            boxShadow: isOn
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color:
                      isOn ? const Color(0xFFFFD400) : const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: isOn ? Colors.black : Colors.grey[600],
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
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black,
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
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_right,
                    color: Color(0xFFFFD400),
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
