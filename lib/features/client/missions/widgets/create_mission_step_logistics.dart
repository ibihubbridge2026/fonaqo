import 'package:flutter/material.dart';

/// Étape 3 : agent optionnel + options (Urgent/Confidentiel).
class CreateMissionStepLogistics extends StatelessWidget {
  final TextEditingController targetAgentController;
  final bool isUrgent;
  final bool isConfidential;
  final ValueChanged<bool> onUrgentChanged;
  final ValueChanged<bool> onConfidentialChanged;
  final VoidCallback onNext;

  const CreateMissionStepLogistics({
    super.key,
    required this.targetAgentController,
    required this.isUrgent,
    required this.isConfidential,
    required this.onUrgentChanged,
    required this.onConfidentialChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Options de mission',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Assignez un agent et choisissez les options supplémentaires.',
          style: TextStyle(color: Colors.grey[700], fontSize: 14),
        ),
        const SizedBox(height: 16),
        _InfoCard(
          icon: Icons.security,
          message: 'Vos missions sont sécurisées et protégées.',
        ),
        const SizedBox(height: 24),
        _InputCard(
          icon: Icons.person,
          label: 'Assigner à un agent (optionnel)',
          controller: targetAgentController,
          hint: 'Ex. agent_koffi',
        ),
        const SizedBox(height: 16),
        _OptionCard(
          icon: Icons.priority_high,
          title: 'Mission urgente',
          subtitle: 'Agents notifiés en priorité (+500 FCFA)',
          value: isUrgent,
          onChanged: onUrgentChanged,
        ),
        const SizedBox(height: 12),
        _OptionCard(
          icon: Icons.lock,
          title: 'Mission confidentielle',
          subtitle: 'Visible uniquement par les agents internes (+500 FCFA)',
          value: isConfidential,
          onChanged: onConfidentialChanged,
        ),
      ],
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
  final String? hint;

  const _InputCard({
    required this.icon,
    required this.label,
    required this.controller,
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

class _DescriptionCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final TextEditingController controller;

  const _DescriptionCard({
    required this.icon,
    required this.label,
    required this.controller,
  });

  @override
  State<_DescriptionCard> createState() => _DescriptionCardState();
}

class _DescriptionCardState extends State<_DescriptionCard> {
  final int _maxLength = 300;

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
                widget.icon,
                color: const Color(0xFFB8860B),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
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
            controller: widget.controller,
            maxLines: 4,
            maxLength: _maxLength,
            decoration: const InputDecoration(
              hintText: 'Décrivez votre mission en détail...',
              hintStyle: TextStyle(color: Color(0xFFBBBBBB)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              counterText: '',
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${widget.controller.text.length}/$_maxLength',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
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
      child: Row(
        children: [
          Icon(
            icon,
            color: value ? const Color(0xFFFFD400) : Colors.grey[600],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: const Color(0xFFFFD400),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
