import 'package:flutter/material.dart';

class LoginMethodToggle extends StatelessWidget {
  final bool usePhone;
  final ValueChanged<bool> onChanged;

  const LoginMethodToggle({
    super.key,
    required this.usePhone,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ToggleButton(
            label: 'Téléphone',
            isActive: usePhone,
            onTap: () => onChanged(true),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ToggleButton(
            label: 'Email',
            isActive: !usePhone,
            onTap: () => onChanged(false),
          ),
        ),
      ],
    );
  }
}

class ToggleButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const ToggleButton({
    super.key,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? Colors.black : const Color(0xFFF3F3F3),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: Colors.black.withOpacity(0.08)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: isActive ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}
