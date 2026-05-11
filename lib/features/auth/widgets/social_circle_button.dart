import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SocialCircleButton extends StatelessWidget {
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const SocialCircleButton({super.key, required this.color, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        alignment: Alignment.center,
        child: FaIcon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
